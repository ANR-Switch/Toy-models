/**
* Name: Logger
* Log data.
* Author: Jean-François Erdelyi 
* Tags: 
*/
model IDMQueue

import "../Species/Road.gaml"
import "Logbook.gaml"

/** 
 * General data
 */
global {
	// If true, then log data
	bool logger_activated <- false;

	// Create a new car
	action create_logger (Logbook logger_logbook) {
		// Create car 
		create Logger {
			logbook <- logger_logbook;
		}

	}

}

species Logger skills: [logging] {
	// The logbook
	agent logbook;

	/**
	 * Reflex
	 */

	// Log data
	reflex log_data when: logger_activated {
		// For each road
		loop road over: Road {
			// For each car
			loop car over: road.cars {
				// Write time/distance: [CarYYY, location/speed, time, car.location/speed]
				do log_data(car.name, "location", string(time), string(car.final_location_in_road));
			}

		}

	}

	/**
	 * Action
	 */
	action log_data (string data_name, string data_entry, string data_x, string data_y) {
		do log_plot_2d section: data_name entry: data_entry x: data_x y: data_y;
	}

} 

