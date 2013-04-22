# Dataplayer
## Installation
### Software dependencies
To make this project up and running, you need:

* **Node** 0.8.7
* **NPM** 1.1.32
* **Mongo** 2.0.6

### Dependencies
This project is build at the top of the pleasant [Node Package Manager](http://npmjs.org/). To download and set up the whole dependancies three, simply run from the project's root directory :

    $ npm install

### Environment variables
The following environment variables can be use with the highest priority :

* **PORT** defines the port to listen to (ex: *80*);
* **DATABASE_URL** defines the way to connect to MongoDB (ex: *mongodb://localhost/db*);
* **NODE_ENV** defines the runing mode (ex: *development*, *production*, etc);

## Run
To launch the server (once the installation is complete), just run from the root of the project:

```
$ coffee app.coffee
```

### JSON file structure
Such as a configuration file, the JSON file must fit to the following structure :

```javascript
{
    "title": "Title of the app",
    "navigation": "horizontal",
    "menu-position": "right bottom",
    "width": 900,
    "height": 600,
    "layout": "default",
    "theme": "default",
    // An array detailing every steps
    "steps": [
        // Step configuration
        {        
            "name": "name of the step",
            "spots": [ 
                // Spot configuration
                {
                    "top":  "0%",
                    "left": "50%",
                    // ...
                }
            ],
            // ...
        }
    ]

```
<a id="player" />
### Player configuration
Every player object can follow this options:

Name | Type | Description | Exemple |
---- | ---- | ---- | ---- |
name | String | Name of the player | Soft kitty
navigation | String | Navigation direction: *horizontal* (default) or *vertical* |
theme | String | Theme of the player: *dark* (default), *light*, *purple*, *green* |
layout | String | Layout of the player: *default*, *horizontal-tabs*, *vertical-tabs* |
menu-position | String | Menu position related to a corner: *top*, *bottom*, *left*, *right* | "bottom right"
width | String, Number | Player width | 850
height | String, Number | Player height | 600


<a id="steps" />
### Step configuration
Every step object can follow this options:

Name | Type | Description | Exemple |
---- | ---- | ---- | ---- |
name | String | Name of the step, displaying on the main menu. | "Soft kitty, warm kitty"
no-index | Boolean | Set to true exit the step from the main menu. |
picture | String | URL to an image file to display as "background", take the whole width. | 
style | String | Inline CSS to apply to the current step. | "font-size:17px; color: red"
spots | Array | List of spots display in that step, see also [Spot configuration](#spots). |
class | String | One or serveral space-separated classes to put on the step | "purr"

<a id="spots" />
### Spot configuration
Every spot object can follow this options:

Name | Type | Description | Exemple |
---- | ---- | ---- | ---- |
type | String | Type of the spot: *default*, *link*, *iframe*, *image* | "default"
src | String | **Types iframe and image only**;
href | String | **Type link only;** href value of the hotspot. Can be an URL or an anchor. | "#step=1"
top | String, Number | Top position of the spot from the top-left corner of the step. | "10%"
left | String, Number | Left position of the spot from the top-left corner of the step. | "20%"
width | String, Number | Width of the spot. | "100px"
height | String, Number | Height of the spot. | 100
title | String | Title of the spot, display at its head. | "Little ball of fur"
sub-title | String  | Sub-title of the spot, display bellow the title. | "Happy kitty, sleepy kitty"
picture | Object | A picture to dispay bellow the sub-title. Taken to properties: ```src```and ```alt``` |
style | String | Inline CSS to apply to the current spot. | "font-size:17px; color: red"
class | String | One or serveral space-separated classes to put on the spot. | "purr"
entrance | String | Animates the entrance of the spot when a step the get the focus. See also [#entrances](Entrance animation) | "zoomIn", "left down", etc
entrance-duration | Integer | Duration of the entrance animation. Default to 300. | 1000
queue | Boolean | If true, the spot wait the end of the previous spot's entrance to appear. |
background | String | URL to an image file to display as background of the step |
background-direction | String, Number | Animate the background into that direction in a loop. Can be a number to specify a dicrection in degree. | "left", 90, "top left", etc
background-speed | Number | Distance in pixels to run through at each animation step. 3 by default. | 10
background-frequency | Number | Animation step frequency in millisecond. 0 by default. | 200

<a id="entrance" />
### Entrance animations
To animate the entrance of a spot, you can use one or several of the following animation class :

Name | Description
---- | ----
left | Sliding to the left
right | Sliding to the right
up | Sliding to the top
down | Sliding to the bottom
zoomIn | Zoom in (getting bigger)
zoomOut | Zoom out (getting smaller)
fadeIn | Fading entrance
