/**
* Name: Car
* Car. 
* Author: Jean-François Erdelyi
* Tags: 
*/
model EventQueue

import "../Utilities/Global.gaml"
import "Road.gaml"

/** 
 * General data
 */
global {	
	/**
	 * Car param
	 */
	 
 	// Maximum speed for a car
	float car_max_speed <- 130.0 #km / #h;
	
	// Spacing between two cars 
	float car_spacing <- 2.0 #m;
	
	// Car length 
	float car_size <- 4.0 #m;
	
	// If true car are animated
	bool car_vehicule_animation <- false;
	
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
			final_path_lenght <- (topology(network) distance_between [car_road.start_node, final_target]);
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

	/**
	 * Computation data
	 */

	// Distance to target
	float distance function: (topology(network) distance_between [self, target]) with_precision 4; 
	
	// Distance to the final target
	float final_distance function: (topology(network) distance_between [self, final_target]) with_precision 4;
	
	// Path lenght to the final location
	float final_path_lenght;

	// Location in the road
	float location_in_road function: (road.length - distance);	
	
	// Location in the road (to the end of the trip)
	float final_location_in_road function: (final_path_lenght - final_distance);

	// Freeflow travel time
	float free_flow_travel_time;
	
	// Freeflow travel time after BPR
	float travel_time;
	
	// Target
	point target;
	
	// Entry time
	date entry_time <- nil;
	
	// Theorical speed
	float desired_speed <- 0.0;
	
	/**
	 * Reflex
	 */
	 
	 // Goto
	 reflex move when: car_vehicule_animation {
		do goto on: road target: target speed: desired_speed;
	 }
	
	/**
	 * Action
	 */

	// Init value in the new road
	action init_value(Road new_road, date request_time) {
		road <- new_road;
		location <- new_road.location;
		target <- new_road.end_node.location;
		
		entry_time <- request_time;
		desired_speed <- get_max_freeflow_speed();
		free_flow_travel_time <- (new_road.length / desired_speed);
		travel_time <- new_road.compute_travel_time(free_flow_travel_time);
	}
	
	// Init value in the new road
	action tear_down(date request_time) {
		float seconds <- milliseconds_between(entry_time, request_time) / 1000.0;
		speed <- ((road.length / seconds) * 3.6) #km / #h;
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
	}

}

