debug(3).

// Name of the manager
manager("Manager").

// Team of troop.
team("ALLIED").
// Type of troop.
type("CLASS_SOLDIER").


{ include("jgomas.asl") }


// Plans


/*******************************
*
* Actions definitions
*
*******************************/

/////////////////////////////////
//  GET AGENT TO AIM 
/////////////////////////////////  
/**
* Calculates if there is an enemy at sight.
* 
* This plan scans the list <tt> m_FOVObjects</tt> (objects in the Field
* Of View of the agent) looking for an enemy. If an enemy agent is found, a
* value of aimed("true") is returned. Note that there is no criterion (proximity, etc.) for the
* enemy found. Otherwise, the return value is aimed("false")
* 
* <em> It's very useful to overload this plan. </em>
* 
*/  
+!get_agent_to_aim
<-  ?debug(Mode); if (Mode<=2) { .println("Looking for agents to aim."); }
?fovObjects(FOVObjects);
.length(FOVObjects, Length);

?debug(Mode); if (Mode<=1) { .println("El numero de objetos es:", Length); }

if (Length > 0) {
    +bucle(0);
    
    -+aimed("false");
    
    while (aimed("false") & bucle(X) & (X < Length)) {
        
        //.println("En el bucle, y X vale:", X);
        
        .nth(X, FOVObjects, Object);
        // Object structure
        // [#, TEAM, TYPE, ANGLE, DISTANCE, HEALTH, POSITION ]
        .nth(2, Object, Type);
        
        ?debug(Mode); if (Mode<=2) { .println("Objeto Analizado: ", Object); }
        
        if (Type > 1000) {
            ?debug(Mode); if (Mode<=2) { .println("I found some object."); }
        } else {
            // Object may be an enemy
            .nth(1, Object, Team);
            ?my_formattedTeam(MyTeam);
            
            if (Team == 200) {  // Only if I'm ALLIED
				
                ?debug(Mode); if (Mode<=2) { .println("Aiming an enemy. . .", MyTeam, " ", .number(MyTeam) , " ", Team, " ", .number(Team)); }
                +aimed_agent(Object);
                -+aimed("true");
                
            }
            
        }
        
        -+bucle(X+1);
        
    }
    
    
}

-bucle(_).

/////////////////////////////////
//  LOOK RESPONSE
/////////////////////////////////
+look_response(FOVObjects)[source(M)]
    <-  //-waiting_look_response;
        .length(FOVObjects, Length);
        if (Length > 0) {
            ?debug(Mode); if (Mode<=1) { .println("HAY ", Length, " OBJETOS A MI ALREDEDOR:\n", FOVObjects); }
        };    
        -look_response(_)[source(M)];
        -+fovObjects(FOVObjects);
        //.//;
        !look.
      
        
