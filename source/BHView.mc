using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.Attention;
using Toybox.Application.Properties;
using Toybox.Application.Storage;
using Toybox.FitContributor;

class BHView extends WatchUi.DataField {


    private var _positions; //zone d'affichage
	hidden var bhLabel; //libellé barrière active
	hidden var bhSubLabel; //Sous libellé barrière active
	hidden var bhTime;  //temps barrière active en minute
	hidden var bhTimeSec; //temps barrière active en seconde
	hidden var bhActive; // numero de barrière active
	hidden var bhMaxSaisie; // nombre de barrière max valide
	hidden var bhMaxPossible; // nombre de barrière max possible
	hidden var bhLabelDefaut; // valeur par defaut du libellé
	hidden var bhTimeDefaut; // valeur par défaut du temps
	hidden var isEnRetard; // indique si on est en retard
	hidden var isAutomatique; // indique si le passage au suivant est automatique
	hidden var decalageVagueSec; // indique le temps entre la première vague et celle du coureur
	hidden var alarmeTemps1; // temps alarme1
	hidden var alarmeTemps1Actif; //Afficher alarme1
	hidden var alarmeTemps2; // temps alarme2
	hidden var alarmeTemps2Actif; //Afficher alarme2
	hidden var alarmeTemps3; // temps alarme3
	hidden var alarmeTemps3Actif; //Afficher alarme3
	
	hidden var bhTimeChartField = null; // champ graphique
	hidden var bhTimeLapField = null; // champ LAP
	hidden var bhStepSumField = null; // champ nombre de pas
	hidden var bhBatterySumField = null; // champ usage de la batterie
	hidden var bhBatteryChartField = null; // champ graphique de la batterie
	
	hidden var mbatteryAvant = null; // sauv valeur de la batterie dernier calcul
	hidden var mbatterySession = 0; // valeur de la batterie de la session
	
	hidden var mTimerRunning = false; // le timer est actif
	
	hidden var mStepsGlobal = null; // sauv le nombre de pas dernier calcul
	hidden var mStepsSession = 0; // nb de pas de la session
	
    hidden var label; // libellé affiché
    hidden var subLabel; // sous libellé affiché
    hidden var mValue; // temps affiché
	hidden var layoutOK;  //indique si la layout est gérée

    function initialize() {
        DataField.initialize();
		bhLabelDefaut = WatchUi.loadResource(Rez.Strings.DefautLabelBarrieres); //init DefautLabelBarrieres  
        Storage.setValue("DefautTimeBarrieres", "0:00");    //init DefautTimeBarrieres  
        bhTimeDefaut = Storage.getValue("DefautTimeBarrieres");      
        Storage.setValue("bhMaxPossible", 20);    //init bhMaxPossible
        bhMaxPossible = Storage.getValue("bhMaxPossible");
        Storage.setValue("bhMaxSaisie", 1);    //init bhMaxSaisie
        bhMaxSaisie = Storage.getValue("bhMaxSaisie");
        isEnRetard = false;    //init isEnRetard
        Storage.setValue("bhActive", 1);    //init bhActive
        Storage.setValue("alarme1", 3600); // init temps alarme1
        alarmeTemps1 = Storage.getValue("alarme1").toNumber(); // init temps alarme1
        alarmeTemps1Actif = readKey("alarme1Active",true);    //init alarme alarme1
        Storage.setValue("alarme2", 1800); // init temps alarme2
        alarmeTemps2 = Storage.getValue("alarme2").toNumber(); // init temps alarme2
        alarmeTemps2Actif = readKey("alarme2Active",true);    //init alarme alarme2
        Storage.setValue("alarme3", 900); // init temps alarme3
        alarmeTemps3 = Storage.getValue("alarme3").toNumber(); // init temps alarme3
        alarmeTemps3Actif = readKey("alarme3Active",true);    //init alarme alarme1
        controleParamBH(); // controle info BH et récup parametres
                
		label = "";
		subLabel = "";
        mValue = "";
        layoutOK = false;
                
        //Batterie
        mbatteryAvant = Math.round(System.getSystemStats().battery).toNumber();
        
        //FIT        
        bhTimeLapField = createField(
        	WatchUi.loadResource(Rez.Strings.lap_label),
           	0,
           	FitContributor.DATA_TYPE_STRING,
           	{:mesgType=>FitContributor.MESG_TYPE_LAP, :count=>32, :units=>WatchUi.loadResource(Rez.Strings.unit_vide)}
        );
        bhTimeChartField = createField(
          	WatchUi.loadResource(Rez.Strings.data_label),
            1,
            FitContributor.DATA_TYPE_SINT32,
            {:mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>WatchUi.loadResource(Rez.Strings.field_units)}
        );
        bhBatterySumField = createField(
        	WatchUi.loadResource(Rez.Strings.battery_label),
           	3,
           	FitContributor.DATA_TYPE_UINT16,
           	{:mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>WatchUi.loadResource(Rez.Strings.unit_percent)}
        );
        bhBatteryChartField = createField(
        	WatchUi.loadResource(Rez.Strings.batteryGraph_label),
           	4,
           	FitContributor.DATA_TYPE_UINT8,
           	{:mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>WatchUi.loadResource(Rez.Strings.unit_percentBattery)}
        );
        
        // init des stats
        bhTimeLapField.setData("");
    	bhBatterySumField.setData(0);
    	//complement au FIT selon type montre
        FIT();
    }
    
