using Toybox.WatchUi;
using Toybox.Application.Properties;
using Toybox.Application.Storage;

class BHMenu extends WatchUi.Menu2 {
    function initialize() {
    	// création du menu principal
        Menu2.initialize(null);
        // ajout du titre
        Menu2.setTitle(Rez.Strings.MenuLabel);
        // gestion menu suivante
        var bhActive = Storage.getValue("bhActive");
        var bhMaxSaisie = Storage.getValue("bhMaxSaisie");
        var ssTitre = "";
        //sous titre différent si on est sur la dernière barrière
        if(bhActive != bhMaxSaisie){
        	ssTitre = WatchUi.loadResource(Rez.Strings.MenuSousLabelBarriereSuivante);
        } else {
        	ssTitre = WatchUi.loadResource(Rez.Strings.MenuSousLabelLastBarriere);
        }
        // ajout du sous menu BH Suivante
        Menu2.addItem(new WatchUi.MenuItem(Properties.getValue("BH_label" + Storage.getValue("bhActive").toString()), 
        ssTitre.toString(), 
        "suivante", 
        null));
        // ajout du sous menu barrière
        Menu2.addItem(new WatchUi.MenuItem(Rez.Strings.MenuLabelBarrieres, 
        Rez.Strings.MenuSousLabelBarrieres, 
        "barrieres", 
        null));
        // ajout du sous menu décalage
        Menu2.addItem(new WatchUi.MenuItem(Rez.Strings.MenuLabelDecalage, 
		formatMinute(Properties.getValue("DecalageVague").toNumber()), 
        "decalage", null));
        // ajout de l'item automatique
        Menu2.addItem(new WatchUi.ToggleMenuItem(Rez.Strings.MenuLabelParametresPassageAuto, 
           	{:enabled=>Rez.Strings.MenuLabelParametresPassageAutoON, 
           	:disabled=>Rez.Strings.MenuLabelParametresPassageAutoOFF}, 
           	"auto", 
           	Properties.getValue("isAutomatique"), 
           	{:alignment=>WatchUi.MenuItem.MENU_ITEM_LABEL_ALIGN_LEFT}));
        // ajout du sous menu Alarmes
        Menu2.addItem(new WatchUi.MenuItem(Rez.Strings.MenuLabelAlarme, 
        null, 
        "alarmes", 
        null));
    }    
    
	// format un nombre de minute en HH:MM   
	function formatMinute(time) {
        var min = time.toLong();
		var hrs = min / 60;
		min -= hrs * 60;
		var valueFormat = hrs + ":" + min.format("%02d");
		return valueFormat;
    }
    
    // format l'horaire de HHH:MM  en nombre de minute    
	function calculTempsMinute(time) {

		var hrs = time.substring(0, time.find(":")).toLong();		
		var min = time.substring(time.find(":")+1,time.length()).toLong();
		hrs = hrs * 60;
		var valueFormat = hrs + min;
		return valueFormat;
    }
}