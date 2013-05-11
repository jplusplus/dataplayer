config = require("config")
path   = require("path")
fs     = require("fs")
md     = require("marked")
_      = require("underscore")

module.exports = ->    


module.exports.locals = (app)->
     # Constant containing the node environment (development, production, etc)
    NODE_ENV: process.env.NODE_ENV
    ###*
     * Return the class of the overflow according descriptor
     * @param  {Object} data Screen descriptor
     * @return {String}      Overflow classes
    ###
    overflowClass: (data) ->
        klasses = data["menu-position"].split(" ")
        layout = data["layout"]      
        # For each class 
        for k of klasses        
            # Add a suffix
            klasses[k] = layout + "-" + klasses[k]

        klasses.push data.navigation || "horizontal"
        klasses.push data.layout || "default"
        klasses.push "scroll-allowed" if data.scroll

        klasses.join " "

    ###*
     * Return the class of the container according descriptor
     * @param  {Object} data Screen descriptor
     * @return {String}      Container classes
    ###
    containerClass: (data) ->
        return    

    ###*
     * Container context style
     * @param  {Object} data Screen descriptor
     * @return {String}      CSS style
    ###
    screenStyle: (data) ->
        toPx = (val) ->
            (if isNaN(val) then val else val + "px")

        style = []      
        # Add size
        style.push "width:" + toPx(data.width)  if data.width
        style.push "height:" + toPx(data.height)  if data.height
        style.join ";"

    ###*
     * Step context style
     * @param  {Object} data Step descriptor
     * @return {String}      CSS style
    ###
    stepStyle: (step) ->
        style = []      
        # Add style
        style.push step.style  if step.style
        style.join ";"

    ###*
     * Spot context style
     * @param  {Object} data Spot descriptor
     * @return {String}      CSS style
    ###
    spotStyle: (spot) ->
        toPx = (val) ->
            (if isNaN(val) then val else val + "px")

        style = []

        # Add position
        style.push "top:" + toPx(spot.top or 0)
        style.push "left:" + toPx(spot.left or 0)      
        # Add size
        style.push "width:" + toPx(spot.width)  if spot.width
        style.push "height:" + toPx(spot.height)  if spot.height      
        # Add style
        style.push spot.style  if spot.style
        style.join ";"

    ###*
     * Spot wrapper context style
     * @param  {Object} data Spot descriptor
     * @return {String}      CSS style
    ###
    spotWrapperStyle: (spot) ->
        style = []      
        # Add background
        style.push "background-image: url(" + spot.background + ")"  if spot.background      
        # Add style
        style.push spot.wrapperStyle  if spot.wrapperStyle
        style.join ";"

    ###*
     * Spot context classes
     * @param  {Object} data Spot descriptor
     * @return {String}      Classes
    ###
    spotClass: (spot) ->
        klass = []
        # Default type
        type = spot.type or "text"
        klass.push "type-#{type}"
        # Deactivate the background on demand      
        klass.push "no-bg" if spot["no-bg"]
        # Spot classes
        klass.push spot.class if spot.class
        klass.join " "

    ###*
     * Template helper to remove html tags (to plain text)
     * @copyright http://kevin.vanzonneveld.net
     * @param  {String} input   HTML to escape
     * @param  {String} allowed  Allowed tags (ex: <a><b><em>)
     * @return {String}         Input string as plain text
    ###
    stripTags: stripTags


module.exports.context = (req, res, next) ->
    # Current user
    res.locals.user = if req.isAuthenticated() then req.user else false
    res.locals.path = req.path
    res.locals.publicURL = (obj) ->
        req.protocol + "://" + req.headers.host + "/" + obj.slug
    res.locals.privateURL = (obj) ->
        res.locals.publicURL(obj) + "?edit=" + obj.token

    # Login/Signup form everywhere
    res.locals.errorLogin = req.flash("errorLogin")
    res.locals.errorSignup = req.flash("errorSignup")
    res.locals.tmpUser = req.flash("tmpUser")

    next()

###*
 * Template helper to remove html tags (to plain text)
 * @copyright http://kevin.vanzonneveld.net
 * @param  {String} input   HTML to escape
 * @param  {String} allowed Allowed tags (ex: <a><b><em>)
 * @return {String}         Input string as plain text
###
stripTags = module.exports.stripTags = (input, allowed=config['allowed-tags']) ->
    return "" unless input      
    allowed = (((allowed or "") + "").toLowerCase().match(/<[a-z][a-z0-9]*>/g) or []).join("") # making sure the allowed arg is a string containing only tags in lowercase (<a><b><c>)
    tags = /<\/?([a-z][a-z0-9]*)\b[^>]*>/g
    commentsAndPhpTags = /<!--[\s\S]*?-->|<\?(?:php)?[\s\S]*?\?>/g
    input.replace(commentsAndPhpTags, "").replace tags, ($0, $1) ->
        (if allowed.indexOf("<" + $1.toLowerCase() + ">") > -1 then $0 else "")

###*
 * Simple function to generate a random string with the given length
 * @param  {Number} length Length of the random String
 * @return {String}        Random string
###
randomString = module.exports.randomString = (length) ->
    chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZabcdefghiklmnopqrstuvwxyz"
    length = (if length then length else 32)
    string = ""
    i = 0

    while i < length
        randomNumber = Math.floor(Math.random() * chars.length)
        string += chars.substring(randomNumber, randomNumber + 1)
        i++
    string

sanitaze = module.exports.sanitaze = (obj, depth=5) ->
    # Reduce the depth left
    --depth
    # Apply a different function according the field type
    for key, o of obj
        type = typeof(o)
        # Escape the strings
        if type == "string" then obj[key] = stripTags o
        # Just copy the number
        else if type == "number" then obj[key] = o
        # Boolean
        else if type == "boolean" then obj[key] = o
        # Reccurcive call with a depth check to avoid infinite call
        else if depth > 0 then sanitaze obj[key], depth
        # Unknow situation, return null
        else obj[key] = null

    obj        


###*
 * True if the given email is valid
 * @param  {String}  email Email to test
 * @return {Boolean}       True if the email is valid
###
isValidEmail = module.exports.isValidEmail = (email) ->  
  # Source:
  # http://fightingforalostcause.net/misc/2006/compare-email-regex.php
  reg = /^[-a-z0-9~!$%^&*_=+}{\'?]+(\.[-a-z0-9~!$%^&*_=+}{\'?]+)*@([a-z0-9_][-a-z0-9_]*(\.[-a-z0-9_]+)*\.(aero|arpa|biz|com|coop|edu|gov|info|int|mil|museum|name|net|org|pro|travel|mobi|[a-z][a-z])|([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}))(:[0-9]{1,5})?$/i
  reg.test email