    (:runnerVersion)
    function FIT() {
    	//on gere les pas
        bhStepSumField = createField(
        	WatchUi.loadResource(Rez.Strings.step_label),
           	2,
           	FitContributor.DATA_TYPE_UINT32,
           	{:mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>WatchUi.loadResource(Rez.Strings.unit_step)}
        );
        
        // init des stats
    	bhStepSumField.setData(0);
    }
    
    (:edgeVersion)
    function FIT() {
    	//on ne fait rien de plus
    	return;
    }
    
 	// on lance l'activité
    function onStart() {
		var activityInfo = Activity.getActivityInfo();		
		// if the activity has restarted after "resume later", load previously stored values
		if (activityInfo != null && activityInfo.elapsedTime > 0) {
	        mStepsSession = Storage.getValue("stepsSession");
	        if (mStepsSession == null) {
	            mStepsSession = 0;
	        }
	        mbatterySession = Storage.getValue("batterySession");
	        if (mbatterySession == null) {
	            mbatterySession = 0;
	        }
        }
        //libération de la mémoire
        activityInfo = null;
 	} 	
 	
 	// on stoppe l'activité
    function onStop() {
    	// store current values of steps on stop for later usage (e.g., resume later)
        Storage.setValue("stepsSession", mStepsSession);
    	// store current values of battery on stop for later usage (e.g., resume later)
        Storage.setValue("batterySession", mbatterySession);
    }
    
     // Timer start
    function onTimerStart() {
    	mTimerRunning = true;    	
        //Batterie
        mbatteryAvant = Math.round(System.getSystemStats().battery).toNumber();
    }
    
     // Timer resume
    function onTimerResume() {
    	mTimerRunning = true;
    }
    
    // Timer stop
    function onTimerStop() {
    	mTimerRunning = false;
    	mStepsGlobal = null;
    }
    
    // Timer pause
    function onTimerPause() {
    	mTimerRunning = false;
    	mStepsGlobal = null;
    }
    
