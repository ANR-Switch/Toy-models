/**
* Name: World
* Entry point IDM simulation.
* Author: Jean-François Erdelyi 
* Tags: 
*/
model SwITCh

import "Utilities/Global.gaml"
import "Utilities/Logbook.gaml"
import "Species/Crossroad.gaml"
import "Species/Road.gaml"
import "Species/Car.gaml"

/** 
 * Setup the world
 */
global skills: [logging] {
	/**
	 * Global param
	 */
	 
	// Starting date
	date starting_date <- date([1970, 1, 1, 0, 0, 0]);
	
	// Time stepƒ
	float step <- 0.1 #s;
	
	// Random seed
	float seed <- 424242.0;
	
	// Cars generator rate (+1 => arithmetic error if value is 0)
	int generate_frequency <- 50 update: rnd(0, 500) + 1;
	
	// The logbook
	agent logbook;

	/**
	 * Geometry of the world
	 */
	 
	// World height
	float height <- 100.0;
	
	// World width
	float width <- 100.0;
	
	// World shape
	geometry shape <- rectangle(height, width);
	
	// Road graph
	graph full_network;
	
	// Start crossroad location
	point start_location <- point(0.0, 0.0);
	
	// Second crossroad location
	point second_location <- point(height, 0.0);
	
	// Third crossroad location
	point third_location <- point(height, width);
	
	// End crossroad location
	point end_location <- point(0.0, width);
	
	/**
	 * Reflex
	 */

	// Car generator
	reflex generate when: ((cycle mod generate_frequency) = 0) and (Crossroad[0].accessible) {
		do create_toy_car(full_network, Road[0], Crossroad[3].location);
	}

	// Log data
	reflex log_data when: logbook_activated {		
		// For each road
		loop road over: Road {			
			// For each car
			loop car over: road.cars {			
				// Write time/distance: [CarYYY, location/speed, time, car.location/speed]
				do log_plot_2d section: car.name entry: "location" x: string(time) y: string(car.final_location_in_road);
				
				// Write speed
				do log_plot_2d section: car.name entry: "speed" x: string(time) y: string(car.speed);
				
			}				
		}
	}
	
	/**
	 * Init
	 */

	// Init the model
	init {
		// Create logbook
		create Logbook;
		logbook <- Logbook[0];
		
		// Create crossroads
		write "Crossroad...";
		do create_toy_crossroad(start_location);
		do create_toy_light_crossroad(second_location, 333);
		do create_toy_light_crossroad(third_location, 666);
		do create_toy_light_crossroad(end_location, 999);
		write "-> " + now;

		// Create roads
		write "Road...";
		do create_toy_road(0, 1);
		do create_toy_road(1, 2);
		do create_toy_road(2, 3);
		write "-> " + now;

		// Create network	
		write "Graph...";
		full_network <- as_edge_graph(Road, 1);
		write "-> " + now;
	}

}

/**
 * Experiment
 */
 
// Main experiment
experiment "IDM" type: gui {
	// Car param
	parameter "Max view length" var: car_max_view_length category: "Car";
	parameter "Max view width" var: car_max_view_width category: "Car";
	parameter "Draw sensing" var: car_draw_sensing category: "Car";
	
	// IDM param
	parameter "Max speed" var: car_max_speed category: "IDM";
	parameter "Size" var: car_size category: "IDM";
	parameter "Max acceleration" var: car_max_acceleration category: "IDM";
	parameter "Max break" var: car_max_break category: "IDM";
	parameter "Reaction time" var: car_reaction_time category: "IDM";
	parameter "Spacing" var: car_spacing category: "IDM";
	parameter "Delta" var: car_delta category: "IDM";
	
	// Road param
	parameter "Road max speed" var: road_max_speed category: "Road";
	
	// Logbook param
	parameter "Logbook file path" var: logbook_file_path category: "Logbook";
	parameter "Logbook cycle threshold" var: logbook_cycle_threshold category: "Logbook";
	parameter "Logbook force write" var: logbook_write_data category: "Logbook";
	parameter "Logbook activated" var: logbook_activated category: "Logbook";
	parameter "Logbook cyclic activated" var: logbook_cycle_activated category: "Logbook";
	parameter "Logbook flush" var: logbook_flush category: "Logbook";
	
	output {
		display main_window type: opengl {
			species Road;
			species Crossroad;
			species Car;
		}

	}

}
