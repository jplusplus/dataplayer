passport = require("passport")
# Module variables
app = undefined

module.exports = (a)->
  app = a  

  app.post('/login', passport.authenticate('local'), (req, res)->
    # If this function gets called, authentication was successful.
    # `req.user` contains the authenticated user.
    res.redirect('/user/' + req.user.username);
  )