    // Timer Reset on remet à zéro
    function onTimerReset() {
    	mStepsSession = 0;
    	mbatterySession = 0;
    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info) {
    
    	recupProperties();
    	// libellé affiché
    	label = bhLabel;
    	subLabel = bhSubLabel;
        // See Activity.Info in the documentation for available information
        // si il y a un elapseTime
        if(info has :elapsedTime){
            if(info.elapsedTime != null){ // non null
            	// temps de course en sec
            	var elapsedTime = (info.elapsedTime ? info.elapsedTime : 0) / 1000; 
        		// calcul de l'ecart avec la barrière active
				//si départ par vague on substrait le décalage de la barrière
				var bhTimeSecDecale = (bhTimeSec-decalageVagueSec);
        		// temps BH - temps de course
				var delta = new Time.Duration(bhTimeSecDecale).subtract(new Time.Duration(elapsedTime));
				// Si départ en vague
        		// si activité commencée
        		if(elapsedTime !=0){
        			// si temps activité >= (barrière horaire - décalage depart par vague)
        			if(elapsedTime >= (bhTimeSecDecale)){
        				// je suis en retard
        				isEnRetard = true;
        			} else { // sinon
        				// je suis en avance
        				isEnRetard = false;       			
        			}
        			//Si alerte existe
        			if(BHView has :showAlert) {
        				// si je suis en avance
        				if(!isEnRetard){
        					// s'il est le moment de déclencher l'Alarme1
                    		if(delta.value().toString().equals(alarmeTemps1.toString())) {
                    			// si actif
                    			if(alarmeTemps1Actif) {
                    				// on déclenche l'alarme1
                        			alarme(label, alarmeTemps1);
                        		}
                        	} else if(delta.value().toString().equals(alarmeTemps2.toString())){ // s'il est le moment de déclencher l'Alarme2
                        		// si actif
                    			if(alarmeTemps2Actif) {
                    				// on déclenche l'alarme2
                        			alarme(label, alarmeTemps2);
                        		}
                        	} else if(delta.value().toString().equals(alarmeTemps3.toString())){ // s'il est le moment de déclencher l'Alarme3
                        		// si actif
                    			if(alarmeTemps3Actif) {
                    				// on déclenche l'alarme3
                        			alarme(label, alarmeTemps3);
                        		}
                        	}
                    	}
                	}
                	// Appel de la création de stats
                	calculStat(elapsedTime.toString(),delta.value());
        		}
        		// si je suis en automatique et que je suis en retard et qu'il existe une autre barrière
        		if(isAutomatique){
        			// si je suis en retard
        			if(isEnRetard){
        				// si il existe une autre barrière
        				if(bhActive != bhMaxSaisie){
        					// je passe à la barrière suivante
        					bhActive = bhActive + 1;
        					Storage.setValue("bhActive", bhActive);
        				}
        			}
        		}        		
        		mValue = formatSecond(delta.value());
        		
        		//libération de la mémoire
        		elapsedTime = null;
        		bhTimeSecDecale = null;
        		delta = null;
        		
            } else {
                mValue = bhTimeDefaut;
            }
        }
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc) {
   
    	// Due to getObsurityFlags returning incorrect results here, we have to postpone the calculation to onUpdate method
        _positions = null; // Force to pre-calculate again

        return true;
    }
    
    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    
	function onUpdate(dc) {
        
        //recup de la zone d'affichage
        if (_positions == null) {
            preCalculate(dc);
        }
        //selon la zone, on applique la bonne layout
        switch (_positions) {
    	case "MainLayout":
    		setLayout(Rez.Layouts.MainLayout(dc));
    		layoutOK = true;
    		break;
    	case "MidTopLayout":
    		setLayout(Rez.Layouts.MidTopLayout(dc));
    		layoutOK = true;
    		break;
    	case "MidBottomLayout":
    		setLayout(Rez.Layouts.MidBottomLayout(dc));
    		layoutOK = true;
    		break;
    	case "CenterLayout":
    		setLayout(Rez.Layouts.CenterLayout(dc));
    		layoutOK = true;
    		break;
    	case "MidTopSmallLayout":
    		setLayout(Rez.Layouts.MidTopSmallLayout(dc));
    		layoutOK = true;
    		break;
    	case "MidBottomSmallLayout":
    		setLayout(Rez.Layouts.MidBottomSmallLayout(dc));
    		layoutOK = true;
    		break;
    	default:    		
    		setLayout(Rez.Layouts.OtherLayout(dc));
    		layoutOK = false;
    		break;
	}
        // Set the background color
        View.findDrawableById("Background").setColor(getBackgroundColor());
 		// Set the foreground color and label
        var labelC = View.findDrawableById("label");
 		// Set the foreground color and subLabel
        var subLabelC = View.findDrawableById("subLabel");
        // Set the foreground color and value
        var value = View.findDrawableById("value");
        // si le fond est noir
        if (getBackgroundColor() == Graphics.COLOR_BLACK) {
        	// on écrit en blanc
            labelC.setColor(Graphics.COLOR_WHITE);
            subLabelC.setColor(Graphics.COLOR_WHITE);
      	} else { // si le fond est blanc
        	// on écrit en noir
            labelC.setColor(Graphics.COLOR_BLACK);
            subLabelC.setColor(Graphics.COLOR_BLACK);
      	}
        // si en avance
        if (!isEnRetard) {
        	// si le fond est noir
        	if (getBackgroundColor() == Graphics.COLOR_BLACK) {
        		// on écrit en blanc
        	    value.setColor(Graphics.COLOR_WHITE);
      	 	} else { // si le fond est blanc
        		// on écrit en noir
       	     	value.setColor(Graphics.COLOR_BLACK);
      	  	}
        } else {    // si en retard
        	// on écrit en rouge
        	value.setColor(Graphics.COLOR_RED);
        }
        // si layout gérée on affiche les données
        if (layoutOK == true){
       		// label also needs to be updated regularly
       		labelC.setText(label);
       		// subLabel also needs to be updated regularly
       		subLabelC.setText(subLabel);
       		// alimentation du delta
       		value.setText(mValue);
        } else { // sinon message erreur
        	// label also needs to be updated regularly
        	labelC.setText("Too");
        	// subLabel also needs to be updated regularly
        	subLabelC.setText("Small");
        	// alimentation du delta
        	value.setText("");
        }
        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
        
    	// libère la mémoire
    	labelC = null;
        subLabelC = null;
        value = null;
    }
    
