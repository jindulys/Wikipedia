(function (module) {

function Bridge() {
}

var eventHandlers = {};

Bridge.prototype.handleMessage = function( type, payload ) {
    var that = this;
    if ( eventHandlers.hasOwnProperty( type ) ) {
        eventHandlers[type].forEach( function( callback ) {
                                    callback.call( that, payload );
                                    } );
    }
};

Bridge.prototype.registerListener = function( messageType, callback ) {
    if ( eventHandlers.hasOwnProperty( messageType ) ) {
        eventHandlers[messageType].push( callback );
    } else {
        eventHandlers[messageType] = [ callback ];
    }
};

Bridge.prototype.sendMessage = function( messageType, payload ) {
    setTimeout(function() { // See: https://phabricator.wikimedia.org/T96822 and http://stackoverflow.com/a/9782220/135557
        var messagePack = { type: messageType, payload: payload };
        var url = "x-wikipedia-bridge:" + encodeURIComponent( JSON.stringify( messagePack ) );

        // quick iframe version based on http://stackoverflow.com/a/6508343/82439
        // fixme can this be an XHR instead? check Cordova current state
        var iframe = document.createElement('iframe');
        iframe.setAttribute("src", url);
        document.documentElement.appendChild(iframe);
        iframe.parentNode.removeChild(iframe);
        iframe = null;
    }, 0);
};

module.exports = new Bridge();

})(module);
