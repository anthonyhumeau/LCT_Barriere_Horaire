using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application.Properties;
using Toybox.Application.Storage;

class BHMenuDelegate extends WatchUi.Menu2InputDelegate {
	
	var menu2;
	
    function initialize(menu) {
    
        Menu2InputDelegate.initialize();
        menu2 = menu;
    }
	
	// si Menu principal séléectionné
  	function onSelect(item) {
  		
  		// récupération de l'ID du menu principal
  		var id=item.getId();
  		
  		// si sur barrière suivante
        if( id.equals("suivante") ) {
			var bhActive = Storage.getValue("bhActive");
            var bhMaxSaisie = Storage.getValue("bhMaxSaisie");
        	var ssTitre = menu2.getItem(menu2.findItemById("suivante")).getSubLabel().toString();
        	// si l'on ne vient pas déjà de valider une barrière
        	if (!ssTitre.equals(WatchUi.loadResource(Rez.Strings.MenuSousLabelGoBarriere).toString())) {
            	// si il existe une autre barrière
        		if(bhActive != bhMaxSaisie) {
        			// je passe à la barrière suivante
        			bhActive = bhActive + 1;
        			Storage.setValue("bhActive", bhActive);
           			// MAJ Label menu "suivante"
           			menu2.getItem(menu2.findItemById("suivante")).setLabel(Properties.getValue("BH_label" + bhActive).toString());
           			// MAJ SousLabel menu "suivante" avec "GO !!!!"
           			ssTitre = WatchUi.loadResource(Rez.Strings.MenuSousLabelGoBarriere);
        		} else { // si sur la dernière barrière        		
           			// MAJ SousLabel menu "suivante" avec "Dernière Barrière"
           			ssTitre = WatchUi.loadResource(Rez.Strings.MenuSousLabelLastBarriere);
           		}
           		// MAJ SousLabel menu "suivante"
           		menu2.getItem(menu2.findItemById("suivante")).setSubLabel(ssTitre);
           	}
           	// Focus sur suivante
           	menu2.setFocus(menu2.findItemById("suivante"));
        } else if(id.equals("barrieres") ) { // si sur les barrières horaires
        	//creation du menu
  		  	var CheckboxMenuBH = new WatchUi.CheckboxMenu({:title=>Rez.Strings.SousMenuLabelBarrieres});
  		  	// variable pour voir si sélectionné
  		  	var actif = false;
			// récup du nombre de barrières saisies
			var bhMaxSaisie = Storage.getValue("bhMaxSaisie").toNumber();
			// boucle sur les barrières saisies
			for( var i = 1; i <= bhMaxSaisie; i += 1 ) {
  		  		// BH1 est selectionnée vrai ou faux
  		  		if(Storage.getValue("bhActive").toNumber() == i){
  		  			actif = true;
  		  		} else {
  		  			actif = false;
  		  		}
  		  		//création de l'item BH
  		  		var ident = "BH" + i;
  		  		CheckboxMenuBH.addItem(new WatchUi.CheckboxMenuItem(Properties.getValue("BH_label" + i).toString(), 
  		  		Properties.getValue("BH_Time" + i).toString(), 
  		  		ident, 
  		  		actif, 
  		  		{:alignment=>WatchUi.MenuItem.MENU_ITEM_LABEL_ALIGN_LEFT}));
  		  	}
           	//ajout du focus sur le sélectionné
           	CheckboxMenuBH.setFocus(Storage.getValue("bhActive").toNumber()-1);
           	//affichage du sous menu
            WatchUi.pushView(CheckboxMenuBH, new Menu2SubMenuDelegate(menu2), WatchUi.SLIDE_LEFT);
        } else if( id.equals("decalage") ){
           	WatchUi.pushView(new TimePicker(), new TimePickerDelegate(item), WatchUi.SLIDE_LEFT);
        } else if( id.equals("alarmes") ){        
        	//creation du menu
  		  	var ToggleAlarmeMenuBH = new WatchUi.Menu2({:title=>Rez.Strings.MenuLabelAlarme});
  		  	ToggleAlarmeMenuBH.addItem(new WatchUi.ToggleMenuItem(formatSecond(Storage.getValue("alarme1").toString()), 
           	{:enabled=>Rez.Strings.MenuLabelAlarmeON, 
           	:disabled=>Rez.Strings.MenuLabelAlarmeOFF}, 
           	"alarme1", 
           	Storage.getValue("alarme1Active"), 
           	{:alignment=>WatchUi.MenuItem.MENU_ITEM_LABEL_ALIGN_LEFT}));
  		  	ToggleAlarmeMenuBH.addItem(new WatchUi.ToggleMenuItem(formatSecond(Storage.getValue("alarme2").toString()),
           	{:enabled=>Rez.Strings.MenuLabelAlarmeON, 
           	:disabled=>Rez.Strings.MenuLabelAlarmeOFF}, 
           	"alarme2", 
           	Storage.getValue("alarme2Active"), 
           	{:alignment=>WatchUi.MenuItem.MENU_ITEM_LABEL_ALIGN_LEFT}));
  		  	ToggleAlarmeMenuBH.addItem(new WatchUi.ToggleMenuItem(formatSecond(Storage.getValue("alarme3").toString()),
           	{:enabled=>Rez.Strings.MenuLabelAlarmeON, 
           	:disabled=>Rez.Strings.MenuLabelAlarmeOFF}, 
           	"alarme3", 
           	Storage.getValue("alarme3Active"), 
           	{:alignment=>WatchUi.MenuItem.MENU_ITEM_LABEL_ALIGN_LEFT}));
           	//affichage du sous menu
            WatchUi.pushView(ToggleAlarmeMenuBH, new Menu2SubMenuDelegate(menu2), WatchUi.SLIDE_LEFT);
        }
    	
    	//si type Toggle
     	if(item instanceof ToggleMenuItem) {
     		//si c'est l'automatique
     		if(id.toString().equals("auto")) {
  				//sauvegarde de la nouvelle valeur de automatique
            	Properties.setValue("isAutomatique", item.isEnabled());
        	}
        }
        	
        //refresh
        WatchUi.requestUpdate();
  	}
  	