	// lance les alarmes
	function alarme(texte,temps){
				
		// affiche une alerte
		BHView.showAlert(new DataFieldAlertView(texte,formatSecond(temps.toString()), getBackgroundColor()));                   	
	}
	
	// Sauvegarde des Stat
	function calculStat(pelapsedTime,pdelta){
		
		// delta pour le graph en MMM
		var graphData = formatSecondEnMinute(pdelta).toString();
		// delta pour le LAP en HH:MM
		var lapData = formatSecondEnHM(pdelta,":").toString();		
		// si on est en retard
		if (isEnRetard) {
			// le graph doit être négatif
			graphData = "-" + graphData;
			// le temps au lap doit être positif (on a mis plus de temps qu'autorisé)
			lapData = "+" + lapData;
		} else { // en avance
			// le temps au lap doit être négatif (on a mis moins de temps qu'autorisé)
			lapData = "-" + lapData;
		}
		// Alimentation du graph
		bhTimeChartField.setData(graphData.toNumber());
		// elapsedTime pour le LAP en HH:MM
		var elapsedTimeMin = formatSecondEnHM(pelapsedTime,":").toString();
		// alimentation de donnée LAP toutes les secondes
    	var valeurLap = Properties.getValue("BH_label" + Storage.getValue("bhActive").toString()) + " " + elapsedTimeMin + " (" + lapData + ")";
    	bhTimeLapField.setData(valeurLap.toString());
    	
    	// Gestion de la Batterie
    	// valeure actuelle de la batterie
    	var batteryActuelle = Math.round(System.getSystemStats().battery).toNumber();
    	// Alimentation du graph
		bhBatteryChartField.setData(batteryActuelle.toNumber());
    	// si diminution de valeur
    	if (mbatteryAvant > batteryActuelle) {
    	    // calcul de la perte de batterie
    		var variationBattery = mbatteryAvant - batteryActuelle;
	    	// on additionne le delta à la session
		    mbatterySession += variationBattery.toNumber();
			// update session FIT Contributions
    		bhBatterySumField.setData(mbatterySession.toNumber());
    		// libère la mémoire
    		variationBattery = null;
	    }
		// on sauvegarde la valeur de la batterie pour faire le detla suivant
		mbatteryAvant = batteryActuelle;
		   	
    	// Gestion du nombre de pas
    	GestNbStep();
    	
    	// libère la mémoire
    	graphData = null;
    	lapData = null;
    	elapsedTimeMin = null;
    	valeurLap = null;
    	batteryActuelle = null;
	}
	
