###
Module dependencies.
###
express = require("express")
md      = require("marked")
fs      = require("fs")
http    = require("http")
path    = require("path")

# Create the Express app
app = express()

###*
 * App configuration callback
 * @return {Object} The app
###
app.configure ->
  # Sets configuration variable
  app.set "port", process.env.PORT or 3000
  app.set "data", __dirname + "/data"
  app.set "pages", __dirname + "/pages"
  app.set "views", __dirname + "/views"
  app.set "view engine", "jade"

  app.use express.logger("dev")
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use require("connect-assets")(src: __dirname + "/public")
  app.use express.static(path.join(__dirname, "public"))
  app.use (req, res, next) ->
    res.locals.path = req.path
    next()

  
  ###
  Views helpers
  ###

  # Register helpers for use in view's
  app.locals
    # Constant containing the node environment (development, production, etc)
    NODE_ENV: process.env.NODE_ENV

    ###*
     * Return the class of the container according descriptor
     * @param  {Object} data Screen descriptor
     * @return {String}      Container classes
    ###
    containerClass: (data) ->
      klasses = data["menu-position"].split(" ")
      layout = data["layout"]
      
      # For each class 
      for k of klasses
        
        # Add a suffix
        klasses[k] = layout + "-" + klasses[k]
      klasses.join " "

    ###*
     * Container context style
     * @param  {Object} data Screen descriptor
     * @return {String}      CSS style
    ###
    screenStyle: (data) ->
      toPx = (val) ->
        (if isNaN(val) then val else val + "px")

      style = []      
      # Add size
      style.push "width:" + toPx(data.width)  if data.width
      style.push "height:" + toPx(data.height)  if data.height
      style.join ";"

    ###*
     * Step context style
     * @param  {Object} data Step descriptor
     * @return {String}      CSS style
    ###
    stepStyle: (step) ->
      style = []      
      # Add style
      style.push step.style  if step.style
      style.join ";"

    ###*
     * Spot context style
     * @param  {Object} data Spot descriptor
     * @return {String}      CSS style
    ###
    spotStyle: (spot) ->
      toPx = (val) ->
        (if isNaN(val) then val else val + "px")

      style = []
      
      # Add position
      style.push "top:" + toPx(spot.top or 0)
      style.push "left:" + toPx(spot.left or 0)      
      # Add size
      style.push "width:" + toPx(spot.width)  if spot.width
      style.push "height:" + toPx(spot.height)  if spot.height      
      # Add style
      style.push spot.style  if spot.style
      style.join ";"

    ###*
     * Spot wrapper context style
     * @param  {Object} data Spot descriptor
     * @return {String}      CSS style
    ###
    spotWrapperStyle: (spot) ->
      style = []      
      # Add background
      style.push "background-image: url(" + spot.background + ")"  if spot.background      
      # Add style
      style.push spot.wrapperStyle  if spot.wrapperStyle
      style.join ";"

    ###*
     * Spot context classes
     * @param  {Object} data Spot descriptor
     * @return {String}      Classes
    ###
    spotClass: (spot) ->
      klass = []
      
      # Spot classes
      klass.push spot.class  if spot.class
      klass.join " "

    ###*
     * Template helper to remove html tags (to plain text)
     * @copyright http://kevin.vanzonneveld.net
     * @param  {String} input   HTML to escape
     * @param  {Array} allowed  Allowed tags
     * @return {String}         Input string as plain text
    ###
    stripTags: (input, allowed) ->
      return ""  unless input      
      allowed = (((allowed or "") + "").toLowerCase().match(/<[a-z][a-z0-9]*>/g) or []).join("") # making sure the allowed arg is a string containing only tags in lowercase (<a><b><c>)
      tags = /<\/?([a-z][a-z0-9]*)\b[^>]*>/g
      commentsAndPhpTags = /<!--[\s\S]*?-->|<\?(?:php)?[\s\S]*?\?>/g
      input.replace(commentsAndPhpTags, "").replace tags, ($0, $1) ->
        (if allowed.indexOf("<" + $1.toLowerCase() + ">") > -1 then $0 else "")

    ###*
     * Return the given page (parsed from Markdown)
     * @param  {String} name Page name
     * @return {String}      Page HTML code
    ###
    getPage: (name) ->      
      # Builds file name
      fileName = path.join(app.get("pages"), name) + ".md"      
      # Checks that file exists
      return ""  unless fs.existsSync(fileName)      
      # Read the text file
      file = fs.readFileSync(fileName, "UTF-8")      
      # Parse the markdown      
      md file

  # Add context helpers
  app.use (req, res, next) ->
    res.locals.editMode = req.query.hasOwnProperty("edit")
    res.locals.editToken = req.query["edit"]
    res.locals.publicURL = (obj) ->
      req.protocol + "://" + req.headers.host + "/" + obj.slug
    res.locals.privateURL = (obj) ->
      res.locals.publicURL(obj) + "?edit=" + req.query["edit"]
    next()
    
  # @warning Needs to be after helpers
  app.use app.router  
  # Load the default route file
  require("./routes") app
  # Returns the app, explicitely
  return app


app.configure "development", ->
  app.use express.errorHandler()

http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")
