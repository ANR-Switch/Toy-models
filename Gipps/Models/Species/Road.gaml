/**
* Name: Road
* Road species. 
* Author: Jean-François Erdelyi
* Tags: 
*/
model Gipps

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
	
	/**
	 * Factory
	 */

	// Create new road
	action create_toy_road (int road_start_node_index, int road_end_node_index) {
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
		}

	}

}

/**
 * Road virtual species
 */
species Road {	

	/**
	 * Factory param
	 */

	// Start crossroad node
	Crossroad start_node;

	// End crossroad node
	Crossroad end_node;
	
	/**
	 * General param
	 */
	
	// Maximum legal speed on this road
	float max_speed function: road_max_speed;

	/**
	 * Computation data
	 */

	// The list of car in this road
	list<Car> cars;
	
	// Lengh
	float length;

	// Maximum space capacity of the road (in meters)
	float max_capacity <- shape.perimeter min: 10.0;

	// Actual free space capacity of the road (in meters)
	float current_capacity <- max_capacity min: 0.0 max: max_capacity;

	// Jam percentage
	float jam_percentage update: ((max_capacity - current_capacity) / max_capacity);

	/**
	 * Action
	 */

	// Join the road
	action join (Car car) {
		// Add car
		ask car {
			// Change capacity
			myself.current_capacity <- myself.current_capacity - car_size - car_spacing;

			// Set values
			do init_value(myself);	
			
			// Remaining speed
			do goto on: road target: target speed: remaining_speed;
		}
		do add_car(car);
	}

	// Leave the road
	action leave (Car car) {
		// Remove car
		do remove_car(car);

		// Change capacity
		ask car {
			myself.current_capacity <- myself.current_capacity + car_size + car_spacing;
		}

		// If there is another road
		if end_node.out_road != nil {
			// Join new road
			ask end_node.out_road {
				do join(car);
			}

		} else {
			// Do die
			ask car {
				do die();
			}

		}

	}

	// Add car
	action add_car (Car car) {
		add car to: cars;
	}

	// Remove car
	action remove_car (Car car) {
		remove car from: cars;
	}

	/**
	 * Aspect
	 */

	// Default aspect
	aspect default {
		draw shape + 1 border: #grey color: rgb(255 * jam_percentage, 0, 0) width: 3;
	}

}
