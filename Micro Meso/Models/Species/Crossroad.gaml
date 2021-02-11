/**
* Name: Crossroad
* Crossroad.  
* Author: Jean-François Erdelyi
* Tags: 
*/
model IDMQueue

import "Car.gaml"

/** 
 * General data
 */
global {
	/**
	 * Factory
	 */
	
	// Create a new car
	action create_toy_crossroad (point crossroad_location) {
		create Crossroad {
			location <- crossroad_location;
			type <- "generator";
			phase_frequency <- 0;
		}

	}

	// Create a new car
	action create_toy_light_crossroad (point crossroad_location, int crossroad_phase_frequency) {
		create Crossroad {
			location <- crossroad_location;
			type <- "light";
			phase_frequency <- crossroad_phase_frequency;
		}

	}

}

/** 
 * Crossroad species
 */
species Crossroad {
	/**
	 * Factory param
	 */

	// Crossroad type
	string type <- "generator" among: ["generator", "light"];

	// Phase frequency
	int phase_frequency;

	/**
	 * Drawing data
	 */

	// Shape
	geometry shape <- circle((car_size / 2.0) + car_spacing);

	// Color
	rgb color function: accessible ? #green : #red;

	/**
	 * Computation data
	 */
	 
	// Crossroad coupling
	string coupling_type <- "none-none" among: ["none-none", "meso-none", "none-meso", "micro-none", "none-micro", "micro-micro", "meso-micro", "micro-meso", "meso-meso"];

	// In road
	Road in_road;

	// Out road
	Road out_road;

	// True if accessible
	bool accessible <- true;

	/**
	 * Reflex
	 */

	// Check accessibility for light
	reflex change_phase when: (type = "light") and ((cycle mod phase_frequency) = 0) and (cycle != 0) {
		accessible <- not accessible;
	}
	
	// Notify roads
	reflex notify_roads when: (type = "light") {
		if accessible {
			if in_road != nil {
				ask in_road {
					do in_notify(simulation_date);			
				}
			}
			if out_road != nil {
				ask out_road {
					do out_notify(simulation_date);			
				}
			}
		}
	}
	
	/**
	 * Action
	 */
	
	// Get cars from the in and out roads
	list<Car> get_closest_cars {
		list<Car> cars;
		if in_road != nil {
			add in_road.cars to: cars all: true;
		}
		if out_road != nil {
			add out_road.cars to: cars all: true;
		}
		return cars;
	}
	
	// Get accessibility
	bool get_accessibility {
		if out_road != nil {
			ask out_road {
				return has_capacity() and myself.accessible;
			}
		} else {
			return accessible;
		}
	}
	
	// Set crossroad
	action setup {
		string type_string <- "";
		
		if in_road != nil {
			if in_road.micro_model {
				type_string <- "micro-";
			} else {
				type_string <- "meso-";
			}
		} else {
			type_string <- "none-";
		}
		
		if out_road != nil {
			if out_road.micro_model {
				type_string <- type_string + "micro";
			} else {
				type_string <- type_string + "meso";
				
			}
		} else {
			type_string <- type_string + "none";
		}
		
		coupling_type <- type_string;
	}

	/**
	 * Aspect
	 */

	// Default aspect
	aspect default {
		draw shape color: color border: #black;
	}

}
