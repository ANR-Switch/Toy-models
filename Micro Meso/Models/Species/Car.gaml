/**
* Name: Car
* Car. 
* Author: Jean-François Erdelyi
* Tags: 
*/
model IDMQueue

import "../Utilities/Logger.gaml"

import "../Utilities/Global.gaml"
import "Road.gaml"

/** 
 * General data
 */
global {
/**
	 * Car general param
	 */

	// Field of view length
	float car_max_view_length <- 200 #m;

	// Field of view width
	float car_max_view_width <- 100 #m;

	// If true draw sensing zone
	bool car_draw_sensing <- false;

	/**
	 * IDM param
	 */

	// Maximum speed for a car
	float car_max_speed <- 130.0 #km / #h;

	// Car length 
	float car_size <- 4.0 #m;

	// Max acceleration
	float car_max_acceleration <- (4.0 #m / (#s ^ 2));

	// Most sever break
	float car_max_break <- (3.0 #m / (#s ^ 2));

	// Reaction time
	float car_reaction_time <- 1.4 #s;

	// Spacing between two cars 
	float car_spacing <- 2.0 #m;

	// Delta param
	float car_delta <- 4.0;

	/**
	 * Factory
	 */

	// Create a new car
	action create_toy_car (graph car_graph, Road car_road, point car_final_target) {
		// Create car 
		create Car returns: values {
			network <- car_graph;
			road <- car_road;
			final_target <- car_final_target;
			final_path_lenght <- car_road.start_node distance_to final_target using topology(network);
		}

		// Join the road
		ask car_road {
			do join(values[0], simulation_date);
		}

	}

}

/** 
 * Car species
 */
species Car skills: [moving] {

	/**
	 * Factory param
	 */

	// Roads network
	graph network;

	// Current road
	Road road;

	// Target
	point final_target;

	/**
	 * Drawing data
	 */

	// Car width
	float width <- 1.5 #m const: true;

	// Default shape
	geometry default_shape update: rectangle(car_size, width);

	// Drawed shape
	geometry shape update: default_shape rotated_by heading at_location location;

	// Center of the sensing zone
	point sensing_zone_location update: location + (point(cos(heading), sin(heading)) * (car_max_view_length / 2.0));

	// Sensing zone
	geometry sensing_zone update: rectangle(car_max_view_length, car_max_view_width) at_location sensing_zone_location rotated_by heading;

	/**
	 * Model computation data
	 */

	// Current acceleration
	float acceleration min: -car_max_break max: car_max_acceleration;

	// Desired speed 
	float desired_speed;

	// Delta speed between the current car and th leader
	float delta_speed;

	// Gap between the current car and the leader
	float actual_gap;

	// Desired minimum gap
	float desired_minimum_gap;

	/**
	 * Computation data
	 */

	// Distance to target
	float distance function: self distance_to target using topology(network) with_precision 4;

	// Distance to the final target
	float final_distance update: self distance_to final_target using topology(network) with_precision 4;

	// Path lenght to the final location
	float final_path_lenght;

	// Location in the road
	float location_in_road update: (road.length - distance);

	// Location in the road (to the end of the trip)
	float final_location_in_road update: (final_path_lenght - final_distance);

	// Remaining speed
	float remaining_speed;

	// Freeflow travel time
	float free_flow_travel_time;

	// Freeflow travel time after BPR
	float travel_time;

	// computed speed
	float computed_speed <- 0.0;

	// If ture use micro model
	bool micro_model <- false;

	// If true is the leader
	bool is_leader;

	// Target
	point target;

	// Entry time
	date entry_time <- nil;

	// List of car in the sensing
	list<Car> cars;

	// Closest
	Car closest;

	// End crossroad
	Crossroad end_crossroad;

	/**
	 * Reflex
	 */

	// Reaction drive
	reflex compute_drive when: micro_model {
	// Get end crossroad
		end_crossroad <- road.end_node.location overlaps sensing_zone ? road.end_node : nil;

		// Check if is the first car of this road
		if first(road.cars) = self and end_crossroad != nil {
			bool joinable <- end_crossroad.get_accessibility();
			if joinable {
			// If accessible -> as usual
				do compute_acceleration();
			} else {
			// Else "follow" the crossroad
				do get_closest_car();
				do compute_follower_acceleration(end_crossroad, 0.0);
			}

		} else {
			do compute_acceleration();
		}

		// Goto and check target
		speed <- speed + (acceleration * step);
		do goto on: road target: target speed: speed;
		do check_target(simulation_date);
	}

	/**
	 * Action
	 */

	// Get closest car
	action get_closest_car {
		ask road.end_node {
			myself.cars <- (get_closest_cars() where (each.location overlaps myself.sensing_zone and each != myself and each.micro_model));
		}

		// Get closest
		closest <- (cars closest_to self using topology(network));
		is_leader <- closest = nil or dead(closest);
	}

	// Compute acceleration
	action compute_acceleration {
		do get_closest_car();
		if (is_leader) {
			do compute_leader_acceleration();
		} else {
			do compute_follower_acceleration(closest, closest.speed);
		}

	}

	// Compute acceleration of leader
	action compute_leader_acceleration {
	// Compute acceleration
		acceleration <- car_max_acceleration * (1 - ((speed / desired_speed) ^ car_delta));
	}

	// Compute acceleration of followers
	action compute_follower_acceleration (agent leader, float leader_speed) {
		// Compute deltas
		delta_speed <- leader_speed - speed;
		actual_gap <- (self distance_to leader using topology(network)) - car_size;

		// Compute minimum gap
		desired_minimum_gap <- car_spacing + (car_reaction_time * speed) - ((speed * delta_speed) / (2 * sqrt(car_max_acceleration * car_max_break)));

		// Compute acceleration
		if actual_gap != 0.0 {
			acceleration <- car_max_acceleration * (1 - ((speed / desired_speed) ^ car_delta) - ((desired_minimum_gap / actual_gap) ^ 2));
		} else {
			acceleration <- car_max_acceleration * (1 - ((speed / desired_speed) ^ car_delta) - (desired_minimum_gap ^ 2));
		}

	}

	// Check if the target is reached
	action check_target (date request_time) {
		// Get the distance between the car and the target
		if distance <= 0.0 {
			// Leave road
			ask road {
				do leave(myself, request_time);
			}

		}

	}

	// Init value in the new road
	action init_value (Road new_road, date request_time) {
		road <- new_road;
		micro_model <- road.micro_model;
		location <- road.start_node.location;
		target <- road.end_node.location;
		desired_speed <- get_max_freeflow_speed();
		entry_time <- request_time;
		free_flow_travel_time <- (road.length / desired_speed);
		travel_time <- road.compute_travel_time(free_flow_travel_time);
		if micro_model and road.start_node.coupling_type = "meso-micro" {
			// Set speed
			if length(road.cars) > 0 {
				// From closest
				closest <- last(road.cars);
				speed <- closest.speed;
			} else {
				// From computed speed (see tear_down action)
				speed <- computed_speed;
			}

		} else if not micro_model {
			// Theorical speed
			speed <- ((road.length / travel_time) * 3.6) #km / #h;
		}
	}

	// Init value in the new road
	action tear_down (date request_time) {
		if micro_model {
			remaining_speed <- speed - real_speed;			
		} else {
			remaining_speed <- 0.0;			
		}
		float seconds <- milliseconds_between(entry_time, request_time) / 1000.0;
		computed_speed <- ((road.length / seconds) * 3.6) #km / #h;
		ask Logger[0] {
			do log_data(myself.name, "speed", string(request_time), string(myself.computed_speed));	
		}
	}

	// Get max freeflow speed
	float get_max_freeflow_speed {
		return (min([car_max_speed, road_max_speed]) * 3.6) #km / #h;
	}

	/**
	 * Aspect
	 */

	// Default aspect
	aspect default {
		draw shape color: #grey border: #black;
		if car_draw_sensing {
			draw sensing_zone border: #blue wireframe: true;
		}

	}

}

