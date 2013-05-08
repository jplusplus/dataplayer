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


###*
 * User Schema
 * @var {Object} The object describing the User Schema
###
userSchema = module.exports.userSchema = mongoose.Schema(
  username:
    type: String
    index:
      unique: true
  email:
    type: String
    index:
      unique: true
  hashed_password: String
  salt: String
)

# Creates a virtual attribute that contains the id of the user
userSchema.virtual("id").get -> @_id.toHexString()

# Creates a virtual attribute that contains the password of the user (before encryption)
userSchema.virtual("password").set((password) ->
  @_password = password
  @salt = @makeSalt()
  @hashed_password = @encryptPassword(password)
).get -> @_password

###*
 * Authenticate checking method
 * @param  {String} plainText Password not hashed
 * @return {Boolean}          True if the passwords match
###
userSchema.method "authenticate", (plainText)-> @encryptPassword(plainText) is @hashed_password

###*
 * Create a random salt for the password hash
 * @return {String} Random salt
###
userSchema.method "makeSalt", -> "" + Math.round((new Date().valueOf() * Math.random()))

###*
 * Encrypt the given password
 * @param  {String} password Password to encrypt
 * @return {String}          Passwird encrypted
###
userSchema.method "encryptPassword", (password) -> crypto.createHmac("sha1", @salt).update(password).digest "hex"

###*
 * User model
 * @var {Object} The class creating from the User model
###
User = module.exports.User = mongoose.model('User', userSchema)