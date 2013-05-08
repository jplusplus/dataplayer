passport = require("passport")
# Module variables
app = undefined

module.exports = (a)->
  app = a  

  app.get('/logout', (req, res)->    
    req.logout()
    res.redirect("/")
  )

  # Always redirect to the home after 
  authOpt = 
    successRedirect: '/'
    failureRedirect: '/'
    failureFlash: true

  # Intercept the login form
  app.post '/login', passport.authenticate('local', authOpt)