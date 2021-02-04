/**
* Name: Global
* Global data. 
* Author: Jean-François Erdelyi 
* Tags: 
*/

model Global

/** 
 * General data
 */
global {
	/**
	 * Computation data
	 */
	 
	// First date
	date first_date <- date([1970, 1, 1, 0, 0, 0]) const: true;
	 
	// Now
	date now function: (first_date + (machine_time / 1000) + 3600);
	
	// Simulation date
	date simulation_date function: starting_date + time;
}
