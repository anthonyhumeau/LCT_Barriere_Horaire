using Toybox.Application;
using Toybox.Graphics;
using Toybox.System;
using Toybox.WatchUi;
using Toybox.Application.Properties;

const HEURE_FORMAT = "%d";
const MINUTE_FORMAT = "%02d";
var item; // menu

class TimePicker extends WatchUi.Picker {

    function initialize() {

        var title = new WatchUi.Text({:text=>Rez.Strings.MenuLabelDecalage, 
        	:locX=>WatchUi.LAYOUT_HALIGN_CENTER, 
        	:locY=>WatchUi.LAYOUT_VALIGN_BOTTOM});
        var factories;

            factories = new [3];
            factories[0] = new NumberFactory(0, 23, 1, {:format=>HEURE_FORMAT, :font=>Graphics.FONT_NUMBER_MEDIUM});

        factories[1] = new WatchUi.Text({:text=>":", 
        	:font=>Graphics.FONT_MEDIUM, 
        	:locX =>WatchUi.LAYOUT_HALIGN_CENTER, 
        	:locY=>WatchUi.LAYOUT_VALIGN_CENTER});
        factories[2] = new NumberFactory(0, 59, 1, {:format=>MINUTE_FORMAT, :font=>Graphics.FONT_NUMBER_MEDIUM});

       	var defaults = splitStoredTime(factories.size());
            defaults[0] = factories[0].getIndex(defaults[0].toNumber());
            defaults[2] = factories[2].getIndex(defaults[2].toNumber());
        Picker.initialize({:title=>title, :pattern=>factories, :defaults=>defaults});
        
        //liberation mémoire
        title = null;
        factories = null;
        defaults = null;
    }

    function onUpdate(dc) {
        dc.clear();
        Picker.onUpdate(dc);
    }

    function splitStoredTime(arraySize) {
        var storedValue = BHMenu.formatMinute(Properties.getValue("DecalageVague").toNumber());
        var defaults = null;
        var separatorIndex = 0;
        var spaceIndex;

        if(storedValue != null) {
            defaults = new [arraySize];
            // the Drawable does not have a default value
            defaults[1] = null;

            // HH:MIN
            separatorIndex = storedValue.find(":");
            if(separatorIndex != null ) {
                defaults[0] = storedValue.substring(0, separatorIndex);
            }
            else {
                defaults = null;
            }
        }

        if(defaults != null) {
                defaults[2] = storedValue.substring(separatorIndex + 1, storedValue.length());
        }

        //liberation mémoire
        storedValue = null;
        separatorIndex = null;
        spaceIndex = null;
        return defaults;
    }
}

class TimePickerDelegate extends WatchUi.PickerDelegate {

    function initialize(pitem) {
        PickerDelegate.initialize();
        // récup du menu d'appel
		item = pitem;
    }

    function onCancel() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    function onAccept(values) {
        var time = values[0] + ":" + values[2].format(MINUTE_FORMAT);
        var timeMinute = BHMenu.calculTempsMinute(time);
        Properties.setValue("DecalageVague", timeMinute);
		// mise à jour du sous titre
		item.setSubLabel(time);

        //liberation mémoire
        time = null;
        timeMinute = null;
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

}
