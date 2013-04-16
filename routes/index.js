// Dependencies
  var path = require('path')
      , fs = require('fs')
, mongoose = require('mongoose')
  , Screen = require('../models.js').Screen
    config = require("config");

// Module variables
var app;

module.exports = function(a){
  app = a;  
  // Connect mongoose
  mongoose.connect(process.env.DATABASE_URL || config.DATABASE_URL);
  // Set routes
  app.get("/create", createScreen);
  app.get("/:page", routePage);
  app.get("/:page/:step/:spot", editSpotPosition);
  app.post("/:page/content", updateContent);
  app.post("/:page/draft", updateDraft);
};


var routePage = function(req, res) {

    // Template file 
    var tplDir = "theme/"
     , tplName = req.params.page + "." + app.get("view engine")
     , tplPath = path.join(app.get("views"), tplDir, tplName );
    
    Screen.findOne({slug: req.params.page }, function(err, data) {
      if(err) return res.send(500);
      if(data == null || !data) return res.send(400, "Page not found.");
      // Preview mode, use the draft as data
      if(req.query.preview) data.content = data.draft || data.content;
      // Render the page template
      res.render(
          // Use the default template if needed 
          path.join( tplDir, fs.existsSync(tplPath) ? req.params.page : "default" ), 
          // Send the data to the template
          { obj: data }
      );   
    });     
};


var editSpotPosition = function(req, res) {

    var step = req.params.step,
        spot = req.params.spot; 
    
    // Forbidden in production!    
    if( process.env.NODE_ENV == "production") return res.send(403);    

    // Do we received the position ?
    if(!req.query.top || !req.query.left) return res.send(500);

    var dataDir = app.get("data")
     , dataName = req.params.page + ".json"
     , dataPath = path.join(dataDir, dataName)
         , data = require( dataPath );

    // Does the spot exist ?
    if(!data || !data[step] || !data[step].spots[spot]) return res.send(404);

    // Edit the data
    data[step].spots[spot].top  = req.query.top;
    data[step].spots[spot].left = req.query.left;

    var dataString = JSON.stringify(data, null, 4);
    // Mades it persistent
    fs.writeFile(dataPath, dataString);

    // Send the resut now
    res.send(200);
};

var updateContent = function(req, res) {    
  // JSON parsing to avoid inbject javascript
  var dataObject = JSON.parse(req.body.content);
  // Update the screen into the database
  Screen.update(
    { slug: req.params.page, token: req.body.token }, 
    { content: dataObject },
    function(err, data) {
      // Error during update
      if(err) res.send(500, "Impossible to update the page.");
      // Screen not found
      else if(data == null) res.send(400, "Page not found.");
      // OK
      else res.send(200);
    }
  );
};

var updateDraft = function(req, res) {    
  try {    
    // JSON parsing to avoid inbject javascript
    var dataObject = JSON.parse(req.body.content);
  } catch(e) {
    return res.send(500, "Invalid configuration.");
  }
  // Update the screen into the database
  Screen.update(
    { slug: req.params.page, token: req.body.token }, 
    { draft: dataObject},
    function(err, data) {
      // Error during update
      if(err) res.send(500, "Impossible to update the page.");
      // Screen not found
      else if(data == null) res.send(400, "Page not found.");
      // OK
      else res.send(200);
    }
  );
};

var createScreen = function(req, res) {

  // Create the screen object
  var s = new Screen({
    slug: randomString(5),
    token: randomString(10),
    created_at: new Date(),
    content: require("../data/sample.json"),
    draft: {}
  });

  // Save it to the databse
  s.save(function(err, data) {
    // Duplicate slug, try again
    if(err && err.code == 11000) return createScreen(req, res);
    // Other error
    else if(err) return res.send(500);    
    // Redirect to the new screen
    res.redirect("/" + data.slug + "?edit=" + data.token);
  });

};


var randomString = function(length) {
  var chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZabcdefghiklmnopqrstuvwxyz';
  length = length ? length : 32;  
  var string = '';
  for (var i = 0; i < length; i++) {
    var randomNumber = Math.floor(Math.random() * chars.length);
    string += chars.substring(randomNumber, randomNumber + 1);
  }
  
  return string;
}