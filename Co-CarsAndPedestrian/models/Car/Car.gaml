/**
* Name: Car
* Car. 
* Author: Jean-François Erdelyi
* Tags: 
*/

model Car

// Bloc global of the simulation
global {
	// Simulation step
	float step <- 0.1#s;

	// Cars generator rate (+1 => arithmetic error if value is 0)
	int generate_frequency <- 100 update: rnd(10, 1000) + 1;
	
	// Environement shape 3.5m(France) x 200m
	float road_witdh <- 200#m const: true; // Arbitary
	float road_height <- 3.5#m const: true;  // Fench road
	geometry world_shape <- rectangle({road_witdh, road_height});
	// The environement shape
	geometry shape <- rectangle({200, 3.5});

	// Controlled car options
	int nb_car <- 0;
	bool has_controlled_car <- false;
	float controlled_speed <- 0.0;
	
	// Guest agents
	list<car> guest <- nil;
	
	// if true to the right edge, else to the left
	bool right;

	// Init simulation
	init {
		create road;
	}

	// Generate cars
	reflex generate when: (cycle mod generate_frequency) = 0 {
		create car {
			location <- right ? {(size / 2.0), world_shape.location.y} : {world_shape.width - (size / 2.0), world_shape.location.y};
			target <- right ? {world_shape.width, world_shape.location.y} : {(size / 2.0), world_shape.location.y};
		}
		nb_car <- nb_car + 1;
	}
	
	// Get control of the first car
	reflex get_control when: has_controlled_car and nb_car > 0 {
		car[0].controlled <- true;
	}
	
	// Release the control of the first car
	reflex realease_control when: !has_controlled_car and nb_car > 0 {
		car[0].controlled <- false;
	}
	
	// Add agent from another places
	/*action add_guest_agent(agent g) {
		add moving_agent(g) to: guest;
	}*/
}

// Road species
species road {
	// Standard road shape, black and 5px
	aspect default {
		draw world_shape color: #lightgray;
	}

}

//species moving_agent skills: [moving] virtual: true {}

// Car species (with skill moving [move])
species car skills: [moving] {
	// The last car is controled in order to test the behaviors of cars
	bool controlled <- false;
	// Reference of the followed car
	car next_moving_agent <- nil;
	// Car target
	point target;

	// Linear params ***************************
	float acc <- 0.0 #m / (#s ^ 2);
	float reactivity <- 2.0;
	// *****************************************

	// Gipps params ****************************
	float alpha <- 2.5;
	float beta <- 0.025;
	float gamma <- 0.5;
	float spacing <- 1.0 #m;
	float max_acc <- (2.0 #m / (#s ^ 2));
	float most_severe_breaking <- -(2.0 #m / (#s ^ 2));
	float size <- 4.0 #m;
	float desired_speed <- 5.56 #m / #s; // 20km/h
	float reaction_time <- 1 #s;
	// *****************************************

	// Standard car, blue rectangle (1.5m x 4.0m argus)
	aspect default {
		float distance <- location distance_to target;
		point direction <- {(target.x - location.x) / distance, (target.y - location.y) / distance};
		
		draw rectangle({size #m, 1.5 #m}) color: #red; //rnd_color(255);
		draw line(location, location + (direction * speed)) color: #green;
		draw circle(spacing + (speed)) color: #darkcyan empty: true;
	}

	// Driver reflex
	reflex drive {
		//Get closest next car
		list<car> moving_agents;
		if(right) { 
			moving_agents <- (car where (c: c.location.x > location.x));
			//moving_agents <- (moving_agents + (guest where (g: g.location.x > location.x )));
		} else {
			moving_agents <- (car where (c: c.location.x < location.x));
			//moving_agents <- (moving_agents + (guest where (g: g.location.x < location.x)));
		}
		
		car closest_moving_agent <- nil;
		loop current_moving_agent over: moving_agents {
			if(closest_moving_agent = nil or closest_moving_agent.location distance_to location > current_moving_agent.location distance_to location) {
				closest_moving_agent <- current_moving_agent;
			} 
		}
		
		if(closest_moving_agent = nil or closest_moving_agent.speed > desired_speed) {
			next_moving_agent <- nil;
		} else if(closest_moving_agent.location distance_to location < spacing + speed + (size / 2.0)) {
			next_moving_agent <- closest_moving_agent;
		} 
		// *****************************************
	
		// If the car is controlled
		if (controlled) {
			// Compute acceleration speed (Linear)
			acc <- (reactivity / reaction_time) * (controlled_speed - speed);
			speed <- speed + (acc * step);
		} else {
			// If there is car to follow
			if (next_moving_agent != nil and not dead(next_moving_agent) ) {
				// Compute acceleration speed (Linear)
				acc <- (reactivity / reaction_time) * (next_moving_agent.speed - speed);
				speed <- speed + (acc * step);
			} else {
				// Compute acceleration speed (Gipps)
				speed <- speed + alpha * max_acc * reaction_time * (1.0 - (speed / desired_speed)) * sqrt(beta + (speed / desired_speed));
			}

		}

		// Move skill
		do move heading: (self) towards (target) speed: speed;		
	}

	// Die if car is out of bound
	reflex die when: (location.x > world_shape.width - (size / 2.0)) or (location.x < (size / 2.0)) {
		nb_car <- nb_car - 1;
		do die();
	}
	
}

// GUI Experiment
experiment Car type: gui {
	// Speed of the "controled car"
	parameter "Controlled car" var: has_controlled_car category: "Car";
	parameter "Maximal speed" var: controlled_speed category: "Car" max: 10 #m / #s;

	// Ouput of the simulation
	output {
		// The main window
		display main_window type: opengl {
			// Species with default aspects
			species road aspect: default;
			species car aspect: default;
		}
	}
}
