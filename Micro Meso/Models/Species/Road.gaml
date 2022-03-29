/**
* Name: Road
* Road species. 
* Author: Jean-François Erdelyi
* Tags: 
*/
model IDMQueue

import "../Utilities/EventManager.gaml"
import "Crossroad.gaml"
import "Car.gaml"

/** 
 * General data
 */
global {
	/**
	 * Roads params
	 */
	
	// Road max speed
	float road_max_speed <- 50.0 #km / #h;
	
	// Vehicule per minutes
	int road_vehicule_per_minutes <- 30;
	
	// BPR equilibrium alpha
	float road_alpha <- 1.0;
	
	// BPR equilibrium beta
	float road_beta <- 0.15;
	
	// BPR equilibrium gamma
	float road_gamma <- 4.0;
	
	/**
	 * Factory
	 */

	// Create new road
	action create_toy_road (int road_start_node_index, int road_end_node_index, bool road_micro_model) {
		create Road {
			// Get start crossroad
			start_node <- Crossroad[road_start_node_index];
			ask start_node {
				out_road <- myself;
			}

			// Get end crossroad
			end_node <- Crossroad[road_end_node_index];
			ask end_node {
				in_road <- myself;
			}

			// Create road shape
			shape <- line(start_node.location, end_node.location);
			length <- shape.perimeter;
			max_capacity <- shape.perimeter;
			current_capacity <- max_capacity;
			event_manager <- EventManager[0];
			micro_model <- road_micro_model;
		}

	}

}

/**
 * Road virtual species
 */
