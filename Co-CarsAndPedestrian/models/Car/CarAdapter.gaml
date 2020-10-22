/**
* Name: CarAdapter
* Co-model car adapter. 
* Author: Jean-François Erdelyi
* Tags: 
*/

model CarAdapter

import "Car.gaml"

experiment MicroCar type: gui {
	
	list<car> get_cars {
		return list(car);
	}
	
	list<agent> get_car_guests {
		return guest;
	}
	
	action clear_car_guests {
		guest <- [];
	}
	
	action add_car_guest(agent m) {
		if(m != nil and !dead(m) and m is_skill "moving") {
			add m to: guest;
		}
	}
}
