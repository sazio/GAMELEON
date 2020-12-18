/**
* Name: MultiAgentCovid_19
* Based on the internal empty template. 
* Author: Simone Azeglio, Matteo Fordiani
* Tags: 
*/

// Per caricare file GIS 
model load_shape_file 
 
global {
	// Global Variables 
	//Number of susceptible host at init
    int number_S <- 700;
    //Number of infected host at init
    int number_I <- 60;
    //Number of resistant host at init
    int number_R <- 0 ;
    //Rate for the infection success 
	float beta <- 0.05 ;
	//Mortality rate for the host
	float nu <- 0.001 ;
	//Rate for resistance 
	float delta <- 0.005;
	//Number total of hosts <- sostituisco in number of people
	// int numberHosts <- number_S+number_I+number_R;
	//Boolean to represent if the infection is computed locally
	bool local_infection <- true parameter: "Is the infection computed locally?";
	//Range of the cells considered as neighbours for a cell
	int neighbours_size <- 2 min:1 max: 5 parameter:"Size of the neighbours";
	float infection_distance <- 25.0 #m;
	float proba_infection <- 0.95;
	float infection_time <- 48 #h;
	float R0 ;
	float step <- 60 #mn;
	date starting_date <- date("2020-01-22-00-00-00");	
	int nb_people <- number_S+number_I+number_R;
	
	// working time 
	int min_work_start <- 6;
	int max_work_start <- 9;
	int min_work_end <- 15; 
	int max_work_end <- 18; 
	
	// free time 
	int min_stuff_start <- 15; 
	int min_stuff_end <- 19;
	int max_stuff_start <- 18;  
	int max_stuff_end <- 22; 
	
	float min_speed <- 15.0 #km / #h;
	float max_speed <- 50.0 #km / #h; 
	float staying_coeff update: 10.0 ^ (1 + min([abs(current_date.hour - 9), abs(current_date.hour - 12), abs(current_date.hour - 18)]));
	
	// Environment  ------------------------------------------------------------------------
	// Roads, buildings shapefiles import 
    // file roads_shapefile <- file("D:/MultiAgentCovid/Data/Traffic/Filtered_1st_neigh/2019-04-01-Toronto.shp");
    // file buildings_shapefile <- file("D:/MultiAgentCovid/Data/Buildings/buildings_shp/height_buildings_1st_neigh.shp");
    file roads_shapefile <- file("/Users/simoneazeglio/Desktop/MAS/Data/Traffic/Filtered_1st_neigh/2019-04-01-Toronto.shp");
    file buildings_shapefile <- file("/Users/simoneazeglio/Desktop/MAS/Data/Buildings/buildings_shp/height_buildings_1st_neigh.shp");
     
    // Instantiating Road Network 
    geometry shape <- envelope(roads_shapefile);
    graph road_network;
    
  
    init {
	    //create building from: buildings_shapefile; ----------------------------------------------------
	    create building from: buildings_shapefile with: [type::string(read ("ZN_ZONE_EX"))] {
	    	// Residential buildings are split up in the following categories:
				if type="Residential" or type="Residential Detached"  or type="Residential Apartment" or type="Commercial Residential"
				or type= "Residential Multiple Dwelling" or type="Residential Apartment Commercial" or type="Residential Semi Detached"
				or type="Residential Townhouse"{
					color <- #blue ;
				}	
			// Employement buildings
				else if type ="Employment Industrial" or type="Employment Light Industrial" or type="Employment Heavy Industrial" 
				or type="Employment Industrial Office" or type="Employment Industrial Commercial"{
					color <- #green ;
				}
			// Commercial buildings 
				else if type ="Commercial Residential Employment" or type="Commercial Local"{
					color <- #lime ;
				}
			// Open space places 
				else if type ="Open Space" or type ="Open Space Recreation" or type="Open Space Natural"{
					color <- #yellow ;
				}
			// Institutional Education --> Schools + Universities 
				else if type ="Institutional School" or type ="Institutional Education"{
					color <- #orange ;
				}
			// Place of Worship --> Churches, temples ...  	
				else if type ="Institutional Place of Worship" {
					color <- #maroon ;
				}
			// Institutional General --> Governement & similar
				else if type="Institutional General"{
					color <- #aqua;		
				}
			// Hospitals 	
				else if type ="Institutional Hospital" {
					color <- #red ;
				}	
			// Open Space Golf, Open Space Marina, Utility & Transportation, Utility, UNKNOWN
			}
    
    	list<building> residential_buildings <- building where (each.type="Residential" or each.type="Residential Detached"
    		or each.type="Residential Apartment" or each.type="Commercial Residential" or each.type="Residential Multiple Dwelling"
    		or each.type="Residential Apartment Commercial" or each.type="Residential Semi Detached" or each.type="Residential Townhouse");
    		
		list<building> employement_buildings <- building  where (each.type ="Employment Industrial" or each.type="Employment Light Industrial" 
			or each.type="Employment Heavy Industrial" or each.type="Employment Industrial Office" or each.type="Employment Industrial Commercial") ;
		
		list<building> commercial_buildings <- building  where (each.type ="Commercial Residential Employment" or each.type="Commercial Local") ;
		
		list<building> open_space_buildings <- building  where (each.type ="Open Space" or each.type ="Open Space Recreation" 
			or each.type="Open Space Natural");
		
		list<building> education_buildings <- building  where (each.type ="Institutional School" or each.type ="Institutional Education") ;
		
		list<building> worship_buildings <- building  where (each.type ="Institutional Place of Worship") ;
		
		list<building> government_buildings <- building  where (each.type="Institutional General") ;
		
		list<building> hospital_buildings <- building  where (each.type ="Institutional Hospital") ;
		
    	
   
    	// Weighted road network 
	    create road from:roads_shapefile with:[weight::float(read("weight"))];
	    
	    map<road, float> weights_map <- road as_map (each::each.weight);
	    //write weights_map;  // check - it works! 
	    road_network <- as_edge_graph(road) with_weights weights_map;
		 
		    
    
	    create people number:number_S {
	        speed <- rnd(min_speed, max_speed);
	        
			start_work <- rnd(min_work_start, max_work_start);
			end_work <- rnd(min_work_end, max_work_end);
			
			start_stuff <- rnd(min_stuff_start, max_stuff_start);
			end_stuff <- rnd(min_stuff_end, max_stuff_end);
			
			living_place <- one_of(residential_buildings);  
			working_place <- one_of(employement_buildings);
			stuff_place <- one_of(commercial_buildings);
			
			objective <- "resting";
			 
			location <- any_location_in(living_place); 
			
	     	is_susceptible <- true;
        	is_infected <-  false;
            is_immune <-  false; 
            color <-  #green;
        
	        }
       create people number:number_I {
     	  	speed <- rnd(min_speed, max_speed);
	        
			start_work <- rnd (min_work_start, max_work_start);
			end_work <- rnd(min_work_end, max_work_end);
			
			start_stuff <- rnd(min_stuff_start, max_stuff_start);
			end_stuff <- rnd(min_stuff_end, max_stuff_end);
			
			living_place <- one_of(residential_buildings);  
			working_place <- one_of(employement_buildings);
			stuff_place <- one_of(commercial_buildings);
			
			objective <- "resting";
			 
			location <- any_location_in(living_place); 
			
			is_susceptible <-  false;
            is_infected <-  true;
            is_immune <-  false; 
            color <-  #red; 
			
        
        }
        
      create people number:number_R {
        	speed <- rnd(min_speed, max_speed);
	        
			start_work <- rnd (min_work_start, max_work_start);
			end_work <- rnd(min_work_end, max_work_end);
			
			start_stuff <- rnd(min_stuff_start, max_stuff_start);
			end_stuff <- rnd(min_stuff_end, max_stuff_end);
			
			living_place <- one_of(residential_buildings);  
			working_place <- one_of(employement_buildings);
			stuff_place <- one_of(commercial_buildings);
			
			objective <- "resting";
			 
			location <- any_location_in(living_place); 
			living_place <- one_of(residential_buildings) ;  
		
			location <- any_location_in(living_place); 
			
			is_susceptible <-  false;
            is_infected <-  false;
            is_immune <-  true; 
            color <-  #fuchsia; 
        
        }
	    }
	}
