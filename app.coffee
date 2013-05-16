###
Module dependencies.
###
express       = require("express")
config        = require("config")
http          = require("http")
path          = require("path")
oembed        = require("oembed")
flash         = require('connect-flash')
passport      = require("passport")
mongoose      = require("mongoose")
MongoStore    = require('connect-mongo') express

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
  app.set "pages", __dirname + "/views/pages"
  app.set "views", __dirname + "/views"
  app.set "view engine", "jade"
  app.set "db", process.env.DATABASE_URL or config.database_url

  # Middlewares
  app.use express.logger("dev")
  app.use express.bodyParser()
  app.use express.methodOverride()  
  app.use express.cookieParser()
  sessionOptions =
    secret : process.env.SALT_SESSIONS or config.salts.sessions
    store  : new MongoStore url: app.get("db")
  app.use express.session sessionOptions

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
  passport.serializeUser require("./routes/user").serializeUser
  # Get the user matching to the token
  passport.deserializeUser require("./routes/user").deserializeUser
  # Creates passport strategy
  passport.use require("./routes/user").localStrategy
  # Remember Me middleware
  app.use require("./routes/user").rememberMe


  # Register helpers functions for use in view's
  app.locals require("./utils").locals(app)
  # Add context helpers
  app.use require("./utils").context  
  # @warning Needs to be after helpers
  app.use app.router    
  # Load the user route file
  require("./routes/user") app
  # Load the default route file
  require("./routes") app
  # Load api resources and routers
  require("./routes/api") app
  
  # Returns the app, explicitely
  return app

app.configure "development", ->
  app.use express.errorHandler()

# Connect mongoose
mongoose.connect app.get("db"), ->
  # Then create the express server
  http.createServer(app).listen app.get("port"), ->
    console.log "Express server listening on port " + app.get("port")
