passport = require("passport")
# Module variables
app = undefined

module.exports = (a)->
  app = a  

  app.get '/login', (req, res)-> res.render("widgets/login-form")

  app.post('/login', passport.authenticate('local'), (req, res)->
    # If this function gets called, authentication was successful.
    # `req.user` contains the authenticated user.
    res.redirect('/user/' + req.user.username);
  )