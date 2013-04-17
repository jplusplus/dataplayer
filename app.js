
/**
 * Module dependencies.
 */

var express = require('express')
       , md = require("marked")
       , fs = require('fs')
     , http = require('http')
     , path = require('path');

var app = express();

app.configure(function(){
  
  app.set('port', process.env.PORT || 3000);
  app.set('data',  __dirname + '/data');
  app.set('pages', __dirname + '/pages');
  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');
  
  app.use(express.logger('dev'));
  app.use(express.bodyParser());
  app.use(express.methodOverride());

  app.use(require('connect-assets')({
    src: __dirname+'/public'    
  }));

  app.use(express.static(path.join(__dirname, 'public')));

  app.use(function(req, res, next) {
    res.locals.path = req.path;
    next();
  });



  /************************************
   * Views helpers
   ************************************/   
  // Register helpers for use in view's
  app.locals({  
    NODE_ENV: process.env.NODE_ENV,  
    screenStyle: function(data) { 

      var toPx = function(val) {
        return isNaN(val) ? val : val + "px";
      };

      var style = [];   
      // Add size
      if(data.width) {
        style.push("width:"  + toPx(data.width) );      
        style.push("margin-left:"  + toPx(data.width/-2) );      
      }

      if(data.height) {
        style.push("height:" + toPx(data.height) );
        style.push("margin-top:"  + toPx(data.height/-2) );   
      }

      return style.join(";");
    },
    stepStyle: function(step) {
      var style = [];
      // Add style
      if(step.style) style.push(step.style)

      return style.join(";");
    },
    spotStyle: function(spot) {

      var toPx = function(val) {
        return isNaN(val) ? val : val + "px";
      };
      
      var style = [];
      // Add position
      style.push("top:"  + toPx(spot.top  || 0) );
      style.push("left:" + toPx(spot.left || 0) );

      // Add size
      if(spot.width) style.push("width:"  + toPx(spot.width) );      
      if(spot.height) style.push("height:" + toPx(spot.height) );
      
      // Add style
      if(spot.style) style.push(spot.style)

      return style.join(";");
    },
    spotWrapperStyle: function(spot) {

      var style = [];
      // Add background
      if(spot.background) {
        style.push("background-image: url(" + spot.background + ")");        
      }
      // Add style
      if(spot.wrapperStyle) style.push(spot.wrapperStyle)

      return style.join(";");
    },
    spotClass: function(spot) {
      var klass = [];
      // Spot classes
      if(spot.class) klass.push(spot.class);
      return klass.join(" ");
    },
    stripTags: function(input, allowed) {
      if(!input) return "";
      // http://kevin.vanzonneveld.net
      allowed = (((allowed || "") + "").toLowerCase().match(/<[a-z][a-z0-9]*>/g) || []).join(''); // making sure the allowed arg is a string containing only tags in lowercase (<a><b><c>)
      var tags = /<\/?([a-z][a-z0-9]*)\b[^>]*>/gi,
        commentsAndPhpTags = /<!--[\s\S]*?-->|<\?(?:php)?[\s\S]*?\?>/gi;
      return input.replace(commentsAndPhpTags, '').replace(tags, function ($0, $1) {
        return allowed.indexOf('<' + $1.toLowerCase() + '>') > -1 ? $0 : '';
      });
    },
    getPage: function(name) {
      // Builds file name
      var fileName = path.join(app.get("pages"), name) + ".md";
      // Checks that file exists
      if(!fs.existsSync(fileName)) return "";
      // Read the text file
      var file = fs.readFileSync(fileName, "UTF-8");
      // Parse the markdown      
      return md(file)
    }
  });

  // Add context helpers
  app.use(function(req, res, next) {    
    res.locals.editMode  = req.query.hasOwnProperty("edit")
    res.locals.editToken = req.query["edit"]
    res.locals.publicURL = function(obj) {
      return req.protocol + "://" + req.headers.host + "/" + obj.slug
    }
    res.locals.privateURL = function(obj) {
      return res.locals.publicURL(obj) + "?edit=" + req.query["edit"]
    }
    next();
  });
  
  /************************************
   * Configure router      
   ************************************/   
  // @warning Needs to be after helpers
  app.use(app.router);
  // Load the default route file
  require("./routes")(app);

});

app.configure('development', function(){
  app.use(express.errorHandler());
});

http.createServer(app).listen(app.get('port'), function(){
  console.log("Express server listening on port " + app.get('port'));
});