/////////////////////////////////
//  PERFORM ACTIONS
/////////////////////////////////
/**
* Action to do when agent has an enemy at sight.
* 
* This plan is called when agent has looked and has found an enemy,
* calculating (in agreement to the enemy position) the new direction where
* is aiming.
*
*  It's very useful to overload this plan.
* 
*/
+!perform_aim_action
    <-  // Aimed agents have the following format:
        // [#, TEAM, TYPE, ANGLE, DISTANCE, HEALTH, POSITION ]
        ?aimed_agent(AimedAgent);
		.println("Agente: ",AimedAgent);
        ?debug(Mode); if (Mode<=1) { .println("AimedAgent ", AimedAgent); }
        .nth(1, AimedAgent, AimedAgentTeam);
        ?debug(Mode); if (Mode<=2) { .println("BAJO EL PUNTO DE MIRA TENGO A ALGUIEN DEL EQUIPO ", AimedAgentTeam);             }
        ?my_formattedTeam(MyTeam);

        if (AimedAgentTeam == 200) {
				
				if(not atLeastOneTime){
					+atLeastOneTime;
					+cont(1);
				}
				
				if(cont(C) & C == 1){	//As this action is made twice for each movement of the AXIS, 
										//it have a counter to only make it once each two.
					-+cont(2);
					
					.nth(6, AimedAgent, NewDestination);
					.nth(2, AimedAgent, AimedType);
					.term2string(NewDestination, DestinationString);	//The position is recieved as a structure so we have to pass it to String
					!extractXZ(DestinationString);
					?extractXZ(X, Z);
					
					if(timesSeen(NumTimes) & NumTimes > 2){	//If it has tried more than 4 times but the type of the agent is not
															//the same as the first read type, it deletes all the info like nothing has happened
						-savedPos1;
						-savedPos2;
						-savedPos3;
						-savedPos4;
						-+timesSeen(1);
					}else{
						if(not savedPos4){
							.println("No guardado Pos4");
							//If we do not have pos4 we have to look pos3
							if(not savedPos3){
								.println("No guardado Pos3");
								//If we do not have pos3 we have to look pos2
								if(not savedPos2){
									.println("No guardado Pos2");
									//If we do not have pos2 we have to look pos1
									if(not savedPos1){
										.println("No guardado Pos1");
										//If we do not have pos1, we save it
										+savedPos1;
										-+pos1(X,Z);
										-+typeAgent(AimedType);
										-+timesSeen(1);
									}else{
										.println("Guardada Pos1");
										?typeAgent(InitialType);
										if(AimedType == InitialType){
											//If we have pos1, then save pos2
											+savedPos2;
											-+pos2(X,Z);
										}else{
											?timesSeen(T);
											-+timesSeen(T+1);
										}
									}
								}else{
									.println("Guardada Pos2");
									?typeAgent(InitialType);
									if(AimedType == InitialType){
										//If we have pos2, then save pos3
										+savedPos3;
										-+pos3(X,Z);
									}else{
										?timesSeen(T);
										-+timesSeen(T+1);
									}
								}
							}else{
								.println("Guardada Pos3");
								?typeAgent(InitialType);
								if(AimedType == InitialType){
									//If we have pos3, then save pos4
									+savedPos4;
									-+pos4(X,Z);
								}else{
									?timesSeen(T);
									-+timesSeen(T+1);
								}
							}
						}else{
							.println("Guardada Pos4");
							//That means we have pos1, pos2, pos3 and pos4 and we can calculate the trajectory of the agent
							?pos1(X1,Z1);
							?pos2(X2,Z2);
							?pos3(X3,Z3);
							?pos4(X4,Z4);
							
							PredX3 = X2 + (X2 - X1);
							PredZ3 = Z2 + (Z2 - Z1);
							
							if(math.round(X3*100) == math.round(PredX3*100) & math.round(Z3*100) == math.round(PredZ3*100)){
								.println("Agent ", AimedAgent, " is NOT Crazy.");
							}else{
								PredX4 = X3 + (X3 - X2);
								PredZ4 = Z3 + (Z3 - Z2);
								if(math.round(X4*100) == math.round(PredX4*100) & math.round(Z4*100) == math.round(PredZ4*100)){
									.println("El agente ", AimedAgent, " NO es esta Crazy.");
								}else{
									.println("Agent ", AimedAgent, " IS Crazy. Attack it.");
									+order(move,X4,Z4)[source (_)];	//We order to go to the last position we know of that agent we have evaluated
																	//because if we go to actual X and Z it may not be the same agent.
								}
							}
								
							-savedPos1;
							-savedPos2;
							-savedPos3;
							-savedPos4;
							-+timesSeen(1);
						}
					}
					
				}else{
					-+cont(1);
				}

				?debug(Mode); if (Mode<=1) { .println("NUEVO DESTINO DEBERIA SER: ", NewDestination); }
        }
 .

 
 
/**
* Action to do when the agent is looking at.
*
* This plan is called just after Look method has ended.
* 
* <em> It's very useful to overload this plan. </em>
* 
*/
+!perform_look_action .
   /// <- ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR PERFORM_LOOK_ACTION GOES HERE.") }. 

/**
* Action to do if this agent cannot shoot.
* 
* This plan is called when the agent try to shoot, but has no ammo. The
* agent will spit enemies out. :-)
* 
* <em> It's very useful to overload this plan. </em>
* 
*/  
+!perform_no_ammo_action . 
   /// <- ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR PERFORM_NO_AMMO_ACTION GOES HERE.") }.
    
/**
     * Action to do when an agent is being shot.
     * 
     * This plan is called every time this agent receives a messager from
     * agent Manager informing it is being shot.
     * 
     * <em> It's very useful to overload this plan. </em>
     * 
     */
+!perform_injury_action .
    ///<- ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR PERFORM_INJURY_ACTION GOES HERE.") }. 
        

/////////////////////////////////
//  SETUP PRIORITIES
/////////////////////////////////
/**  You can change initial priorities if you want to change the behaviour of each agent  **/
+!setup_priorities
    <-  +task_priority("TASK_NONE",0);
        +task_priority("TASK_GIVE_MEDICPAKS", 2000);
        +task_priority("TASK_GIVE_AMMOPAKS", 0);
        +task_priority("TASK_GIVE_BACKUP", 0);
        +task_priority("TASK_GET_OBJECTIVE",1000);
        +task_priority("TASK_ATTACK", 1000);
        +task_priority("TASK_RUN_AWAY", 1500);
        +task_priority("TASK_GOTO_POSITION", 750);
        +task_priority("TASK_PATROLLING", 500);
        +task_priority("TASK_WALKING_PATH", 1750).   



/////////////////////////////////
//  UPDATE TARGETS
/////////////////////////////////
/**
 * Action to do when an agent is thinking about what to do.
 *
 * This plan is called at the beginning of the state "standing"
 * The user can add or eliminate targets adding or removing tasks or changing priorities
 *
 * <em> It's very useful to overload this plan. </em>
 *
 */

+!update_targets
	<-	?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR UPDATE_TARGETS GOES HERE.") }.
	
	
	