	// Gestion du nombre de pas 
	(:runnerVersion) 
	function GestNbStep() {
    	// si timer en cours
    	if (mTimerRunning) {
	    	// read current step count
	    	var infoActivityMonitor = ActivityMonitor.getInfo();
	    	// s'il y a des steps
	    	if (infoActivityMonitor != null && infoActivityMonitor.steps != null) {
	    		// si le nombre de pas dernier calcul est alimenté
	    		if (mStepsGlobal != null) {
	    			// si le nombre de pas de l'activité est < au dernier calcul
	    			// probably step counter has been reset (e.g., midnight)
			        if (infoActivityMonitor.steps < mStepsGlobal) {
			        	// on additionne le nombre de pas de a session avec le nouveau nombre
			        	mStepsSession += infoActivityMonitor.steps;
			        } else { // si le nombre de pas de l'activité est >= au dernier calcul
			        	// on fait la différence entre le nouveau nombre de pas et celui sauvegardé (calcul du delta)
			        	// et on additionne à celui de la session
			        	mStepsSession += infoActivityMonitor.steps - mStepsGlobal;
			        }
		        }
		        // on sauvegarde le nombre de pas de l'activité pour faire le detla suivant
		        mStepsGlobal = infoActivityMonitor.steps;
		    }
		    // update session FIT Contributions
		    bhStepSumField.setData(mStepsSession);
    		// libère la mémoire
    		infoActivityMonitor = null;
	    }
    }
    
	// Gestion du nombre de pas inexistante sur les edge
    (:edgeVersion) 
	function GestNbStep() {
		return;
	}

	// format un nombre de seconde en minute      
	function formatSecondEnMinute(time) {
		var sec = time.toLong();
		var min = sec / 60;
		return min;
    }
    
    // format un nombre de seconde en HHH<sep>MM       
	function formatSecondEnHM(time,sep) {
		var sec = time.toLong();
		var hrs = sec / 3600;
		sec -= hrs * 3600;
		var min = sec / 60;
		var valueFormat = hrs + sep + min.format("%02d");
		return valueFormat;
    }

	// format un nombre de seconde en HHH:MM       
	function formatSecond(time) {
		var sec = time.toLong();
		var hrs = sec / 3600;
		sec -= hrs * 3600;
		var min = sec / 60;
//		var valueFormat = hrs.format("%3d") + ":" + min.format("%02d");
		var valueFormat = hrs + ":" + min.format("%02d");
		return valueFormat;
    }
    
    // format un nombre de minute en HHH:MM       
	function formatMinute(time) {
		var sec = time.toLong();
		var hrs = sec / 3600;
		sec -= hrs * 3600;
		var min = sec / 60;
		var valueFormat = hrs.format("%3d") + ":" + min.format("%02d");
		return valueFormat;
    } 
    
	// format l'horaire de la barrière de HHH:MM  en nombre de minute    
	function calculTempsMinute(time) {

		var hrs = time.substring(0, time.find(":")).toLong();		
		var min = time.substring(time.find(":")+1,time.length()).toLong();
		hrs = hrs * 60;
		var valueFormat = hrs + min;
		return valueFormat;
    }
    
