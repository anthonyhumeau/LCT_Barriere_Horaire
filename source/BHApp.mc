using Toybox.Application;
using Toybox.WatchUi;

class BHApp extends Application.AppBase {

	var view;
	var menu;
	
    function initialize() {
        AppBase.initialize();
        
    		view = new BHView();
    }

    // onStart() is called on application start up
    function onStart(state) {
    	view.onStart();
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    	view.onStop();
    }

    //! Return the initial view of your application here
    function getInitialView() {
    	if (null == view) {
    		view = new BHView();
    	}
        return [ view ];
    }
    
    //! Return the initial view of your application here
    // création du menu et de la gestion des actions sur le menu
    function getSettingsView() {
    	menu = new BHMenu();
        return [ menu, new BHMenuDelegate(menu)  ];
    }  
    
    // si changement des Settings
    function onSettingsChanged() {
    	if (null != view) {
    		// on se repositionne sur la barrière 1
			Storage.setValue("bhActive", 1);
			// on contrôle les nouveaux paramètres
			view.controleParamBH();
		}
	}
}