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
	 
	// Now
	date now function: (starting_date + (machine_time / 1000) + 3600);
}
