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
  app.set "pages", __dirname + "/views/pages"
  app.set "views", __dirname + "/views"
  app.set "view engine", "jade"

  # Middlewares
  app.use express.logger("dev")
  app.use express.bodyParser()
  app.use express.methodOverride()  
  app.use express.cookieParser process.env.SALT_COOKIES or config.salts.cookies
  app.use express.session(secret: process.env.SALT_SESSIONS or config.salts.sessions)     
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
  passport.serializeUser (user, done)->    
    createAccessToken = ->      
      token = user.makeSalt 30
      User.findOne accessToken: token, (err, existingUser) ->
        return done err if err
        # Run the function again - the token has to be unique!
        if existingUser then createAccessToken() 
        # Remeber the access token into session
        else
          user.set "access_token", token
          user.save (err) ->
            return done(err) if err
            done null, user.get("access_token")
    # creates the token
    createAccessToken() if user._id

  # Get the user matching to the token
  passport.deserializeUser (token, done)-> User.findOne access_token: token, done


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
  # Returns the app, explicitely
  return app


app.configure "development", ->
  app.use express.errorHandler()

http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")
