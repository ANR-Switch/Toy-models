/**
* Name: PedestrianAdapter
* Co-model pedestrian adapter.
* Author: Jean-François Erdelyi
* Tags: 
*/

model PedestrianAdapter

import "Pedestrian.gaml"

global {}

experiment Simple type: gui {
	list<People> get_people {
		return list(People);
	}
	
	list<Sidewalks> get_sidewalks {
		return list(Sidewalks);
	}
	
	// If we redefine the output, i.e, a blank output, the displays in parent experiement dont show.
	output {}
}