species Road skills: [scheduling] {	

	/**
	 * Factory param
	 */

	// Start crossroad node
	Crossroad start_node;

	// End crossroad node
	Crossroad end_node;
	
	/**
	 * Computation data
	 */

	// The list of car in this road
	queue<Car> cars;
	
	// Waiting cars
	queue<Car> waiting_cars;
	
	// Lengh
	float length;

	// Maximum space capacity of the road (in meters)
	float max_capacity <- shape.perimeter min: 10.0;

	// Actual free space capacity of the road (in meters)
	float current_capacity <- max_capacity min: 0.0 max: max_capacity;

	// Jam percentage
	float jam_percentage update: ((max_capacity - current_capacity) / max_capacity);
	
	// Request time of each car
	map<Car, date> request_times;
	
	// Outflow duration
	float outflow_duration function: 1 / (road_vehicule_per_minutes / 60) #s;
	
	// Last out date
	date last_out <- nil;
	
	// True car is corssing
	bool car_is_crossing function: length(cars where (each overlaps start_node)) > 0;
	
	// If true use micro model
	bool micro_model <- false;
	
	/**
	 * Reflex 
	 */
	 
	 // Check meso locations
	 reflex check_meso_location when: not micro_model {
	 	loop car over: cars {
			if simulation_date > request_times[car] {
				car.location <- end_node.location;		
			}	
		}
	 }
	 

	/**
	 * Action
	 */

	// Join the road
	action join (Car car, date request_time) {
		if micro_model {
			do micro_join(car, request_time);
		} else {
			do meso_join(car, request_time);
		}
	}

	// Leave the road
	action leave (Car car, date request_time) {
		if micro_model {
			do micro_leave(car, request_time);
		} else {
			do meso_leave(car, request_time);
		}
	}

	// Freeflow travel time
	float compute_travel_time(float free_flow_travel_time) {
		return free_flow_travel_time * (road_alpha + road_beta * (jam_percentage ^ road_gamma));			
	}

	/**
	 * Micro action
	 */
	 
	 // Join the road
	action micro_join (Car car, date request_time) {					
		ask car {
			// Change capacity
			myself.current_capacity <- myself.current_capacity - car_size - car_spacing;
			
			// Set values
			do init_value(myself, request_time);
	
			// Remaining speed
			do goto on: road target: target speed: remaining_speed;
		
		}

		// Add car and time to travel
		do add_request_time_car(car, (request_time + car.travel_time));
		
		
	}

	// Leave the road
	action micro_leave (Car car, date request_time) {
		// Remove car
		do remove_car(car, request_time);

		// Change capacity
		ask car {
			myself.current_capacity <- myself.current_capacity + car_size + car_spacing;
			do tear_down(request_time);
		}

		// If there is another road
		if end_node.out_road != nil {
			// Join new road
			ask end_node.out_road {
				do join(car, request_time);
			}

		} else {
			ask car {
				// Do die
				do die();
			}
		}

	}

	/**
	 * Meso action
	 */
	 
	// Join the road
	action meso_join (Car car, date request_time) {		
		ask car {
			// Change capacity
			myself.current_capacity <- myself.current_capacity - car_size - car_spacing;

			// Set values
			do init_value(myself, request_time);
		}
		
		// Add car and time to travel
		do add_request_time_car(car, (request_time + car.travel_time));			
		
		// If this is the first car
		if length(cars) = 1 {
			do check_and_schedule_first_agent(request_time);		
		}
	}
	 
	// Leave the road
	action meso_leave (Car car, date request_time) {

		// Get first
		if first(cars) != car {
			write "Something wrong in meso_leave " + name + " at " + cycle + " car " + car;
		}
		
		Road next_road <- end_node.out_road;
		
		// If there is another road
		bool joinable <- end_node.get_accessibility();
		if next_road != nil {		
			// If joined
			if joinable {
				// Pop
				car <- pop_car(request_time);
				
				// Update capacity
				ask car {
					myself.current_capacity <- myself.current_capacity + car_size + car_spacing;
					do tear_down(request_time);
				}
		
				// Check and add car
				do check_waiting(request_time);

				// Join new road
				ask next_road {
					do join(car, request_time);
				}
			} else {
				ask next_road {
					do add_in_waiting_queue(car);
				}
			}
		} else {
			if joinable {
				// Pop
				car <- pop_car(request_time);
				
				// Update capacity
				ask car {
					myself.current_capacity <- myself.current_capacity + car_size + car_spacing;
					do tear_down(request_time);
				}
		
				// Check and add car
				do check_waiting(request_time); 

				// Do die
				ask car {
					do die();
				}
				
			}
		}
	}
		
	// End travel
	action end_travel(Car car, date request_time, bool from_signal <- false) {
		if last_out = nil {
			do meso_leave(car, request_time);
		} else {
			float delta <- milliseconds_between(last_out, request_time) / 1000.0;
			if delta >= outflow_duration {
				do meso_leave(car, request_time);
			} else {
				// If the car has crossed the road
				date signal_date <- request_time + (outflow_duration - delta);
				
				// If the signal date is equals to the actual step date then execute it directly
				if signal_date = (starting_date + time) {
					do meso_leave(car, request_time + (outflow_duration - delta));
				} else if not from_signal {
					do later the_action: meso_leave_signal at: request_time + (outflow_duration - delta) refer_to: car;					
				}
			}
		}
	}

	// Leave signal
	action meso_leave_signal {
		do meso_leave(refer_to as Car, event_date);
	}
	
	// End signal
	action end_travel_signal {
		do end_travel(refer_to as Car, event_date);
	}
	
	// Check waiting agents
	action check_waiting(date request_time) {
		do check_and_schedule_first_agent(request_time);
		if length(waiting_cars) > 0 {
			do add_waiting_agents(request_time);
		}
	}
	
	// Check first car
	action check_first_agent (date request_time, bool from_signal <- false) {		
		if not empty(cars) {
			Car car <- first(cars);
			date end_road_date; 
			if request_time > request_times[car] {
				end_road_date <- request_time;
			} else {
				end_road_date <- request_times[car];
			}
			
			if end_road_date = request_time {
				do end_travel(car, end_road_date, from_signal);	
			}
		}
	}
	
	// Check first car
	action check_and_schedule_first_agent (date request_time) {		
		if not empty(cars) {
			Car car <- first(cars);
			date end_road_date; 
			if request_time > request_times[car] {
				end_road_date <- request_time;
			} else {
				end_road_date <- request_times[car];
			}
			
			if end_road_date = (starting_date + time) {
				do end_travel(car, end_road_date);			
			} else {
				do later the_action: end_travel_signal at: end_road_date refer_to: car;			
			}
		}
	}
	
	// Check if there is waiting agents and add it if it's possible
	action add_waiting_agents (date request_time) {
		// Check if waiting tranport can be join the road
		loop while: not empty(waiting_cars) and start_node.get_accessibility() {
			// Get first car			
			Car car <- pop(waiting_cars);
		
			// Leave previous road
			ask start_node.in_road {
				do meso_leave(car, request_time);
			}
		}
	}
		
	// Just the current capacity
	bool has_capacity {
		if micro_model {
			return (current_capacity >= car_size + car_spacing) and (not car_is_crossing);			
		} else {
			return (current_capacity >= car_size + car_spacing);
		}
	}

	// Notify as in road
	action in_notify(date request_time) {
		if not micro_model and end_node.out_road = nil {
			do check_first_agent(request_time, true);			
		}
	}
	
	// Notify as out road
	action out_notify(date request_time) {
		do add_waiting_agents(request_time);
	}
	
	/**
	 * Handler action
	 */

	// Add car
	action add_car (Car car) {
		push item: car to: cars;
	}

	// Add car to waiting queue
	action add_in_waiting_queue (Car car) {
		push item: car to: waiting_cars;
	}

	// Add request time car
	action add_request_time_car (Car car, date request_time) {
		do add_car (car);
		add request_time at: car to: request_times;				
	}
	
	// Remove car
	Car pop_car(date request_time) {
		Car first <- pop(cars);
		remove key: first from: request_times;
		last_out <- request_time;
		return first;
	}
	
	// Remove specific car
	action remove_car (Car car, date request_time) {
		Car first <- pop(cars);
		if first != car {
			write "Something wrong in remove_car " + name + " at " + cycle + " car " + car;
		}
		remove key: car from: request_times;
		last_out <- request_time;
	}
	
	// Remove car
	action pop_waiting_car {
		Car first <- pop(waiting_cars);
		remove key: first from: request_times;
	}
	
	/**
	 * Aspect
	 */

	// Default aspect
	aspect default {
		draw shape + 1 border: #grey color: rgb(255 * jam_percentage, 0, 0) width: 3;
	}

}
