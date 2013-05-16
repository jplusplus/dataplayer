mongoose = require("mongoose")
baucis   = require("baucis")
models   = require("../models")

###*
 * Only allow reading 
 * @param  {Object}   request  User request
 * @param  {Object}   response User response
 * @param  {Function} next     Callback
###
writeAuthentication = (request, response, next)->    
    return response.send(401) if request.method isnt 'GET'
    next()

module.exports = (app)->

    # Screen resource
    baucis.rest        
        all      : writeAuthentication
        findBy   : "slug"
        select   : "slug created_at author content"
        singular : "Screen"        
        restrict : (query, request)->
            # Populate the author field
            query.populate "author", "username"
            # Restrict to public screen 
            query.where("content.private", false)
            query.or().where("content.private",  $exists: false)

    # User resource
    baucis.rest 
        all      : writeAuthentication
        findBy   : "username"
        singular : "User",
        select   : "username screens"
        restrict : (query, request)->
            # Populate the screens field
            query.populate "screens"
        

    app.use "/api/v1", baucis()