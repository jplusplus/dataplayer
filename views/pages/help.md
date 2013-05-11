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
entrance | String | Animates the entrance of the spot when a step the get the focus. | "zoomIn", "left down", etc
entrance-duration | Integer | Duration of the entrance animation. Default to 300. | 1000
queue | Boolean | If true, the spot wait the end of the previous spot's entrance to appear. |
background | String | URL to an image file to display as background of the step |
background-direction | String, Number | Animate the background into that direction in a loop. Can be a number to specify a dicrection in degree. | "left", 90, "top left", etc
background-speed | Number | Distance in pixels to run through at each animation step. 3 by default. | 10
background-frequency | Number | Animation step frequency in millisecond. 0 by default. | 200

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