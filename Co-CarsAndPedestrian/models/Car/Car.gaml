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
	geometry road_shape <- rectangle({road_witdh, road_height});
	// The environement shape
	geometry shape <- road_shape;

	// Speed of "controlled" car
	float controlled_speed <- 0.0;
	// if true to the right edge, else to the left
	bool right;

	// Init simulation
	init {
		create road;
		/*create car {
			location <- {road_shape.location.x, road_shape.location.y};
			target <- right ? {road_shape.width, road_shape.location.y} : {0.0, road_shape.location.y};
			speed <- 0.0;
			controlled <- true;
		}*/
	}

	// Generate cars
	reflex generate when: (cycle mod generate_frequency) = 0 {
		create car {
			location <- right ? {(size / 2.0), road_shape.location.y} : {road_shape.width - (size / 2.0), road_shape.location.y};
			target <- right ? {road_shape.width, road_shape.location.y} : {(size / 2.0), road_shape.location.y};
		}
	}
}

// Road species
species road {
	// Standard road shape, black and 5px
	aspect default {
		draw road_shape color: #lightgray;
	}

}

// Car species (with skill moving [goto])
species car skills: [moving] {
	// The last car is controled in order to test the behaviors of cars
	bool controlled <- false;
	// Reference of the followed car
	car next_car <- nil;
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
		list<car> cars;
		if(right) { 
			cars <- (car where (c: c.location.x > location.x));
		} else {
			cars <- (car where (c: c.location.x < location.x));
		}
		
		car closest_car <- nil;
		loop current_car over: cars {
			if(closest_car = nil or closest_car.location distance_to location > current_car.location distance_to location) {
				closest_car <- current_car;
			} 
		}
		
		if(closest_car != nil and (closest_car.location distance_to location < spacing + speed + (size / 2.0))) {
			next_car <- closest_car;
		} else if(closest_car = nil or closest_car.speed > desired_speed) {
			next_car <- nil;
		}
		// *****************************************
	
		// If the car is controlled
		if (controlled) {
			speed <- controlled_speed;
			desired_speed <- controlled_speed;
		} else {
			// If there is car to follow
			if (next_car != nil and not dead(next_car) ) {
				// Compute acceleration speed (Linear)
				acc <- (reactivity / reaction_time) * (next_car.speed - speed);
				speed <- speed + (acc * step);
			} else {
				// Compute acceleration speed (Gipps)
				if (desired_speed = 0) {
					speed <- 0.0;
				} else {
					speed <- speed + alpha * max_acc * reaction_time * (1.0 - (speed / desired_speed)) * sqrt(beta + (speed / desired_speed));
				}

			}

		}

		// Move skill
		do move heading: (self) towards (target) speed: speed;
	}

	// Die if car is out of bound
	reflex die when: (location.x > road_shape.width - (size / 2.0)) or (location.x < (size / 2.0)) {
		do die();
	}
}

// GUI Experiment
experiment Simple type: gui {
	// Speed of the "controled car"
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