/////////////////////////////////
//  CHECK MEDIC ACTION (ONLY MEDICS)
/////////////////////////////////
/**
 * Action to do when a medic agent is thinking about what to do if other agent needs help.
 *
 * By default always go to help
 *
 * <em> It's very useful to overload this plan. </em>
 *
 */
 +!checkMedicAction
     <-  -+medicAction(on).
      // go to help
      
      
/////////////////////////////////
//  CHECK FIELDOPS ACTION (ONLY FIELDOPS)
/////////////////////////////////
/**
 * Action to do when a fieldops agent is thinking about what to do if other agent needs help.
 *
 * By default always go to help
 *
 * <em> It's very useful to overload this plan. </em>
 *
 */
 +!checkAmmoAction
     <-  -+fieldopsAction(on).
      //  go to help



/////////////////////////////////
//  PERFORM_TRESHOLD_ACTION
/////////////////////////////////
/**
 * Action to do when an agent has a problem with its ammo or health.
 *
 * By default always calls for help
 *
 * <em> It's very useful to overload this plan. </em>
 *
 */
+!performThresholdAction
       <-
       
       ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR PERFORM_TRESHOLD_ACTION GOES HERE.") }
       
       ?my_ammo_threshold(At);
       ?my_ammo(Ar);
       
       if (Ar <= At) { 
          ?my_position(X, Y, Z);
          
         .my_team("fieldops_ALLIED", E1);
         //.println("Mi equipo intendencia: ", E1 );
         .concat("cfa(",X, ", ", Y, ", ", Z, ", ", Ar, ")", Content1);
         .send_msg_with_conversation_id(E1, tell, Content1, "CFA");
       
       
       }
       
       ?my_health_threshold(Ht);
       ?my_health(Hr);
       
       if (Hr <= Ht) { 
          ?my_position(X, Y, Z);
          
         .my_team("medic_ALLIED", E2);
         //.println("Mi equipo medico: ", E2 );
         .concat("cfm(",X, ", ", Y, ", ", Z, ", ", Hr, ")", Content2);
         .send_msg_with_conversation_id(E2, tell, Content2, "CFM");

       }
       .
       
/////////////////////////////////
//  ANSWER_ACTION_CFM_OR_CFA
/////////////////////////////////

     

    
+cfm_agree[source(M)]
   <- ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR cfm_agree GOES HERE.")};
      -cfm_agree.  

+cfa_agree[source(M)]
   <- ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR cfa_agree GOES HERE.")};
      -cfa_agree.  

+cfm_refuse[source(M)]
   <- ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR cfm_refuse GOES HERE.")};
      -cfm_refuse.  

+cfa_refuse[source(M)]
   <- ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR cfa_refuse GOES HERE.")};
      -cfa_refuse.  



/////////////////////////////////
//  Initialize variables
/////////////////////////////////

+!init
   <- ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR init GOES HERE.");}
		!extractXZ("pos(12.213, 0, 3.258)");	//Or in a variable
		?extractXZ(X, Z);
		.println( "X is ", X, ", Z is ",Z);
		if(.string(X)){.println("X es string");}
		if(.string(Z)){.println("Z es string");}
		if(.number(X)){.println("X es un numero");}
		R = math.round(X);
		.println("Round: ", R);
		.

/////////////////////////////////
//  EXTRACT_X_Z
/////////////////////////////////
// Given a position in a String, returns the X and Z of it.
// @results +extractXZ(X,Z)
// Usage:
/*
	!extractXZ("pos(12.213, 0, 3.258)");	//Or in a variable
	?extractXZ(X, Z);
	.println( "X is ", X, ", Z is ",Z);
*/
+!extractXZ(Position)
	<-	
		.length(Position, LenPos);
		if(.substring(",",Position,FirstCom)){}
		
		//To obtain X
		-+vl(LenPos - 1);
		-+posString(Position);
		while(posString(S) & vl(It) & FirstCom <= It){
			.delete(It,S,StringReduced);
			-+vl(It-1);
			-+posString(StringReduced);
		}
		?posString(SAux);
		.delete(0,SAux,S1);
		.delete(0,S1,S2);
		.delete(0,S2,S3);
		.delete(0,S3,S4);
		-+posString(S4);
		?posString(ReducedPosition);
		X = ReducedPosition;
		
		//to obtain Z
		.delete(FirstCom, Position, Position2);
		
		if(.substring(",",Position2,SecondCom)){}
		
		-+vl(0);
		-+posString(Position2);
		
		while(posString(S) & vl(It2) & It2 <= SecondCom){
			.delete(0,S,StringReduced);
			-+vl(It2+1);
			-+posString(StringReduced);	
		}
		
		?posString(ZAux);
		.length(ZAux, LenZ);
		.delete(LenZ-1,ZAux,Z);
		
		.term2string(NumX,X);
		.term2string(NumZ,Z);
		
		-+extractXZ(NumX,NumZ);
		.

