/**
* Name: CarAdapter
* Co-model car adapter. 
* Author: Jean-François Erdelyi
* Tags: 
*/

model CarAdapter

import "Car.gaml"

experiment Micro type: gui {
	list<car> get_cars {
		return list(car);
	}
	
	list<road> get_roads {
		return list(road);
	}
	
}

