/**
* Name: Pedestrian
* Pedestrian model.
* Author: Jean-François Erdelyi
* Tags: 
*/

model Pedestrian

// Bloc global of the simulation
global {
	// Simulation step
	float step <- 0.1;
	
	// People generator rate (+1 -> arithmetic error if value is 0 -> divide by 0)
	int generate_frequency <- 100 update: rnd(250) + 1;
	
	// Guest agents
	list<agent> guest <- nil;
	
	// Environement shape
	float sidewalk_height <- 1.5#m const: true; // min 1.4m (France)

	float crossing_width <- 3.5#m const: true; // min 2.5m (France)
	float crossing_height <- 10#m const: true; // road 3.5mx2 + sidewalk 1.5mx2 (France)
	geometry crossing_area_shape <- rectangle(crossing_width, crossing_height);
	
	// The environement shape
	float world_width <- 10#m const: true;
	float world_height <- 10#m const: true;
	geometry world_shape <- rectangle(world_width, world_height);	
	geometry shape <- world_shape;	
	
	// When the simulation is called: init the model
	init {
		// Create sidewalks
		create sidewalk;
	}
	
	// Generate people
	reflex generate when: (cycle mod generate_frequency) = 0 {
		create person {
			float first_border <- world_shape.width / 2.0 - crossing_area_shape.width / 2.0;
			location <- {rnd(first_border + head_size / 2.0, first_border + crossing_area_shape.width - (head_size / 2.0)), sidewalk_height / 2.0};
			target <- {location.x, crossing_area_shape.height};		
		}
	}
}

// Sidewalks
species sidewalk {
	// Up and down sidewalks
	aspect default {
		point location_up <- {world_shape.width / 2.0, sidewalk_height / 2.0};
		point location_down <- {world_shape.width / 2.0, world_shape.height - sidewalk_height / 2.0};
		
		// Sidewalks
		draw rectangle(world.shape.width, sidewalk_height) at: location_up color: #gray;
		draw rectangle(world.shape.width, sidewalk_height) at: location_down color: #gray;
		
		// Crossing area
		draw rectangle(crossing_area_shape.width, sidewalk_height) at: location_up color: #darkgray;
		draw rectangle(crossing_area_shape.width, sidewalk_height) at: location_down color: #darkgray;	
	}
}

// People species (with skill moving [goto])
species person skills: [moving] {
	// People head size
	float head_size <- 0.28#m const: true;
	// Min speed (2.5km/h)
	float min_speed <- 0.5555#m/#s const: true;
	// Max speed (5km/h)
	float max_speed <- 1.4#m/#s const: true;
	
	// Start time blocked
	float start_blocked;
	// If true force crossing
	bool forced <- false;
	// Minimum size of the sensing zone
	float min_size <- head_size;
	
	// Desired and actual speed
	float desired_speed <- rnd(min_speed, max_speed);
	float speed <- desired_speed;
	
	// Target
	point target;
	// Effect zone 
	geometry sensing_zone <- rectangle(desired_speed, desired_speed);
	
	// Shape of the person
	geometry shape <- sphere(head_size);
	
	// Walk straight ahead
	reflex walk {
		// Get all detected agents
		list<agent> all_agents <- guest 
			where (a: a != nil 						// Not nil
				and !dead(a) 						// Not dead
				and a != self						// Not itself
				and a.shape overlaps sensing_zone 	// Overlap the sensing_zone
			);
		
		// Check if the pedestrian is blocked
		bool blocked <- speed = 0.0;
		// If there is an agent in front of it
		if(length(all_agents) > 0 and !forced) {
			// Set speed to 0.0;
			speed <- 0.0;
			// If the pedestrian is blocked
			if(blocked) {
				// Wait 20 cycle
				if(time - start_blocked >= 20) {
					// Change the minimum effect zone to very thin
					min_size <- 0.1;
				}
			} else {
				// Is not already blocked then get the time
				start_blocked <- time;
			}
		} else {
			// If nothing in front of the desired_speedhen it's not blocked and speed is desired speed
			blocked <- false;
			speed <- desired_speed;
		}
		
		do goto target: target speed: speed;
		
		point loc <- {location.x, location.y + (crossing_area_shape.width * 2) + head_size};
		sensing_zone <- rectangle((speed / desired_speed) * (crossing_area_shape.width * 4) + min_size, crossing_area_shape.width * 4) at_location loc;
	}
	
	// Die if out of bound
	reflex die when: (location distance_to target < sidewalk_height / 2.0) {
		do die();
	}
	
	// Standard people, blue sphere (head sized) and green speed vector 
	aspect default {
		draw shape color: #blue;
		
		if(false) {
			draw sensing_zone color: #darkcyan wireframe: true;
			float distance <- location distance_to target;
			point direction <- {(target.x - location.x) / distance, (target.y - location.y) / distance};
			draw line(location, location + (direction * speed)) color: #green;
		}
	}
}

// GUI Experiment
experiment Pedestrian type: gui {
	
	// Ouput of the simulation
	output {
		// The main window
		display "main_window" type: opengl {
			// Sidewalks default
			species sidewalk aspect: default;
			// People default
			species person aspect: default;
		}
	}
}
