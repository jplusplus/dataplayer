passport     = require("passport")
User         = require("../models").User
Screen       = require("../models").Screen
isValidEmail = require("../utils").isValidEmail
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

  
      