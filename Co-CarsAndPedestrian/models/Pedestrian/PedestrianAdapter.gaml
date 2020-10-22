/**
* Name: PedestrianAdapter
* Co-model pedestrian adapter.
* Author: Jean-François Erdelyi
* Tags: 
*/

model PedestrianAdapter

import "Pedestrian.gaml"

experiment MicroPedestrian type: gui {
	
	list<person> get_people {
		return list(person);
	}
	
	list<agent> get_person_guests {
		return guest;
	}
	
	action clear_person_guests {
		guest <- [];
	}
	
	action add_person_guest(agent m) {
		if(m != nil and !dead(m)) {
			add m to: guest;
		}
	}
}
