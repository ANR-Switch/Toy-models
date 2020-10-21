/**
* Name: PedestrianAdapter
* Co-model pedestrian adapter.
* Author: Jean-François Erdelyi
* Tags: 
*/

model PedestrianAdapter

import "Pedestrian.gaml"

experiment Micro type: gui {
	list<people> get_people {
		return list(people);
	}
	
	list<sidewalks> get_sidewalks {
		return list(sidewalks);
	}
}

