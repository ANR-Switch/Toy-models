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
	geometry shape <- rectangle(200, 10);

	// Simulation step
	float step <- 0.1;

	init {
		// micro_model must be instantiated by create statement. We create an experiment inside the micro-model and the simulation will be created implicitly (1 experiment have only 1 simulation).
		geometry rr <- rectangle(200, 3.5) at_location {100.0, 1.5 + 1.75};
		create Cars.Base using topology(world) with: [right::false, road_shape::rr] {}

		geometry rr1 <- rectangle(200, 3.5) at_location {100.0, 5.0 + 1.75};
		create Cars.Base using topology(world) with: [right::true, road_shape::rr1] {}

		geometry cr <- rectangle(200, 10) at_location {100.0, 0.0};
		geometry ca <- rectangle(3.5, 10) at_location {100.0, 0.0};
		create Pedestrians.Simple using topology(world) with: [crossing_shape::cr, crossing_area_shape::ca] {}
	}

	reflex simulate_micro_models {

		// tell all experiments of micro_model_1 do 1 step;
		ask (Cars.Base) accumulate each.simulation {
			do _step_;
		}

		// tell the first experiment of micro_model_2 do 1 step;
		ask (Pedestrians.Simple) accumulate each.simulation {
			do _step_;
		}

	}

}

experiment Complex type: gui {
	output {
		display "Comodel display" type: opengl  {
			//to display the agents of micro-models, we use the agent layer with the values come from the coupling.
			agents "Agent sidewalks" value: ((Pedestrians.Simple) accumulate each.simulation.Sidewalks);
			agents "Agent road" value: ((Cars.Base) accumulate each.simulation.road);
			agents "Agent pedestrian" value: ((Pedestrians.Simple) accumulate each.simulation.People);
			agents "Agent car" value: ((Cars.Base) accumulate each.simulation.car);
		}

	}

}

