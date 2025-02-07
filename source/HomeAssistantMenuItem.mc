//-----------------------------------------------------------------------------------
//
// Distributed under MIT Licence
//   See https://github.com/house-of-abbey/GarminHomeAssistant/blob/main/LICENSE.
//
//-----------------------------------------------------------------------------------
//
// GarminHomeAssistant is a Garmin IQ application written in Monkey C and routinely
// tested on a Venu 2 device. The source code is provided at:
//            https://github.com/house-of-abbey/GarminHomeAssistant.
//
// P A Abbey & J D Abbey, 31 October 2023
//
//
// Description:
//
// Menu button that triggers a service.
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application.Properties;

class HomeAssistantMenuItem extends WatchUi.MenuItem {
    hidden var mApiKey = Properties.getValue("api_key");
    hidden var strNoInternet as Lang.String;
    hidden var strApiFlood   as Lang.String;
    hidden var mService      as Lang.String;

    function initialize(
        label as Lang.String or Lang.Symbol,
        subLabel as Lang.String or Lang.Symbol or Null,
        identifier as Lang.Object or Null,
        service as Lang.String or Null,
        options as {
            :alignment as WatchUi.MenuItem.Alignment,
            :icon      as Graphics.BitmapType or WatchUi.Drawable or Lang.Symbol
        } or Null
    ) {
        strNoInternet = WatchUi.loadResource($.Rez.Strings.NoInternet);
        strApiFlood   = WatchUi.loadResource($.Rez.Strings.ApiFlood);
        mService = service;
        WatchUi.MenuItem.initialize(
            label,
            subLabel,
            identifier,
            options
        );
    }

    // Callback function after completing the POST request to call a script.
    //
    function onReturnExecScript(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        if (Globals.scDebug) {
            System.println("HomeAssistantMenuItem onReturnExecScript() Response Code: " + responseCode);
            System.println("HomeAssistantMenuItem onReturnExecScript() Response Data: " + data);
        }
        if (responseCode == Communications.BLE_QUEUE_FULL) {
            if (Globals.scDebug) {
                System.println("HomeAssistantMenuItem onReturnExecScript() Response Code: BLE_QUEUE_FULL, API calls too rapid.");
            }
            var cw = WatchUi.getCurrentView();
            if (!(cw[0] instanceof ErrorView)) {
                // Avoid pushing multiple ErrorViews
                WatchUi.pushView(new ErrorView(strApiFlood), new ErrorDelegate(), WatchUi.SLIDE_UP);
            }
        } else if (responseCode == 200) {
            var d = data as Lang.Array;
            for(var i = 0; i < d.size(); i++) {
                if ((d[i].get("entity_id") as Lang.String).equals(mIdentifier)) {
                    if (Globals.scDebug) {
                        System.println("HomeAssistantMenuItem Note - onReturnExecScript(): Correct script executed.");
                    }
                    if (WatchUi has :showToast) {
                        WatchUi.showToast(
                            (d[i].get("attributes") as Lang.Dictionary).get("friendly_name") as Lang.String,
                            null
                        );
                    }
                    if (Attention has :vibrate) {
                        Attention.vibrate([
                            new Attention.VibeProfile(50, 100), // On  for 100ms
                            new Attention.VibeProfile( 0, 100), // Off for 100ms
                            new Attention.VibeProfile(50, 100)  // On  for 100ms
                        ]);
                    }
                    if (!(WatchUi has :showToast) && !(Attention has :vibrate)) {
                        new Alert({
                            :timeout => Globals.scAlertTimeout,
                            :font    => Graphics.FONT_MEDIUM,
                            :text    => (d[i].get("attributes") as Lang.Dictionary).get("friendly_name") as Lang.String,
                            :fgcolor => Graphics.COLOR_WHITE,
                            :bgcolor => Graphics.COLOR_BLACK
                        }).pushView(WatchUi.SLIDE_IMMEDIATE);
                    }
                }
            }
        }
    }

    function execScript() as Void {
        var options = {
            :method  => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => {
                "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON,
                "Authorization" => "Bearer " + mApiKey
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        if (System.getDeviceSettings().phoneConnected && System.getDeviceSettings().connectionAvailable) {
            // Updated SDK and got a new error
            // ERROR: venu: Cannot find symbol ':substring' on type 'PolyType<Null or $.Toybox.Lang.Object>'.
            var id = mIdentifier as Lang.String;
            if (mService == null) {
                var url = (Properties.getValue("api_url") as Lang.String) + "/services/" + id.substring(0, id.find(".")) + "/" + id.substring(id.find(".")+1, id.length());
                if (Globals.scDebug) {
                    System.println("HomeAssistantMenuItem execScript() URL=" + url);
                    System.println("HomeAssistantMenuItem execScript() mIdentifier=" + mIdentifier);
                }
                Communications.makeWebRequest(
                    url,
                    null,
                    options,
                    method(:onReturnExecScript)
                );
            } else {
                var url = (Properties.getValue("api_url") as Lang.String) + "/services/" + mService.substring(0, mService.find(".")) + "/" + mService.substring(mService.find(".")+1, null);
                if (Globals.scDebug) {
                    System.println("HomeAssistantMenuItem execScript() URL=" + url);
                    System.println("HomeAssistantMenuItem execScript() mIdentifier=" + mIdentifier);
                }
                Communications.makeWebRequest(
                    url,
                    {
                        "entity_id" => id
                    },
                    options,
                    method(:onReturnExecScript)
                );
            }
        } else {
            if (Globals.scDebug) {
                System.println("HomeAssistantMenuItem Note - execScript(): No Internet connection, skipping API call.");
            }
            WatchUi.pushView(new ErrorView(strNoInternet + "."), new ErrorDelegate(), WatchUi.SLIDE_UP);
        }
    }

}