// Edifici nella città di Toronto

species building {
    string type; 
    rgb color <- #gray;
    bool is_infected <- false;
    float infection_time;
    list<people> people_in_building;
    
    aspect base {
    draw shape color: color ;
    }
    
    reflex get_people when: is_infected {
    	self.people_in_building <- people inside self;
    }
    
    reflex infect when: is_infected {
//    	loop index from: 0 to: length(list_of_string) - 1 step: 2 {
//			write "" + index +"th element of " + list_of_string;
//			write "  " + sample(list_of_string[index]); 
//		}
    	loop index from: 0 to: length(people_in_building) - 1 step: 1 {
    		people agt <- people_in_building[index];
    		if (agt.is_susceptible and flip(proba_infection)) {
    		agt.is_infected <- true;
    		agt.is_susceptible <- false;
    		agt.is_immune <- false;
    		}
    	}
	}
	reflex become_immune when: is_infected and flip(1/48) {
    	is_infected <- false;
    }
}

// Strade di Toronto
species road {
	float weight;
    aspect geom {
    draw shape color: #black;
    }
     
}



// Persone
species people skills:[moving]{
	float speed; 
	int staying_counter; 
	
    rgb color <- #fuchsia ;
    
    building living_place <- nil ;
    building working_place <- nil ;
    building stuff_place <- nil; 
     
	
	int start_work ;
	int end_work  ;
	int start_stuff; 
	int end_stuff; 
	
	string objective ; 
	point target <- nil;
	
	//Booleans to represent the state of the host agent
	bool is_susceptible <- false;
	bool is_infected <- false;
    bool is_immune <- false;
 
	// Qua si possono metter diversi reflex in base a quali posti
	// vogliamo far visitare all'agente: chiesa, parco... con orari precisi o 
	// probabilità associata all'azione in base all'ora / giorno 
	
	reflex time_to_work when: current_date.hour = start_work and objective = "resting"{
		objective <- "working" ;
		target <- any_location_in (working_place);
	}
	
	reflex time_to_do_stuff when: current_date.hour = start_stuff and objective = "working"{
		objective <- "doing_stuff" ;
		target <- any_location_in (stuff_place);
		
	}
		
	reflex time_to_go_home when: current_date.hour = end_work and objective = "doing_stuff"{
		objective <- "resting" ;
		target <- any_location_in (living_place); 
	} 
	
	reflex staying when: target = nil {
		staying_counter <- staying_counter + 1;
		if flip(staying_counter / staying_coeff) {
			target <- any_location_in(one_of(building));
		}
	}
	
	// Importante, in questo modo salviamo i cammini di ogni agente!!
	// sarebbe bene impostare abitudini (ad esempio, stesso posto per andare a lavoro 
	// e stessa casa) 	
	reflex move when: target != nil{
		path path_to_store <- goto(target:target, on:road_network, return_path:true);
		//write path_to_store; // check - it works! 
			 if (location = target) {
				target <- nil;
				staying_counter <- 0;
			}  
			
		}
		
		 //Reflex to make the agent infected if it is susceptible
//    reflex become_infected when: is_susceptible {
//    	float rate  <- 0.5;
    	//computation of the infection according to the possibility of the disease to spread locally or not
//    	if(local_infection) {
//    		int nb_hosts  <- 0;
//    		int nb_hosts_infected  <- 0;
//    		loop hst over: (() accumulate (people overlapping each)) {
//    			nb_hosts <- nb_hosts + 1;
//    			if (self.is_infected) {nb_hosts_infected <- nb_hosts_infected + 1;}
//    		}
//    		rate <- nb_hosts_infected / nb_hosts;
//    	} else {
//    		rate <- number_I / numberHosts;
//    	}
//    	if (flip(beta * rate)) {
//        	is_susceptible <-  false;
//            is_infected <-  true;
//            is_immune <-  false;
//            color <-  #red;    
//        }
//    }
     reflex infect when: is_infected and building(location) = working_place {
		
			if flip(proba_infection) {
				building place <- building(location);
				
				place.is_infected <- true;
				//working_place.infection_time <- time;
			}
		
	}
    
    //Reflex to make the agent recovered if it is infected and if it success the probability
    reflex become_immune when: is_infected and flip(delta) {
    	is_susceptible <- false;
    	is_infected <- false;
        is_immune <- true;
        color <- #fuchsia;
    }
    //Reflex to kill the agent according to the probability of dying
    reflex shallDie when: is_infected and flip(nu) {
    	//Create another agent
		create species(self)  {
			target <- myself.target ;
			location <- myself.location ; 
		}
       	do die;
    }
	
	
	
	
	aspect base {
		draw circle(10) color: color border: #fuchsia;
	}
}



