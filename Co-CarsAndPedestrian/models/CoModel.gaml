/**
* Name: CoModel
* Cars and pedestrians co-model. 
* Author: Jean-François Erdelyi
* Tags: 
*/
model CoModel

import "Car/CarAdapter.gaml" as Cars
import "Pedestrian/PedestrianAdapter.gaml" as Pedestrians

global {
	// Macro model shape
	geometry shape <- rectangle(200, 10);

	// Simulation step
	float step <- 0.1;
	
	init {
		// Geometry of micro models
		geometry first_road_world_shape <- rectangle(200, 3.5) at_location {100.0, 1.5 + 1.75};
		geometry second_road_world_shape <- rectangle(200, 3.5) at_location {100.0, 5.0 + 1.75};
		geometry pedestrian_world_shape <- rectangle(200, 10) at_location {100.0, 0.0};

		// Instance of micro models
		create Cars.MicroCar using topology(world) with: [right::false, world_shape::first_road_world_shape] {}
		create Cars.MicroCar using topology(world) with: [right::true, world_shape::second_road_world_shape] {}
		create Pedestrians.MicroPedestrian using topology(world) with: [world_shape::pedestrian_world_shape] {}
	}

	reflex simulate_micro_models {		
		// Get actual guest in car model and all pedestrian
		list<agent> cars <- list<agent>(Cars.MicroCar accumulate each.get_cars());
		list<agent> guest_pedestrians <- list<agent>(Pedestrians.MicroPedestrian accumulate each.get_person_guests());
				
		// If the number of cars has changed 
		if(length(guest_pedestrians) != length(cars)) {
			// Clear the guest list
			ask (Pedestrians.MicroPedestrian) {
				do clear_person_guests;
			}
			
			// If there is 1 or more cars
			if(length(cars) > 0) {
				
				// Insert all alive pedestrians
				loop i from: 0 to: length(cars) - 1 {
					if (!dead(cars at i)) {
						ask (Pedestrians.MicroPedestrian) {
							do add_person_guest(cars at i);
						}
					}
				}
			}
		}

		// Do one step of pedestrian
		ask (Pedestrians.MicroPedestrian) accumulate each.simulation {
			do _step_;
		}

		// Get actual guest in car model and all pedestrian
		list<agent> pedestrians <- list<agent>(Pedestrians.MicroPedestrian accumulate each.get_people());
		list<agent> guest_car <- list<agent>(Cars.MicroCar accumulate each.get_car_guests());
	
		// If the number of pedestrian has changed 
		if(length(guest_car) != length(pedestrians)) {
			// Clear the guest list
			ask (Cars.MicroCar)
			{
				do clear_car_guests;
			}
			
			// If there is 1 or more pedestrians
			if(length(pedestrians) > 0) {
				 
				// Insert all alive pedestrians
				loop i from: 0 to: length(pedestrians) - 1 {
					if (!dead(pedestrians at i)) {
						ask (Cars.MicroCar) {
							do add_car_guest(pedestrians at i);
						}
					}
				}
			}
		}
		
		// Do one step of cars
		ask (Cars.MicroCar) accumulate each.simulation {
			do _step_;
		}
	}
}

experiment Complex type: gui {
	output {
		display "Comodel display" type: opengl  {
			agents "Agent sidewalks" value: ((Pedestrians.MicroPedestrian) accumulate each.simulation.sidewalk);
			agents "Agent road" value: ((Cars.MicroCar) accumulate each.simulation.road);
			agents "Agent pedestrian" value: ((Pedestrians.MicroPedestrian) accumulate each.simulation.person);
			agents "Agent car" value: ((Cars.MicroCar) accumulate each.simulation.car);
		}

	}

}

