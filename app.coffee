###
Module dependencies.
###
express       = require("express")
config        = require("config")
md            = require("marked")
fs            = require("fs")
http          = require("http")
path          = require("path")
oembed        = require("oembed")
flash         = require('connect-flash')
passport      = require("passport")
LocalStrategy = require("passport-local").Strategy
User          = require("./models").User

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

  # Middlewares
  app.use express.logger("dev")
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.cookieParser(config.salts.cookies)
  app.use express.session()     
  # Flash messages
  # see also: https://github.com/jaredhanson/connect-flash    
  app.use flash()
  # Assets managers
  app.use require("connect-assets")(src: __dirname + "/public")
  app.use express.static(path.join(__dirname, "public"))

  # configure oembed client to use embedly as fallback
  oembed.EMBEDLY_KEY = process.env.EMBEDLY_KEY or config.EMBEDLY_KEY

  # Authentification with passport
  app.use passport.initialize()
  app.use passport.session()

  # Passport session setup.
  # To support persistent login sessions, Passport needs to be able to
  # serialize users into and deserialize users out of the session. Typically,
  # this will be as simple as storing the user ID when serializing, and finding
  # the user by ID when deserializing.
  passport.serializeUser (user, done)->done(null, user)
  passport.deserializeUser (user, done)->done(null, user)

  # Creates passport strategy
  passport.use(new LocalStrategy (username, password, done)->
    # Get the user from the database
    User.findOne(username: username, (err, user)->
      # Something happens   
      if err   
        return done(err) 
      # The username is incorrect
      unless user
        return done(null, false, message: "Incorrect username.")
      # The password is incorrect
      unless user.authenticate(password)
        return done(null, false, message: "Incorrect password.")
      # Everything is OK
      done null, user
    )
  )


  ###
  Views helpers
  ###  
  # Register helpers for use in view's
  app.locals
    # Constant containing the node environment (development, production, etc)
    NODE_ENV: process.env.NODE_ENV
    ###*
     * Return the class of the overflow according descriptor
     * @param  {Object} data Screen descriptor
     * @return {String}      Overflow classes
    ###
    overflowClass: (data) ->
      klasses = data["menu-position"].split(" ")
      layout = data["layout"]      
      # For each class 
      for k of klasses        
        # Add a suffix
        klasses[k] = layout + "-" + klasses[k]

      klasses.push data.navigation || "horizontal"
      klasses.push data.layout || "default"
      klasses.push "scroll-allowed" if data.scroll
        
      klasses.join " "

    ###*
     * Return the class of the container according descriptor
     * @param  {Object} data Screen descriptor
     * @return {String}      Container classes
    ###
    containerClass: (data) ->
      return    

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
      # Default type
      type = spot.type or "text"
      klass.push "type-#{type}"
      # Deactivate the background on demand      
      klass.push "no-bg" if spot["no-bg"]
      # Spot classes
      klass.push spot.class if spot.class
      klass.join " "


    ###*
     * Template helper to remove html tags (to plain text)
     * @copyright http://kevin.vanzonneveld.net
     * @param  {String} input   HTML to escape
     * @param  {String} allowed  Allowed tags (ex: <a><b><em>)
     * @return {String}         Input string as plain text
    ###
    stripTags: require("./utils").stripTags

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
    # Current user
    res.locals.user = if req.isAuthenticated() then req.user else false
    res.locals.path = req.path
    res.locals.editMode = req.query.hasOwnProperty("edit")
    res.locals.editToken = req.query["edit"]
    res.locals.publicURL = (obj) ->
      req.protocol + "://" + req.headers.host + "/" + obj.slug
    res.locals.privateURL = (obj) ->
      res.locals.publicURL(obj) + "?edit=" + req.query["edit"]
    next()
    
  # @warning Needs to be after helpers
  app.use app.router  
  # Load the user route file
  require("./routes/user") app
  # Load the default route file
  require("./routes") app
  # Returns the app, explicitely
  return app


app.configure "development", ->
  app.use express.errorHandler()

http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")
