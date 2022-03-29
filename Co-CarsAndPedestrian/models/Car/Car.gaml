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
	float step <- 0.1;
	
	// Internal time step
	float time_step <- min(0.1, step);
	
	// Number of steps
	float step_count <- step / time_step;

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
	
	// Get speed component from another (moving) agent
	float get_dot_product_speed(agent a, point direction) {
		
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
	
	// Get angle
	float get_angle(point v1, point v2) {
		return atan2(v2.y, v2.x) - atan2(v1.y, v1.x);
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
	// Reference of the followed car
	agent next_moving_agent <- nil;

	// Effect zone (following behavior)
	geometry sensing_zone <- arc((speed / desired_speed) * (view * 2.0) + size, 0.0, 180);	

	// Car target (is it depends of "right" variable)
	point target;
	
	// View 
	float view <- 20.0;

	// Size
	float size <- 1.5;

	// Distance to target
	float distance;
	
	// Direction of the target
	point direction;
	
	// Desired speed
	float desired_speed <- 20 #m / #s;
	
	// Current acceleration
	float acc <- 0.0 #m / (#s ^ 2);
	
	// Max acceleration
	float max_acc <- (3.0 #m / (#s ^ 2));
	
	// Most sever break
	float most_sever_break <- (11.0 #m / (#s ^ 2));
	
	// Reaction time
	float reaction_time <- 1.0;
	
	// Reactivity
	float reactivity <- 3.0;
	
	// Spacing between two transport
	float spacing <- 1.5 #m;
		
	// Controlled
	bool controlled <- false;

	// Argus size
	geometry shape <- rectangle({4.0, size});

	// Driver reflex
	reflex drive {
		// Get distance to target and direction
		distance <- location distance_to target;				
		direction <- {(target.x - location.x) / distance, (target.y - location.y) / distance};
		
		// Get all detected agents
		list<agent> all_agents <- ((guest + car)
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
			float closest_speed <- world.get_dot_product_speed(closest_agent, direction);
			if(closest_speed > desired_speed) {
				next_moving_agent <- nil;
			} else {
				next_moving_agent <- closest_agent;
				next_moving_agent_speed <- closest_speed;
			}
		} else {
			next_moving_agent <- nil;
		}
	
		// If there is something to follow
		if (controlled) {
			// Compute acceleration speed (Linear)
			acc <- (reactivity / reaction_time) * (controlled_speed - speed);
		} else if (next_moving_agent != nil and not dead(next_moving_agent) ) {
			// Compute acceleration speed (Linear)
			acc <- (reactivity / reaction_time) * (next_moving_agent_speed - speed);
		} else {
			// Compute acceleration speed (Linear)
			acc <- (reactivity / reaction_time) * (desired_speed - speed);
		}
		
		// Limitation
		if(acc > max_acc) {
			acc <- max_acc;
		} else if(acc < -most_sever_break) {
			acc <- -most_sever_break;
		} 
		
		// Set speed
		speed <- speed + (acc * time_step);
		
		// Move skill
		do move heading: (self) towards (target) speed: speed;
				
		// Change "effect zone" with new location and speed
		float angle <- world.get_angle({1.0, 0.0}, direction);
		float radius <- (speed / desired_speed) * (view * 2.0) + spacing;
		point rect_pos <- location + (direction * ((radius / 2.0) + 2.0));
		sensing_zone <- rectangle(radius, radius / 2.0) at_location rect_pos rotated_by heading;
	}

	// Die if car is out of bound
	reflex die when: (location distance_to target < 10.0) {
		nb_car <- nb_car - 1;
		do die();
	}
	
	// Standard car, blue rectangle (1.5m x 4.0m argus)
	aspect default {
		// Draw car
		draw shape color: #red;
		if true {
			// Draw the effect zone used in "following behavior"
			draw sensing_zone color: #darkcyan wireframe: true;
			// Draw speed
			draw line(location, location + (direction.y * speed)) color: #green;
		}
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
