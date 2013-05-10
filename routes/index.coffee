# Dependencie
path     = require("path")
async    = require("async")
_        = require("underscore")
fs       = require("fs")
mongoose = require("mongoose")
Screen   = require("../models").Screen
config   = require("config")
oembed   = require("oembed")

# Module variables
app = undefined

module.exports = (a) ->
  app = a  
  # Connect mongoose
  mongoose.connect process.env.DATABASE_URL or config.database_url  
  # Set routes
  app.get "/", homepage
  app.get "/create", createScreen
  app.get "/fork/:slug", createScreen
  app.get "/:slug", viewScreen
  app.post "/:slug/content", updateContent
  app.post "/:slug/draft", updateDraft

###*
 * Homepage router
 * @param  {Object} req Client request object
 * @param  {Object} res Client result object
###
homepage = (req, res) ->
  locals=
    demoSlideshow: process.env.DEMO_SLIDESHOW or config["demo_slideshow"]
  res.render "home", locals

###*
 * Single screen router 
 * @param  {Object} req Client request object
 * @param  {Object} res Client result object
###
viewScreen = (req, res) ->
  Screen.findOne(
    slug: req.params.slug,
    (err, screen) ->
      # Error cases
      return res.send(500) if err
      return res.send(400, "Page not found.")  if not screen? or not screen
      
      # Template file 
      tplDir = "sliders/"
      tplName = screen.content.layout + "." + app.get("view engine")
      tplPath = path.join(app.get("views"), tplDir, tplName)
      
      # End callback
      end = (err, screen)->     
        # Error case
        return res.send 500 if err   

        # Change the layout if not exists
        screen.content.layout = (if fs.existsSync(tplPath) then screen.content.layout else "default")      
        # Preview mode, use the draft as screen
        screen.content = screen.draft or screen.content  if req.query.preview      

        # Determines if this is the edit mode (false by default)
        editMode  = false
        # Edit request
        if req.query.edit?
          # If the authenicated user is the author
          editMode |= req.isAuthenticated() and String(screen.author) == String(req.user._id)
          # Or if the given token is the editToken and the screen has no author
          editMode |= not screen.author? and screen.token == req.query.edit

          # If the user just own a screen
          if req.isAuthenticated() and screen.token == req.query.edit
            # Redirect to the url without token 
            return res.redirect("/#{screen.slug}?edit")

        # Render the page template      
        # Use the default template if needed 
        res.render path.join(tplDir, screen.content.layout), 
          # To know if the user ask for edition
          editRequest: req.query.edit?
          # Activate edit mode
          editMode: editMode
          # Get the edit token
          editToken: if editMode then screen.token else null
          # Send the screen to the template
          obj: screen

      # Import the screen to an user if need
      if req.isAuthenticated() then importUserScreen(req.user, screen, end)
      # Or just terminates
      else end null, screen
  )


###*
 * Post method router that update the screen content
 * @param  {Object} req Client request object
 * @param  {Object} res Client result object
###
updateContent = (req, res) ->
  try    
    # JSON parsing to avoid inbject javascript
    dataObject = JSON.parse(req.body.content)
  catch e    
    # Catch the parsing error
    return res.send(500, "Invalid configuration.")

  # Clean the configuration objecy
  cleanConfiguration dataObject, (err, dataObject)->     
    # Update the screen into the database
    Screen.update
      slug: req.params.slug
      token: req.body.token
    ,
      content: dataObject
    , (err, data) ->
      
      # Error during update
      if err
        res.send 500, "Impossible to update the page."    
      # Screen not found
      else unless data?
        res.send 400, "Page not found."    
      # OK
      else
        res.json dataObject

###*
 * Post method to update the screen draft
 * @param  {Object} req Client request object
 * @param  {Object} res Client result object
###
updateDraft = (req, res) ->
  try    
    # JSON parsing to avoid inbject javascript
    dataObject = JSON.parse(req.body.content)
  catch e    
    # Catch the parsing error
    return res.send(500, "Invalid configuration.")
  
  # Clean the configuration objecy
  cleanConfiguration dataObject, (err, dataObject)->   
    # Update the screen into the database
    Screen.update
      slug: req.params.slug
      token: req.body.token
    ,
      draft: dataObject
    , (err, data) ->
      
      # Error during update
      if err
        res.send 500, "Impossible to update the page."    
      # Screen not found
      else unless data?
        res.send 400, "Page not found."    
      # OK
      else
        res.json dataObject