// Costruzione interfaccia grafica
experiment main_experiment type:gui{
	parameter "Number of people agents" var: nb_people category: "People" ;
	parameter "Earliest hour to start work" var: min_work_start category: "People" min: 5 max: 8;
    parameter "Latest hour to start work" var: max_work_start category: "People" min: 8 max: 12;
    parameter "Earliest hour to end work" var: min_work_end category: "People" min: 12 max: 16;
    parameter "Latest hour to end work" var: max_work_end category: "People" min: 16 max: 23;
    parameter "minimal speed" var: min_speed category: "People" min: 0.1 #km/#h ;
    parameter "maximal speed" var: max_speed category: "People" max: 5 #km/#h;
    parameter "Number of people agents" var: nb_people category: "People" ;
	parameter "Number of Susceptible" var: number_S ;// The number of susceptible
    parameter "Number of Infected" var: number_I ;	// The number of infected
    parameter "Number of Resistant" var:number_R ;	// The number of removed
	parameter "Beta (S->I)" var:beta; 	// The parameter Beta
	parameter "Mortality" var:nu ;	// The parameter Nu
	parameter "Delta (I->R)" var: delta; // The parameter Delta
	parameter "Is the infection computed locally?" var:local_infection ;
	parameter "Size of the neighbours" var:neighbours_size ;

    output {
    	layout #split;
    display map {
    	species building aspect: base; 
        species road aspect:geom; 
        species people aspect: base;      
    }
    
    display chart_people refresh: every(10#cycles) {
			chart "Susceptible People" type: series background: #lightgray style: exploded {
				data "susceptiblep" value: people count (each.is_susceptible) color: #green;
				data "infectedp" value: people count (each.is_infected) color: #red;
				data "immunep" value: people count (each.is_immune) color: #blue;
			}
		}
		
	display chart_building refresh: every(10#cycles) {
		chart "Susceptible Buildings" type: series background: #lightgray style: exploded {
			data "infectedb" value: building count (each.is_infected) color: #red;
			data "immuneb" value: building count (!each.is_infected) color: #blue;
			}
		}
    }
}
    
    




