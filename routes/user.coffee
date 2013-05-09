passport = require("passport")
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
    