###*
 * Router to create a screen and redirect to that screen
 * @param  {Object} req Client request object
 * @param  {Object} res Client result object
###
createScreen = (req, res) ->

  # Is it a fork ?
  if req.params.slug? and not res.locals.content?
    return Screen.findOne
      slug: req.params.slug,
      (err, screen)->
        res.locals.content = screen.content if screen?
        createScreen(req, res)

  content = if res.locals.content? then res.locals.content else require("../data/sample.json")
  # Create the screen object
  s = new Screen(
    slug: require("../utils").randomString(5)
    token: require("../utils").randomString(10)
    created_at: new Date()
    content: content
    draft: {}
    author: if req.isAuthenticated() then req.user._id else null
  )

  # Save it to the databse
  s.save (err, data) ->    
    # Duplicate slug, try again
    if err and err.code is 11000
      return createScreen(req, res)    
    # Other error
    else return res.send(500) if err 
    # Basic redirect url       
    url = "/" + data.slug + "?edit"
    # Add the token if we are not connected to allow anonymmous 
    url += "=" + data.token unless req.isAuthenticated()
    # Redirect to the new screen
    res.redirect url 

###*
 * Clean the given configuration object
 * @param  {Object}   obj      Configuration object
 * @param  {Function} callback Callback function
###
cleanConfiguration = (obj, callback=->) -> 
  # Set default values
  obj = setDefaultValues obj
  # Look for the missing embed into given object's spots
  completeMissingEmbed obj, callback  

###*
 * Put the default screen values into the given obj
 * @param  {Object} obj Screen descriptor
 * @return {Object}     Screen descriptor updated
###
setDefaultValues = (obj) ->
  # Default values
  defaults = _.clone require("../data/default.json")
  # Extend the obj value
  obj = _.extend(defaults, obj)  
  # Sanitaze each fields and return the obj
  require("../utils").sanitaze(obj)  
  
###*
 * Complete uncomplete embed spot with there oembed
 * @param  {Object}   obj      Configuration object
 * @param  {Function} callback Callback function
###
completeMissingEmbed = (obj, callback=->) ->
  urls = []
  # Get the embed spot with a missing embed
  iterateMissingEmbed obj, (spot)->
    # add the spot to the queue
    urls.push 
      url: spot.url
      width: spot.width
      height: spot.height
      wmode: 'transparent'

  # No URL to load, stop here
  return callback null, obj if urls.length == 0

  # Func to get an embed code
  getEmbed = (o, next)-> oembed.fetch(o.url, o, next)

  # Apply this function to every obj
  async.map urls, getEmbed, (err, oembeds)->    
    # No error ?
    unless err
      # Get the embed spot with a missing embed
      iterateMissingEmbed obj, (spot, index)->
        # Retreive the corresponding oembed 
        oembed = oembeds[index]
        # if it's OK...
        if not oembed.error?
          # ...record the embed code
          spot.oembed = oembed.html
    # Add the end, pass to the next tick 
    callback(err, obj)

###*
 * Get the embed spots without oembed
 * @param  {Object}   obj      Configuration object
 * @param  {Function} iterator Iterator function
###
iterateMissingEmbed = (obj, iterator)-> 
  index = 0   
  # Fetch each step
  _.each obj.steps or [], (step, stKey)->
    # Fetch each spots into this step
    _.each step.spots or [], (spot, spKey)->
      # is the given spot an embed ?
      if spot.type == "embed"
        # is there an url ?
        if spot.url?
          # Is the oembed code present ?
          if not spot.oembed? or spot.oembed == ""
            # Iterate the spot
            iterator spot, index++
      # Do not interupt the loop
      return true


importUserScreen = (user, screen, callback)->
  # If the screen hasn't an author yet
  unless screen.author?
    # Update it author
    screen.author = user._id
    # Save the screen
    screen.save callback
  else
    # Nothing to do
    callback null, screen
    
