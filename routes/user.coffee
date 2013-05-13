passport      = require("passport")
User          = require("../models").User
Screen        = require("../models").Screen
isValidEmail  = require("../utils").isValidEmail
LocalStrategy = require("passport-local").Strategy
# Module variables
app = undefined

module.exports = (a)->
  app = a  

  # Intercepts the user profile
  app.get '/user/:username', userProfile

  ###*
   * Logout the user
   * @param  {Object} req User request
   * @param  {Object} res User result
  ###
  app.get '/logout', (req, res)->    
    req.logout()
    res.redirect("back")  

  loginOptions = 
    successRedirect: 'back'
    failureRedirect: '/login'
    failureFlash: true
  
  ###*
   * Login form
   * @param  {Object} req User request
   * @param  {Object} res User result
  ###
  app.get '/login', (req, res)-> 
    # Redirect authenticated users to the hp
    return res.redirect("/") if req.isAuthenticated()
    res.render("login")


  ###*
   * Intercept the login form
   * @param  {Object} req User request
   * @param  {Object} res User result
  ###
  app.post '/login', passport.authenticate('local', loginOptions)

  ###*
   * Intercept the login error
   * @param  {Object} req User request
   * @param  {Object} res User result
  ###
  app.get '/login', (req, res)->
    # Do we transmit a flash message ?
    req.flash 'errorLogin', req.flash('error')
    # Redirect to the homepage 
    res.redirect("back")

  ###*
   * Intercept the signup form
   * @param  {Object} req User request
   * @param  {Object} res User result
  ###
  app.post '/signup', (req, res)->

    # Create the user object
    user = new User
      username : req.body.username
      email    : req.body.email
      password : req.body.password
          
    # Normalize end function
    end=(err)->
      req.flash "errorSignup", err
      req.flash "tmpUser", user
      # Always redirect to the homepage
      res.redirect "back"

    # Check email format    
    return end("Wrong email address.") unless isValidEmail req.body.email
    # Check passwords is long enougt    
    return end("Password too short.") if req.body.password.length < 8
    # Check passwords are the sames
    return end("Wrong password confirmation.") if req.body.password != req.body.password_again

    # Save the new user
    user.save (e, obj)->
      unless e
        # Everything is OK,
        # log the user in
        req.logIn obj, end
      # If there is an error
      else
        # Duplicates
        if e.code == 11000
          end "Email already taken."          
        # Several errors
        else if e.errors        
          # Collect the errors and put them as flash message
          end error.type for key, error of e.errors   
        else if e.message
          end e.message
        else
          end "Something went wrong."

###*
 * User profile
 * @param  {Object} req User request
 * @param  {Object} res User result
###
userProfile = (req, res)->
  # Get the user
  User.findOne username: req.params.username, (err, user)->
    # Error cases
    return res.send(500) if err
    return res.send(400, "User not found.") unless user?

    # Screen filter
    filter =
      # By author
      "author": user._id
      # And only the public one
      "content.private": "$ne": true

    # Get the user's screens
    Screen.find filter, (err, screens)->
      # Error cases
      return res.send(500) if err
      # Show the user profile
      res.render "user", 
        isYou: req.isAuthenticated() and String(req.user._id) == String(user._id)
        userProfile: user        
        screens: screens



###*
 * User serialization function
 * 
 * Passport session setup.
 * To support persistent login sessions, Passport needs to be able to
 * serialize users into and deserialize users out of the session. Typically,
 * this will be as simple as storing the user ID when serializing, and finding
 * the user by ID when deserializing.
 * 
 * @param  {Object}   user Given user
 * @param  {Function} done Callback function
###
module.exports.serializeUser = (user, done)->        
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

###*
 * Get the user matching to the token
 * @param  {String}   token User access token
 * @param  {Function} done  Callback function
###
module.exports.deserializeUser = (token, done)-> User.findOne access_token: token, done


###*
 * Creates passport strategy
 * @param  {String}   username Username
 * @param  {String}   password Passport (in clear)
 * @param  {Function} done     Callbackfunction
 * @return {Object}            LocalStrategy instance
###
module.exports.localStrategy = new LocalStrategy (username, password, done)->
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

###*
 * Remember Me middleware
 * @param  {Object}   req  User request
 * @param  {Object}   res  User result
 * @param  {Function} next Callbackfunction
###
module.exports.rememberMe = (req, res, next) ->
  if req.method is "POST" and req.url is "/login"
    if req.body.remember_me
      req.session.cookie.maxAge = 2592000000 # 30*24*60*60*1000 Rememeber 'me' for 30 days
    else
      req.session.cookie.expires = false
  next()


  
      