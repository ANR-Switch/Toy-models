/**
* Name: Crossroad
* Crossroad.  
* Author: Jean-François Erdelyi
* Tags: 
*/
model Gipps

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
	geometry shape <- circle(3);

	// Color
	rgb color function: accessible ? #green : #red;

	/**
	 * Computation data
	 */

	// In road
	Road in_road;

	// Out road
	Road out_road;

	// True if accessible
	bool accessible <- true;

	/**
	 * Reflex
	 */

	// Change phase periodically
	reflex change_phase when: (type = "light") and ((cycle mod phase_frequency) = 0) {
		accessible <- not accessible;
	}

	// Check accessibility
	reflex accessibility_change when: (type = "generator") {
		accessible <- length(get_closest_cars() where (each overlaps self)) <= 0;
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

	/**
	 * Aspect
	 */

	// Default aspect
	aspect default {
		draw shape color: color border: #black;
	}

}
