/**
* Name: Pedestrian
* Pedestrian.
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
	
	// Environement shape
	float sidewalk_height <- 1.5#m const: true; // min 1.4m (France)

	float crossing_width <- 3.5#m const: true; // min 2.5m (France)
	float crossing_height <- 10#m const: true; // road 3.5mx2 + sidewalk 1.5mx2 (France)
	geometry crossing_area_shape <- rectangle(crossing_width, crossing_height);
	
	float world_width <- 10#m const: true;
	float world_height <- 10#m const: true;
	geometry world_shape <- rectangle(world_width, world_height);
	
	// The environement shape is the crossing shape
	geometry shape <- world_shape;	
	
	// When the simulation is called: init the model
	init {
		// Create sidewalks
		create sidewalks;
	}
	
	// Generate people
	reflex generate when: (cycle mod generate_frequency) = 0 {
		create people {
			float first_border <- world_shape.width / 2.0 - crossing_area_shape.width / 2.0;
			location <- {rnd(first_border + head_size / 2.0, first_border + crossing_area_shape.width - (head_size / 2.0)), sidewalk_height / 2.0};
			target <- {location.x, crossing_area_shape.height};		
		}
	}
}

// Sidewalks
species sidewalks {
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
species people skills: [moving] {
	// People head size
	float head_size <- 0.28#m const: true;
	// Min speed (2.5km/h)
	float min_speed <- 0.5555#m/#s const: true;
	// Max speed (5km/h)
	float max_speed <- 1.4#m/#s const: true;
	
	// Speed 
	float speed <- rnd(min_speed, max_speed);
	// Target
	point target;
	
	// Walk straight ahead
	reflex walk {
		//do move heading: (self) towards (target) speed: speed; 
		do goto target: target speed: speed; 
	}
	
	// Die if out of bound
	reflex die when: (location distance_to target < sidewalk_height / 2.0) {
		do die();
	}
	
	// Standard people, blue sphere (head sized) and green speed vector 
	aspect default {
		float distance <- location distance_to target;
		point direction <- {(target.x - location.x) / distance, (target.y - location.y) / distance};
		draw sphere(head_size) color: #blue;
		draw line(location, location + (direction * speed)) color: #green;
	}
}

// GUI Experiment
experiment Pedestrian type: gui {
	
	// Ouput of the simulation
	output {
		// The main window
		display "main_window" type: opengl {
			// Sidewalks default
			species sidewalks aspect: default;
			
			// People default
			species people aspect: default;
		}
	}
}
