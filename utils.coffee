config = require("config")
_      = require("underscore")

module.exports = ->    


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
        # Reccurcive call with a depth check to avoid infinite call
        else if depth > 0 then sanitaze obj[key], depth
        # Unknow situation, return null
        else obj[key] = null

    obj        