crypto   = require('crypto')
mongoose = require("mongoose")
bcrypt   = require('bcrypt')

# Self returning
module.exports = -> module.exports

###*
 * Just ensure that the given value exists
 * @param  {Mixed} value Value to check
 * @return {Boolean}     True if the value exists
###
validatePresenceOf = (value)-> value && value.length


###*
 * User Schema
 * @var {Object} The object describing the User Schema
###
userSchema = module.exports.userSchema = mongoose.Schema(
  username:
    type: String
    validate: [validatePresenceOf, 'An username is required.']
  email:
    type: String
    validate: [validatePresenceOf, 'An email is required.']
    index:
      unique: true
  hashed_password: String
  salt: String
  access_token: String
)

# Creates a virtual attribute that contains the id of the user
userSchema.virtual("id").get -> @_id.toHexString()

# Creates a virtual attribute that contains the email hashed (for gravatar)
userSchema.virtual("email_hash").get -> crypto.createHash('md5').update(@email).digest("hex");

# Creates a virtual attribute that contains the password of the user (before encryption)
userSchema.virtual("password").set((password) ->
  @_password = password
  @salt = @makeSalt()
  @hashed_password = @encryptPassword(password)
).get -> @_password


# Checks that the username isn't taken yet
userSchema.pre "save", (next) ->      
  # Looks for users with the same username
  User.findOne username: @username, (err, user) =>
    # Username exists!
    if user
      @invalidate "username", "Username already taken."
      err = new Error("Username already taken.")
    # Callback function
    next err


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
userSchema.method "makeSalt", -> "" + bcrypt.genSaltSync(15)

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
  author:
    type: mongoose.Schema.Types.ObjectId
    ref: 'UserSchema'
)

###*
 * Screen model
 * @var {Object} The class creating from the Screen model
###
Screen = module.exports.Screen = mongoose.model('Screen', screenSchema)
