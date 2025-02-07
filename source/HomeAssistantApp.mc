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
// Application root for GarminHomeAssistant
//
//-----------------------------------------------------------------------------------

using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Application.Properties;
using Toybox.Timer;

class HomeAssistantApp extends Application.AppBase {
    hidden var mHaMenu;
    hidden var strNoApiKey    as Lang.String;
    hidden var strNoApiUrl    as Lang.String;
    hidden var strNoConfigUrl as Lang.String;
    hidden var strNoInternet  as Lang.String;
    hidden var strNoMenu      as Lang.String;
    hidden var strApiFlood    as Lang.String;
    hidden var mTimer         as Timer.Timer;
    hidden var mItemsToUpdate;        // Array initialised by onReturnFetchMenuConfig()
    hidden var mNextItemToUpdate = 0; // Index into the above array

    function initialize() {
        AppBase.initialize();
        strNoApiKey    = WatchUi.loadResource($.Rez.Strings.NoAPIKey);
        strNoApiUrl    = WatchUi.loadResource($.Rez.Strings.NoApiUrl);
        strNoConfigUrl = WatchUi.loadResource($.Rez.Strings.NoConfigUrl);
        strNoInternet  = WatchUi.loadResource($.Rez.Strings.NoInternet);
        strNoMenu      = WatchUi.loadResource($.Rez.Strings.NoMenu);
        strApiFlood    = WatchUi.loadResource($.Rez.Strings.ApiFlood);
        mTimer          = new Timer.Timer();
    }

    // onStart() is called on application start up
    function onStart(state as Lang.Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Lang.Dictionary?) as Void {
        if (mTimer != null) {
            mTimer.stop();
        }
    }

    // Return the initial view of your application here
    function getInitialView() as Lang.Array<WatchUi.Views or WatchUi.InputDelegates>? {
        if ((Properties.getValue("api_key") as Lang.String).length() == 0) {
            if (Globals.scDebug) {
                System.println("HomeAssistantMenuItem Note - execScript(): No API key in the application settings.");
            }
            return [new ErrorView(strNoApiKey + "."), new ErrorDelegate()] as Lang.Array<WatchUi.Views or WatchUi.InputDelegates>;
        } else if ((Properties.getValue("api_url") as Lang.String).length() == 0) {
            if (Globals.scDebug) {
                System.println("HomeAssistantMenuItem Note - execScript(): No API URL in the application settings.");
            }
            return [new ErrorView(strNoApiUrl + "."), new ErrorDelegate()] as Lang.Array<WatchUi.Views or WatchUi.InputDelegates>;
        } else if ((Properties.getValue("config_url") as Lang.String).length() == 0) {
            if (Globals.scDebug) {
                System.println("HomeAssistantMenuItem Note - execScript(): No configuration URL in the application settings.");
            }
            return [new ErrorView(strNoConfigUrl + "."), new ErrorDelegate()] as Lang.Array<WatchUi.Views or WatchUi.InputDelegates>;
        } else if (System.getDeviceSettings().phoneConnected && System.getDeviceSettings().connectionAvailable) {
            fetchMenuConfig();
            return [new WatchUi.View(), new WatchUi.BehaviorDelegate()] as Lang.Array<WatchUi.Views or WatchUi.InputDelegates>;
        } else {
            if (Globals.scDebug) {
                System.println("HomeAssistantApp Note - fetchMenuConfig(): No Internet connection, skipping API call.");
            }
            return [new ErrorView(strNoInternet + "."), new ErrorDelegate()] as Lang.Array<WatchUi.Views or WatchUi.InputDelegates>;
        }
    }

    // Callback function after completing the GET request to fetch the configuration menu.
    //
    function onReturnFetchMenuConfig(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        if (Globals.scDebug) {
            System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Code: " + responseCode);
            System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Data: " + data);
        }
        if (responseCode == Communications.BLE_QUEUE_FULL) {
            if (Globals.scDebug) {
                System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Code: BLE_QUEUE_FULL, API calls too rapid.");
            }
            var cw = WatchUi.getCurrentView();
            if (!(cw[0] instanceof ErrorView)) {
                // Avoid pushing multiple ErrorViews
                WatchUi.pushView(new ErrorView(strApiFlood), new ErrorDelegate(), WatchUi.SLIDE_UP);
            }
        } else if (responseCode == 200) {
            mHaMenu = new HomeAssistantView(data, null);
            WatchUi.switchToView(mHaMenu, new HomeAssistantViewDelegate(), WatchUi.SLIDE_IMMEDIATE);
            mItemsToUpdate = mHaMenu.getItemsToUpdate();
            mTimer.start(
                method(:updateNextMenuItem),
                Globals.scMenuItemUpdateInterval,
                true
            );
        } else if (responseCode == -300) {
            if (Globals.scDebug) {
                System.println("HomeAssistantApp Note - onReturnFetchMenuConfig(): Network request timeout.");
            }
            WatchUi.pushView(new ErrorView(strNoMenu + ". " + strNoInternet + "?"), new ErrorDelegate(), WatchUi.SLIDE_UP);
        } else {
            if (Globals.scDebug) {
                System.println("HomeAssistantApp Note - onReturnFetchMenuConfig(): Configuration not found or potential validation issue.");
            }
            WatchUi.pushView(new ErrorView(strNoMenu + " code=" + responseCode ), new ErrorDelegate(), WatchUi.SLIDE_UP);
        }
    }

    function fetchMenuConfig() as Void {
        var options = {
            :method  => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Communications.makeWebRequest(
            Properties.getValue("config_url"),
            null,
            options,
            method(:onReturnFetchMenuConfig)
        );
    }

    // We need to spread out the API calls so as not to overload the results queue and cause Communications.BLE_QUEUE_FULL (-101) error.
    // This function is called by a timer every Globals.menuItemUpdateInterval ms.
    function updateNextMenuItem() as Void {
        var itu = mItemsToUpdate as Lang.Array<HomeAssistantToggleMenuItem>;
        itu[mNextItemToUpdate].getState();
        mNextItemToUpdate = (mNextItemToUpdate + 1) % itu.size();
    }

}

function getApp() as HomeAssistantApp {
    return Application.getApp() as HomeAssistantApp;
}
