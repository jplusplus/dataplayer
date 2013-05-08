crypto   = require('crypto')
mongoose = require("mongoose")
# Self returning
module.exports = -> module.exports


###*
 * Screen Schema
 * @var {Object} The object describing the Screen Schema
###
screenSchema = module.exports.screenSchema = mongoose.Schema(
  slug:
    type: String
    index:
      unique: true
  token: String
  content: mongoose.Schema.Types.Mixed
  draft: mongoose.Schema.Types.Mixed
  created_at: Date
)

###*
 * Screen model
 * @var {Object} The class creating from the Screen model
###
Screen = module.exports.Screen = mongoose.model('Screen', screenSchema)