	// récupère le libellé, la barrière en minute et seconde
	function recupInfoBH(pBhActive) {
		        			
        bhLabel = Properties.getValue("BH_label" + pBhActive).toString(); 
        bhSubLabel = Properties.getValue("BH_subLabel" + pBhActive).toString(); 
		bhTime = calculTempsMinute(Properties.getValue("BH_Time" + pBhActive).toString());		
		bhTimeSec = bhTime*60;
    }

	// récupère des Properties
	function recupProperties() {
		bhActive = Storage.getValue("bhActive").toNumber();
        recupInfoBH(bhActive.toString()); 
        isAutomatique = Properties.getValue("isAutomatique");
        decalageVagueSec = Properties.getValue("DecalageVague").toLong()*60;
        //si le décalage de vague est supérieur à la barrière
        if(decalageVagueSec > bhTimeSec) {
        	// on alimente le décalage à zéro
        	Properties.setValue("DecalageVague", "0");
        }
        alarmeTemps1Actif = Storage.getValue("alarme1Active");    //Afficher alarme1
        alarmeTemps2Actif = Storage.getValue("alarme2Active");    //Afficher alarme2
        alarmeTemps3Actif = Storage.getValue("alarme3Active");    //Afficher alarme3
    }
  
	// contrôle des parametres    
	function controleParamBH() {

		// initialisations
		var erreur = false;
		var hrs = null;
		var min = null;
        bhMaxSaisie = 1;
		// boucle sur les barrières
		for( var i = 1; i <= bhMaxPossible; i += 1 ) {
			hrs = null;
			min = null;
			//recup du label
        	var pbhLabelSaisie = Properties.getValue("BH_label" + i).toString(); 
        	// si le libellé est alimenté
        	if (pbhLabelSaisie.length() != 0 and !erreur){ 
        		// temps saisie
				var pbhTimeSaisie = Properties.getValue("BH_Time" + i).toString();
				// si Temps est saisie
        		if (pbhTimeSaisie.length() != 0){ 
        			try {
        				// on verifie si c'est au bon format
						hrs = pbhTimeSaisie.substring(0, pbhTimeSaisie.find(":")).toLong();	
						min = pbhTimeSaisie.substring(pbhTimeSaisie.find(":")+1,pbhTimeSaisie.length()).toLong();
        			} catch (e instanceof Lang.Exception){  // erreur lors de la transfo 
        				erreur = true;
        				// on efface tout sauf le temps 1 car il en faut au moins 1 barrière
        				if (i == 1){ 
        					Properties.setValue("BH_label" + i, bhLabelDefaut);
        					Properties.setValue("BH_subLabel" + i, "");
        					Properties.setValue("BH_Time" + i, bhTimeDefaut);
        				} else {        		
        					Properties.setValue("BH_label" + i, "");
        					Properties.setValue("BH_subLabel" + i, "");
        					Properties.setValue("BH_Time" + i, "");
        				}
        			}
        			if(hrs != null and min != null){
        				// Tout est OK --> alimentation du nombre de barrière max saisie et valide
        				bhMaxSaisie = i;
        			} else  { // si temps invalide --> erreur et efface libelle et temps
        				erreur = true;
        				// on efface tout sauf le temps 1 car il en faut au moins 1 barrière
        				if (i == 1){ 
        					Properties.setValue("BH_label" + i, bhLabelDefaut);
        					Properties.setValue("BH_subLabel" + i, "");
        					Properties.setValue("BH_Time" + i, bhTimeDefaut);
        				} else {        		
        					Properties.setValue("BH_label" + i, "");
        					Properties.setValue("BH_subLabel" + i, "");
        					Properties.setValue("BH_Time" + i, "");
        				}
        			}
        		} else { // si temps vide --> erreur et efface libelle
        			erreur = true;
        			Properties.setValue("BH_label" + i, "");
        			Properties.setValue("BH_subLabel" + i, "");
        		}
    			// libère la mémoire
        		pbhTimeSaisie = null;
        	} else {
        		// présence d'erreur
        		erreur = true;
        		// on efface tout sauf le temps 1 car il en faut au moins 1 barrière
        		if (i == 1){ 
        			Properties.setValue("BH_label" + i, bhLabelDefaut);
        			Properties.setValue("BH_subLabel" + i, "");
        			Properties.setValue("BH_Time" + i, bhTimeDefaut);
        		} else {        		
        			Properties.setValue("BH_label" + i, "");
        			Properties.setValue("BH_subLabel" + i, "");
        			Properties.setValue("BH_Time" + i, "");
        		}
        	}
    		// libère la mémoire
    		pbhLabelSaisie = null;
		}
		// sauvegarde bhMaxSaisie
        Storage.setValue("bhMaxSaisie", bhMaxSaisie);
        // récup des Propertie
    	recupProperties();
    	
		// libération Mémoire
		hrs = null;
		min = null;
    } 
    
