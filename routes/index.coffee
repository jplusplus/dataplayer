# Dependencies
path     = require("path")
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
  mongoose.connect process.env.DATABASE_URL or config.DATABASE_URL  
  # Set routes
  app.get "/", homepage
  app.get "/create", createScreen
  app.get "/:page", viewScreen
  app.post "/:page/content", updateContent
  app.post "/:page/draft", updateDraft

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
    slug: req.params.page,
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
    dataObject = setDefaultValues(JSON.parse(req.body.content))
  catch e    
    # Catch the parsing error
    return res.send(500, "Invalid configuration.")
  
  # Update the screen into the database
  Screen.update
    slug: req.params.page
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
    dataObject = setDefaultValues(JSON.parse(req.body.content))
  catch e    
    # Catch the parsing error
    return res.send(500, "Invalid configuration.")
  
  # Update the screen into the database
  Screen.update
    slug: req.params.page
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
  
  # Create the screen object
  s = new Screen(
    slug: randomString(5)
    token: randomString(10)
    created_at: new Date()
    content: require("../data/sample.json")
    draft: {}
  )
  
  # Save it to the databse
  s.save (err, data) ->    
    # Duplicate slug, try again
    if err and err.code is 11000
      return createScreen(req, res)    
    # Other error
    else return res.send(500)  if err    
    # Redirect to the new screen
    res.redirect "/" + data.slug + "?edit=" + data.token

###*
 * Put the default screen values into the given obj
 * @param  {Object} obj Screen descriptor
 * @return {Object}     Screen descriptor updated
###
setDefaultValues = (obj) ->
  
  # Default values
  defaults = _.clone(require("../data/default.json"))
  defaultsStep = _.clone(require("../data/default-step.json"))
  
  # Extend the obj value
  obj = _.extend(defaults, obj)
  obj

###*
 * Simple function to generate a random string with the given length
 * @param  {Number} length Length of the random String
 * @return {String}        Random string
###
randomString = (length) ->
  chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZabcdefghiklmnopqrstuvwxyz"
  length = (if length then length else 32)
  string = ""
  i = 0

  while i < length
    randomNumber = Math.floor(Math.random() * chars.length)
    string += chars.substring(randomNumber, randomNumber + 1)
    i++
  string