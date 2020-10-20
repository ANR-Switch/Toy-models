/**
* Name: CarAdapter
* Co-model car adapter. 
* Author: Jean-François Erdelyi
* Tags: 
*/

model CarAdapter

import "Car.gaml"

global {
}

experiment Base type: gui {
	list<car> get_cars{
		return list(car);
	}
	
	list<road> get_roads{
		return list(road);
	}
	
	//if we redefine the output, i.e, a blank output, the displays in parent experiement dont show.
	output {
	}
}