    function readKeyInt(key,thisDefault) {
		//System.println("readKeyInt |" + key +"|"+thisDefault+"|");
    	var value = thisDefault.toNumber();
    	try {
		value = Storage.getValue(key);
		} catch (e instanceof Lang.Exception){  // erreur lors de la transfo
			//System.println("aie UnexpectedTypeException |" + value +"|");
			value = thisDefault.toNumber();
			Storage.setValue(key, value);
		}
		if(value==null || !(value instanceof Number)) {
			if(value!=null) {
				//System.println("aie not NULL |" + value +"|");
				value = value.toNumber();
				Storage.setValue(key, value);
			} else {
				//System.println("aie NULL");
				value = thisDefault.toNumber();
				Storage.setValue(key, value);
			}
		}
		//System.println("value :" + value);
		return value;
	}	 
    
    function readKey(key,thisDefault) {
		//System.println("readKeyInt |" + key +"|"+thisDefault+"|");
    	var value = thisDefault;
	    try {
			value = Storage.getValue(key);
		} catch (e instanceof Lang.Exception){  // erreur lors de la transfo
			//System.println("aie UnexpectedTypeException |" + value +"|");
			value = thisDefault;
			Storage.setValue(key, value);
		}
		if(value==null) {		
			//System.println("aie NULL");
			value = thisDefault;
			Storage.setValue(key, value);
		}
		//System.println("value :" + value);
		return value;
	}
	
	//recup de la layout où se trouve le datafield
    private function preCalculate(dc) {
    	//recup des dimensions de l'ecran
        var width = dc.getWidth();
        var height = dc.getHeight();
    	//recup des flags
        var flags = getObscurityFlags();
    	//recup des layouts
        var layouts = WatchUi.loadResource(Rez.JsonData.Layouts);
    	//nb de layouts
        var totalLayouts = layouts.size() / 3;
    	//boucle sur les layouts pour trouver la bonne
        for (var i = 0; i < totalLayouts; i++) {
            var index = i * 3;
            var layoutWidth = layouts[index];
            var layoutHeight = layouts[index + 1];
            var layoutFlags = layouts[index + 2];
            //si on est sur la bonne layout
            if ((layoutWidth - width).abs() <= 2 && (layoutHeight - height).abs() <= 2 && layoutFlags == flags) {
            	//recup de son nom
                _positions = WatchUi.loadResource(Rez.JsonData[layoutResources[i]]);
                // liberation mémoire
                width = null;
                height = null;
                flags = null;
                layouts = null;
                totalLayouts = null;
                index = null;
                layoutWidth = null;
                layoutHeight = null;
                layoutFlags = null;
                //retour
                return;
            } else { //si mauvaise layout on initialise à "autre"
            _positions = "OtherLayout";
            }
        }
    }
    
}
