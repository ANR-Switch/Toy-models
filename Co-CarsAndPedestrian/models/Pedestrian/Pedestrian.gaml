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
	float crossing_width <- 3.5#m const: true; // min 2.5m (France)
	float crossing_height <- 10#m const: true; // road 3.5mx2 + sidewalk 1.5mx2 (France)
	float sidewalk_height <- 1.5#m const: true; // min 1.4m (France)
	geometry crossing_shape <- rectangle(200, crossing_height);
	geometry crossing_area_shape <- rectangle(crossing_width, crossing_height);
	// The environement shape is the crossing shape
	geometry shape <- crossing_shape;	
	
	// When the simulation is called: init the model
	init {
		// Create sidewalks
		create Sidewalks;
	}
	
	// Generate people
	reflex generate when: (cycle mod generate_frequency) = 0 {
		create People {
			float first_border <- crossing_shape.width / 2.0 - crossing_area_shape.width / 2.0;
			write(first_border);
			location <- {rnd(first_border + head_size / 2.0, first_border + crossing_area_shape.width - (head_size / 2.0)), sidewalk_height / 2.0};
			target <- {location.x, crossing_area_shape.height};		
		}
	}
}

// Sidewalks
species Sidewalks {
	// Up and down sidewalks
	aspect default {
		point location_up <- {crossing_shape.width / 2.0, sidewalk_height / 2.0};
		point location_down <- {crossing_shape.width / 2.0, crossing_shape.height - sidewalk_height / 2.0};
		
		// Sidewalks
		draw rectangle(world.shape.width, sidewalk_height) at: location_up color: #gray;
		draw rectangle(world.shape.width, sidewalk_height) at: location_down color: #gray;
		
		// Crossing area
		draw rectangle(crossing_area_shape.width, sidewalk_height) at: location_up color: #darkgray;
		draw rectangle(crossing_area_shape.width, sidewalk_height) at: location_down color: #darkgray;	
	}
}

// People species (with skill moving [goto])
species People skills: [moving] {
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
experiment Simple type: gui {
	
	// Ouput of the simulation
	output {
		// The main window
		display "main_window" type: opengl {
			// Sidewalks default
			species Sidewalks aspect: default;
			
			// People default
			species People aspect: default;
		}
	}
}
