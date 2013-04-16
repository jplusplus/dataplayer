var mongoose = require('mongoose');

module.exports = function() {
    return module.exports;
};

/**
 * Screen model
 * @type {Object}
 */
module.exports.Screen = mongoose.model('Screen', { 
    slug: { type: String, index: { unique: true } },
    token: String,
    content: mongoose.Schema.Types.Mixed,
    draft: mongoose.Schema.Types.Mixed,
    created_at: Date
});
