/**
* Name: NewModel
* Based on the internal empty template. 
* Author: simon
* Tags: 
*/

// Per caricare file GIS 
model load_shape_file 
 
global {
	
	 //Numero di persone
    int nb_people <- 1500;
    
    //Step temporale
    float step <- 60 #mn;
    
    // data di inizio infezione
    date starting_date <- date([2020,1,1,3,0,0]);
    
	// Questi file, strade e edifici sono stati preprocessati nel notebook "GIS_Data_Turin"
    file roads_shapefile <- file("C:/Users/simon/Desktop/MAS/Data/Traffic/Filtered-top23-neigh/2019-04-01-Toronto.shp");
    file buildings_shapefile <- file("C:/Users/simon/Desktop/MAS/Data/Buildings/buildings_shp/height_build_23_neigh.shp");
    
    
    // Creaiamo il grafo stradale come base per il nostro modello
    geometry shape <- envelope(roads_shapefile);
    graph road_network;
    
    // 
    
    
    
    //************************************
    // Distribuzione di traffico (scrapata) da Tom-Tom 
    point the_target <- any_location_in(one_of(building));
    
    list<float> hour_traffic <- []; 
    	
    
    list hour_list <- [3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,0,1,2,
    				   3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,0,1,2,
    				   3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,0,1,2,
    				   3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,0,1,2,
    				   3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,0,1,2,
    				   3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,0,1,2,
    				   3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,0,1,2
    					];
    
    
    
   //**************************************
   

   init {
   	
   	file traffic_week <- file("C:/Users/simon/Documents/MAS/MultiAgentCovid/trafficweek.csv");
    	loop el over: traffic_week {
    		add float(el) to: hour_traffic; 
    	}
    	
    	write length(hour_traffic);
    	write length(hour_list);
    	
    // inizializzazione da file 
    create building from: buildings_shapefile;
    
    create road from: roads_shapefile;
    road_network <- as_edge_graph(road);
    
    //create hospitals from: hospitals_shapefile;
    
    
    create people number:nb_people {
        //location <- any_location_in(one_of(building));
         home <- one_of(building);
   		 workplace <- one_of(building);
   	   	 location <- any_location_in(home);
         prob_to_move <- 0.0;
        }
    /* ask nb_infected_init among people {
        is_infected <- true;
        }
        
    reflex end_simulation when: infected_rate = 1.0 {
        do pause;
    }   */
    }
}
// Edifici nella città di Toronto

species building {
    string type; 
    rgb color <- #gray  ;
    
    aspect base {
    draw shape color: color ;
    }
}

// Strade di Toronto
species road {
    aspect geom {
    draw shape color: #black;
    }
}

/*species hospitals {
    string type; 
    rgb color <- #red  ;
    
    aspect base {
    draw shape color: color ;
    }
}*/

// Persone
species people skills:[moving]{
    rgb color <- #yellow ;
    building home <- nil;
    building workplace <- nil;
    point the_target <- nil;
   	building dest <- nil;
    float prob_to_move;
    
    reflex set_dest when: the_target = nil {
    	if dest = workplace{
    		dest <- home;
    	}
    	else {
    		dest <- workplace;
    	}
    	
    	loop i from: 0 to: 23{
    		if current_date.hour = hour_list at i{
    			prob_to_move <- hour_traffic at i; 
    		}
    	}
    	if flip(prob_to_move/100){
    		the_target <- any_location_in(dest);
    	}
    }
    
    reflex move when: the_target != nil{
    	path path_followed <- goto( target: the_target, on: road_network, speed:5#km/#hour, return_path: true);
    	if the_target = location{
    		the_target <- nil;
    	}
    }
    
    aspect base {
    draw circle(20) color: color border: #blue;
    }
}


// Costruzione interfaccia grafica
experiment main_experiment type:gui{
	parameter "Number of people agents" var: nb_people category: "People" ;

    output {
    	monitor date value: current_date;
    	
    display map {
    	species building aspect: base; 
    	//species hospitals aspect: base;
        species road aspect:geom; 
        species people aspect: base;      
    }
    }
}


