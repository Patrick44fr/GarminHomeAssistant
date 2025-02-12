# GarminHomeAssistant

<img src="images/Actual_Venu2_Theme.jpg" width="200" title="Venu 2"/>

A Garmin application to provide a "dashboard" to control your devices via [Home Assistant](https://www.home-assistant.io/). The application will never be as fully fledged as a Home Assistant dashboard, so it is designed to be good enough for the simple and essential things. Those things that can be activated via an on/off toggle or a tap. That should cover lights, switches, and anything requiring a single press such as an automation. For anything more complicated, e.g. thermostat, it would always be quicker and simpler to reach for your phone or tablet... or the device's own remote control!

The application is designed around a simple scrollable menu where menu items have been extended to interface with the [Home Assistant API](https://developers.home-assistant.io/docs/api/rest/), e.g. to get the status of switches or lights for display on the toggle menu item. It is possible to nest menus, so there is a menu item to open a sub-menu. This can be 
arbitrarily deep and nested in the format of a tree of items, although you need to consider if reaching for your phone becomes quicker to select the device what you want to control.

It is important to note that your homeassistant instance will need to be accessible via HTTPS with public SSL or all requests from the Garmin will not work. This cannot be a self-signed certificate, it must be a public certificate (You can get one for free from Let's Encrypt or you can pay for homeassistant cloud).

## Application Installation

Head over to the [GarminHomeAssistant](https://apps.garmin.com/en-US/apps/61c91d28-ec5e-438d-9f83-39e9f45b199d) application page on the [Connect IQ application store](https://apps.garmin.com/en-US/) to download the application.

## Dashboard Definition

Setup for this menu is more complicated than the Connect IQ settings menu really allows you to specify. In order to make the dashboard easily configurable and easy to change, we have provided an external mechanism for specifying the menu layout, a JSON file you write, retrieved from a URL you specify. JSON was chosen over YAML because Garmin can parse JSON HTTP GET responses into its own internal dictionary, it cannot parse YAML, hence a choice of one really. We recommend you take advantage of [Home Assistant's own web server](https://www.home-assistant.io/integrations/http/#hosting-files) to provide the JSON definition. The advantage here are:

1. the file is as public as you make your Home Assistant,
2. the file is editable within Home Assistant via "Studio Code Server", and
3. the schema is verifiable using [JSON Schema](https://json-schema.org/overview/what-is-jsonschema).

We have used `/config/www/garmin/<something>.json` on our Home Assistant's file system. That equates to a URL of `https://homeassistant.local/local/garmin/<something>.json`.

Schema verification is a big part of this design choice. If the application cannot read your menu definition, there's a limited amount of debug it can reasonable provide on a small screen. That responsibility now falls to you and the schema checker for help.

Example schema as shown in the images:

```json
{
  "$schema": "https://raw.githubusercontent.com/house-of-abbey/GarminHomeAssistant/main/config.schema.json",
  "title": "Home",
  "items": [
    {
      "entity": "script.food_on_table",
      "name": "Food is Ready!",
      "type": "tap"
    },
    {
      "entity": "light.bedside_light_switch",
      "name": "Bedroom Light",
      "type": "toggle"
    },
    {
      "entity": "light.living_room_lights_all",
      "name": "Lounge Lights",
      "type": "toggle"
    },
    {
      "entity": "menu.each_lounge_light",
      "name": "Each Lounge Light",
      "title": "Lounge",
      "type": "group",
      "items": [
        {
          "entity": "light.standard_lamp",
          "name": "Standard Lamp",
          "type": "toggle"
        },
        {
          "entity": "light.bookcase_light",
          "name": "Bookcase Lamp",
          "type": "toggle"
        },
        {
          "entity": "light.corner_table_light",
          "name": "Corner Table Lamp",
          "type": "toggle"
        }
      ]
    },
    {
      "entity": "switch.bc_usbs",
      "name": "Bookcase USBs",
      "type": "toggle"
    },
    {
      "entity": "switch.crnr_tbl_usbs",
      "name": "Corner Table USBs",
      "type": "toggle"
    }
  ]
}
```

NB. Entity names are not real in case anyone's a hacker.

The [schema](https://raw.githubusercontent.com/house-of-abbey/GarminHomeAssistant/main/config.schema.json) is checked by using a URL directly back to this GitHub source repository, so you do not need to install that file. You can just copy & paste your entity names from the YAML configuration files used to configure Home Assistant. With a submenu, there's a difference between "title" and "name". The "name" goes on the menu item, and the "title" at the head of the submenu. If your dashboard definition fails to meet the schema, the application will simply drop items with the wrong field names without warning.

## API Key Creation

Having created your JSON definition for your dashboard, you need to create an API key for your personal account on Home Assistant.

![Long-Lived Access Token](images/Long_Lived_Access_Tokens.png)

Having created that token, before you dismiss the dialogue box with the value you will never see again, copy it somewhere safe. You need to paste this into the Garmin Application's settings.

## Settings

<img src="images/GarminHomeAssistantSettings.png" width="400" title="Application Settings"/>

1. Paste your API key you've just created into the top field.
2. Add the URL for your Home Assistant API, e.g. `https://<homeassistant>/api/`.
3. Add the URL of your JSON file, e.g. `https://<homeassistant>/local/garmin/<something>.json`.

You should now have a working application on your watch and be able to operate your Home Assistant devices for as long as your watch is within Bluetooth range of your phone.

## Tap Item Response

Its obvious that a toggle menu item has been triggered as the visible switch changes position and colour. Less obvious is that you have successfully triggered a tap operation.

<img src="images/SimTapResponse.png" width="400" title="Tap Triggered"/>

The application will display a 'toast' showing Home Assistant's friendly name of the triggered item. The toast will disappear after a short while if not dismissed by the user.

## External Device Changes

Home Assistant will inevitably change the state of devices you are also controlling via your Garmin. The Garmin application does not maintain a web socket to listen for changes. Instead it must poll the Home Assistant API with your key. Therefore the application is not responsive to changes, instead there will be a delay of about 5 seconds to pick up state changes. The thinking here is that the watch application will only ever be open briefly not persistently, so the delay in picking up state changes won't be observed often for any race condition between two controllers.

## Changes to the (JSON) Dashboard Definition

When you change the JSON file defining your dashboard, you must exit the application and the reopen it. It only takes a matter of a few seconds to pick up the new definition, but it is not automatic.
