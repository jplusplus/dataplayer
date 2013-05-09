passport     = require("passport")
User         = require("../models").User
isValidEmail = require("../utils").isValidEmail
# Module variables
app = undefined

module.exports = (a)->
  app = a  

  app.get('/logout', (req, res)->    
    req.logout()
    res.redirect("/")
  )

  loginOptions = 
    successRedirect: '/'
    failureRedirect: '/login'
    failureFlash: true

  # Intercept the login form
  app.post '/login', passport.authenticate('local', loginOptions)
  # Intercept the login error
  app.get '/login', (req, res)-> 
    # Do we transmit a flash message ?
    req.flash 'errorLogin', req.flash('error')
    # Redirect to the homepage 
    res.redirect("/")

  # Intercept the signup form
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
      res.redirect "/"

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