// Dependencies
var path = require('path')
    , fs = require('fs');

// Module variables
var app;

module.exports = function(a){
  app = a;  
  app.get("/:page.html", routePage);
  app.get("/:page/:step/:spot", editSpotPosition);
  app.post("/:page/save", saveJson);
};


var routePage = function(req, res) {

    // Template file 
    var tplDir = app.get("page")
     , tplName = req.params.page + "." + app.get("view engine")
     , dataDir = app.get("data")
    , dataName = req.params.page + ".json";

    // Template file path
    var  tpl = path.join(app.get("views"), tplDir, tplName );
    // Data file path
    var data = path.join(dataDir, dataName);

    // Do the data file exist ?
    if(! fs.existsSync(data)  ) return res.send(404, "Data file not found.");
    
    // Render the page template
    res.render(
        path.join(
            tplDir,
            // Use the default template if needed 
            fs.existsSync(tpl) ? req.params.page : "default"
        ), 
        { 
            data: require(data), 
            page: req.params.page 
        }
    );        
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

var saveJson = function(req, res) {

    // JSON parsing/sringify to avoid inbject javascript
    var dataObject = JSON.parse(req.body.config),
        dataPlain  = JSON.stringify(dataObject, null, 4);

    var dataDir = app.get("data")
     , dataName = req.params.page + ".json"
     , dataPath = path.join(dataDir, dataName);

    // Purge the require cache
    if(require.cache[dataPath]) require.cache[dataPath] = false;
    // Mades it persistent
    fs.writeFile(dataPath, dataPlain);    
    // Send the resut now
    res.send(200);
};