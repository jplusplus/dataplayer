# Dependencies
Embedly  = require('embedly')
path     = require("path")
async    = require("async")
_        = require("underscore")
fs       = require("fs")
mongoose = require("mongoose")
Screen   = require("../models").Screen
config   = require("config")

# Module variables
app = undefined

module.exports = (a) ->
  app = a  
  # Connect mongoose
  mongoose.connect process.env.DATABASE_URL or config.database_url  
  # Create the embedly client
  new Embedly key: config.embedly_key, (e, api)-> exports.embedly = api unless e
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
  res.render "home"

###*
 * Single screen router 
 * @param  {Object} req Client request object
 * @param  {Object} res Client result object
###
viewScreen = (req, res) ->
  Screen.findOne(
    slug: req.params.slug,
    (err, data) ->
      # Error cases
      return res.send(500)  if err
      return res.send(400, "Page not found.")  if not data? or not data
      
      # Template file 
      tplDir = "sliders/"
      tplName = data.content.layout + "." + app.get("view engine")
      tplPath = path.join(app.get("views"), tplDir, tplName)
      
      # Change the layout if not exists
      data.content.layout = (if fs.existsSync(tplPath) then data.content.layout else "default")
      
      # Preview mode, use the draft as data
      data.content = data.draft or data.content  if req.query.preview
      
      # Render the page template      
      # Use the default template if needed 
      res.render path.join(tplDir, data.content.layout),        
        # Send the data to the template
        obj: data
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
  )

  # Save it to the databse
  s.save (err, data) ->    
    # Duplicate slug, try again
    if err and err.code is 11000
      return createScreen(req, res)    
    # Other error
    else return res.send(500) if err    
    # Redirect to the new screen
    res.redirect "/" + data.slug + "?edit=" + data.token

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
  defaults = _.clone(require("../data/default.json"))
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
  return callback null, obj if urls.length == 0 or not exports.embedly?

  async.map urls, exports.embedly.oembed, (err, oembeds)->    

    console.log oembeds
    # No error ?
    unless err
      # Get the embed spot with a missing embed
      iterateMissingEmbed obj, (spot, index)->
        # Retreive the corresponding oembed 
        oembed = oembeds[index]
        # if it's OK...
        if not oembed.error? and oembed.length
          # ...record the embed code
          spot.oembed = oembed[0].html
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


    
