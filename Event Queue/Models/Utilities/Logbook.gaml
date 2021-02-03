/**
* Name: Logbook
* Log data.
* Author: Jean-François Erdelyi 
* Tags: 
*/
model EventQueue

import "Global.gaml"

/** 
 * General data
 */
global {
	/**
	 * Logbook param
	 */
	
	// File path
	string logbook_file_path <- "../Logs/";
	
	// Cycle threshold
	int logbook_cycle_threshold <- 10000;
	
	// If true, then write data
	bool logbook_write_data <- false;
	
	// If true, then log data
	bool logbook_activated <- false;
	
	// If true, then write data	when the cycle is reached
	bool logbook_cycle_activated <- false;
	
	// If true, then flush buffer when logbook write data in the file 
	bool logbook_flush <- true;
}

/** 
 * Logbook species
 */
species Logbook skills: [logging_book] {
	/**
	 * Reflex
	 */

	// Write data when cycle threshold is reached
	reflex write_data when: logbook_cycle_activated and (cycle != 0) and ((cycle mod logbook_cycle_threshold) = 0) {
		do write file_name: (logbook_file_path + name + "_" + now + ".json") flush: logbook_flush;
	}
	
	// Write data when cycle threshold is reached
	reflex write_data_manualy when: logbook_write_data {
		logbook_write_data <- false;
		do write file_name: (logbook_file_path + name + "_" + now + ".json") flush: logbook_flush;
	}

}
