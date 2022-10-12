using Toybox.WatchUi;
using Toybox.Application;
using Toybox.Attention;

class DataFieldAlertView extends WatchUi.DataFieldAlert{

	var alerteNom = "";
	var alerteTemps = "00:00";
	var couleurFond;
	
    function initialize(nom,temps,backgroundColor) {
        DataFieldAlert.initialize();
    	alerteNom = nom;
    	alerteTemps = temps;
    	couleurFond = backgroundColor;
    }
    
    function onShow() {

    	// si on peut jouer un son
		if (Attention has :playTone) {
			// joue le son
			Attention.playTone(Attention.TONE_TIME_ALERT);
		}

		// si on peut lancer une vibration
		if (Attention has :vibrate) {
			// vibration à 100% et 2 secondes
			var vibrateData = [new Attention.VibeProfile(100, 2000)];
			//lance la vibration
			Attention.vibrate(vibrateData);
		}
    }
    
    function onUpdate(dc){
        
    	var couleurFondAlerte;
    	var couleurTexteAlerte;
    	if (couleurFond == Graphics.COLOR_WHITE){
    		couleurFondAlerte = Graphics.COLOR_BLACK;
    		couleurTexteAlerte = Graphics.COLOR_WHITE;
    	} else {
    		couleurFondAlerte = Graphics.COLOR_WHITE;
    		couleurTexteAlerte = Graphics.COLOR_BLACK;
    	}
        dc.setColor(couleurFondAlerte, couleurFondAlerte);
        dc.clear();
        dc.setColor(couleurTexteAlerte, Graphics.COLOR_TRANSPARENT);
        var BarrieresAlerte = new WatchUi.Text({
            :text=>alerteNom,
            :color=>couleurTexteAlerte,
            :font=>Graphics.FONT_LARGE,
            :locX =>WatchUi.LAYOUT_HALIGN_CENTER,
            :locY=>0.25*dc.getHeight()
        });
        BarrieresAlerte.draw(dc);
        var Barrieres2Alerte = new WatchUi.Text({
            :text=>Rez.Strings.Barrieres2Alerte,
            :color=>couleurTexteAlerte,
            :font=>Graphics.FONT_LARGE,
            :locX =>WatchUi.LAYOUT_HALIGN_CENTER,
            :locY=>0.4*dc.getHeight()
        });
        Barrieres2Alerte.draw(dc);
        var alerteTempsText = new WatchUi.Text({
            :text=>alerteTemps,
            :color=>Graphics.COLOR_RED,
            :font=>Graphics.FONT_NUMBER_HOT,
            :locX =>WatchUi.LAYOUT_HALIGN_CENTER,
            :locY=>0.5*dc.getHeight()
        });
        alerteTempsText.draw(dc);

    }
}