  	function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
		return false;
    }  

    function onWrap(key) {
        return false;
    }

	// format un nombre de seconde en HHH:MM       
	function formatSecond(time) {
		var sec = time.toLong();
		var hrs = sec / 3600;
		sec -= hrs * 3600;
		var min = sec / 60;
		var valueFormat = hrs.format("%3d") + ":" + min.format("%02d");
		return valueFormat;
    }
}
//This is the menu input delegate shared by all the basic sub-menus in the application
class Menu2SubMenuDelegate extends WatchUi.Menu2InputDelegate {
	
	var menu2;
	
    function initialize(menu) {
        Menu2InputDelegate.initialize();
        menu2 = menu;
    }
	//si sous menu sélectionné
    function onSelect(item) {
  		// récupération de l'ID du menu principal
  		var id=item.getId();
    	//si de type BH
     	if(id.toString().substring(0,2).equals("BH")) {
     		//si existe
  			if(item != null) {
  				// récup barrière sélectionnée
  				var bhActive = id.toString().substring(2,4).toNumber();
  				//sauvegarde de la nouvelle BH active
           		Storage.setValue("bhActive", bhActive);
           		// MAJ Label menu "suivante"
           		menu2.getItem(menu2.findItemById("suivante")).setLabel(Properties.getValue("BH_label" + bhActive).toString());
           		// MAJ SousLabel menu "suivante"
           		menu2.getItem(menu2.findItemById("suivante")).setSubLabel(WatchUi.loadResource(Rez.Strings.MenuSousLabelGoBarriere));
           		// Focus sur suivante
           		menu2.setFocus(menu2.findItemById("suivante"));
           		//simul un retour utilisateur
           		onBack();
        	}
        }
        //si de type Alarme1
     	if(id.toString().equals("alarme1")) {
     		//si existe
  			if(item != null) {
  				//sauvegarde de la nouvelle valeur
           		Storage.setValue("alarme1Active", item.isEnabled());
        	}
        }
        //si de type Alarme2
     	if(id.toString().equals("alarme2")) {
     		//si existe
  			if(item != null) {
  				//sauvegarde de la nouvelle valeur
           		Storage.setValue("alarme2Active", item.isEnabled());
        	}
        }
        //si de type Alarme3
     	if(id.toString().equals("alarme3")) {
     		//si existe
  			if(item != null) {
  				//sauvegarde de la nouvelle valeur
           		Storage.setValue("alarme3Active", item.isEnabled());
        	}
        }
        	
        //refresh
        WatchUi.requestUpdate();
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    function onDone() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    function onWrap(key) {
        return false;
    }
}