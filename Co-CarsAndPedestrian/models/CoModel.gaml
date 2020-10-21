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
		//create Cars.Micro using topology(world) with: [right::false, world_shape::first_road_world_shape] {}
		create Cars.Micro using topology(world) with: [right::true, world_shape::second_road_world_shape] {}
		create Pedestrians.Micro using topology(world) with: [world_shape::pedestrian_world_shape] {}
	}

	reflex simulate_micro_models {

		
		/*list<moving_agent> people <- list<moving_agent>(Pedestrians.Simple accumulate each.get_people());
		if(length(people) > 0) {
			agent a <- (agent(Cars.Simple accumulate each.add_guest(people[0])));
		}*/
				
		// Do one step of pedestrian
		ask (Pedestrians.Micro) accumulate each.simulation {
			do _step_;
		}
		
		// Do one step of cars
		ask (Cars.Micro) accumulate each.simulation {
			do _step_;
		}
		

	}

}

experiment Complex type: gui {
	output {
		display "Comodel display" type: opengl  {
			agents "Agent sidewalks" value: ((Pedestrians.Micro) accumulate each.simulation.sidewalks);
			agents "Agent road" value: ((Cars.Micro) accumulate each.simulation.road);
			agents "Agent pedestrian" value: ((Pedestrians.Micro) accumulate each.simulation.people);
			agents "Agent car" value: ((Cars.Micro) accumulate each.simulation.car);
		}

	}

}

