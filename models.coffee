mongoose = require("mongoose")
# Self returning
module.exports = -> module.exports

###*
 * Screen model
 * @var {Object} The object describing the Screen model
###
module.exports.Screen = mongoose.model("Screen",
  slug:
    type: String
    index:
      unique: true
  token: String
  content: mongoose.Schema.Types.Mixed
  draft: mongoose.Schema.Types.Mixed
  created_at: Date
)
