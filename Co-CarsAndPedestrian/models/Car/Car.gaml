/**
* Name: Car
* Car following model. 
* Author: Jean-François Erdelyi
* Tags: 
*/

model Car

// Bloc global of the simulation
global {
	// Simulation step
	float step <- 0.1#s;

	// Cars generator rate (+1 => arithmetic error if value is 0)
	int generate_frequency <- 100 update: rnd(100, 200) + 1;
	
	// Environement shape 3.5m(France) x 200m
	float road_witdh <- 200#m const: true; // Arbitary
	float road_height <- 3.5#m const: true;  // Fench road
	geometry world_shape <- rectangle({road_witdh, road_height});
	geometry shape <- rectangle({200, 3.5});

	// Controlled car options
	int nb_car <- 0;
	bool has_controlled_car <- false;
	float controlled_speed <- 0.0;
	
	// Guest agents
	list<agent> guest <- nil;
	
	// If true to the right edge, else to the left
	bool right <- false;

	// Init simulation
	init {
		create road;
	}

	// Generate cars
	reflex generate when: (cycle mod generate_frequency) = 0 and nb_car < 10 {
		// Create a new car with is desired speed
		// The position and the target of the car depends of the "right" variable
		create car {
			speed <- desired_speed;
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
}

// Road species
species road {
	// Standard road shape, black and 5px
	aspect default {
		draw world_shape color: #lightgray;
	}

}

// Car species (with skill moving)
species car skills: [moving] {
	// If true the car is controlled by user
	bool controlled <- false;
	
	// Reference of the followed car
	agent next_moving_agent <- nil;
	// Car target (is it depends of "right" variable)
	point target;
	// View 
	float view <- 3.0;
	
	// Effect zone (following behavior)
	geometry sensing_zone <- rectangle({spacing + (speed ^ 2), (speed / desired_speed) * (view * 2.0) + width});
	
	// Distance to target
	float distance;
	// Direction of the target
	point direction;

	// Linear params ***************************
	float acc <- 0.0 #m / (#s ^ 2);
	float reactivity <- 2.0;
	// *****************************************

	// Gipps params ****************************
	float alpha <- 2.5;
	float beta <- 0.025;
	float gamma <- 0.5;
	float spacing <- 2.0 #m;
	float max_acc <- (0.1 #m / (#s ^ 2));
	float size <- 4.0 #m;
	float width <- 1.5 #m;
	float desired_speed <- 5.56 #m / #s; // 20km/h
	float reaction_time <- 1.5 #s;
	// *****************************************
	
	// Argus size
	geometry shape <- rectangle({size, width});

	// Standard car, blue rectangle (1.5m x 4.0m argus)
	aspect default {
		// Draw car
		draw shape color: #red; //rnd_color(255);
		if(false) {
			// Draw the effect zone used in "following behavior"
			draw sensing_zone color: #darkcyan empty: true;
			// Draw speed
			draw line(location, location + (direction.y * speed)) color: #green;
		}
	}

	// Driver reflex
	reflex drive {
		// Get distance and direction
		distance <- location distance_to target;
		direction <- {(target.x - location.x) / distance, (target.y - location.y) / distance};
		
		// Get all detected agents
		list<agent> all_agents <- list<agent>((car + guest)
			where (a: a != nil 						// Not nil
				and !dead(a) 						// Not dead
				and a != self						// Not itself
				and a.shape overlaps sensing_zone 	// Overlap the effect_zone
			)
		);
		
		// Get closest agent in all detected agents
		agent closest_agent <- nil;
		loop current_agent over: all_agents {
			if(closest_agent = nil or current_agent.location distance_to location < closest_agent.location distance_to location) {
				closest_agent <- current_agent;
			} 
		}		
		
		// If there is no closest agent then there is no agent to follow
		float next_moving_agent_speed;
		if(closest_agent != nil) {
			// Get speed of the closest agent
			float closest_speed <- get_dot_product_speed(closest_agent);
			if(closest_speed > desired_speed) {
				next_moving_agent <- nil;
			} else {
				next_moving_agent <- closest_agent;
				next_moving_agent_speed <- closest_speed;
			}
		} else {
			next_moving_agent <- nil;
		}
	
		// If the car is controlled
		if (controlled) {
			// Compute acceleration speed (Linear)
			acc <- (reactivity / reaction_time) * (controlled_speed - speed);
			speed <- speed + (acc * step);
		} else {
			// If there is something to follow
			if (next_moving_agent != nil and not dead(next_moving_agent) ) {
				// Compute acceleration speed (Linear)
				acc <- (reactivity / reaction_time) * (next_moving_agent_speed - speed);
				speed <- speed + (acc * step);
			} else {
				// Compute acceleration speed (Gipps)
				speed <- speed + alpha * max_acc * reaction_time * (1.0 - (speed / desired_speed)) * sqrt(beta + (speed / desired_speed));
			}

		}
		
		// Move skill
		do move heading: (self) towards (target) speed: speed;	
		
		// Change "effect zone" with new location and speed
		point loc <- {direction.x * ((spacing + (speed ^ 2) + size) / 2.0) + location.x, direction.y + location.y};
		sensing_zone <- rectangle({spacing + (speed ^ 2), (speed / desired_speed) * (view * 2.0) + width}) at_location loc;
	}

	// Die if car is out of bound
	reflex die when: (location.x > world_shape.width - (size / 2.0)) or (location.x < (size / 2.0)) {
		nb_car <- nb_car - 1;
		do die();
	}
	
	// Get speed composant
	float get_dot_product_speed(agent a) {
		
		// Get data
		point closest_target <- a get("destination");
		float closest_speed_norm <- float(a get("speed"));
		
		// Compute
		float res <- 0.0;
		if(closest_target != nil and closest_speed_norm != nil and a.location != closest_target) {
			float closest_distance <- a.location distance_to closest_target;
			point closest_direction <- {(closest_target.x - a.location.x) / closest_distance, (closest_target.y - a.location.y) / closest_distance};
			
			res <- (direction * closest_direction) * closest_speed_norm;
		}
		
		return res;
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
