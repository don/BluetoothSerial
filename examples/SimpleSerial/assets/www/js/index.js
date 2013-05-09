/*
    SimpleSerial index.js
    Created 7 May 2013
    Modified 9 May 2013
    by Tom Igoe
*/


var bluetoothSerial = cordova.require('bluetoothSerial');

var app = {
    macAddress: "AA:BB:CC:DD:EE:FF",  // get your mac address from bluetoothSerial.list
    chars: "",

/*
    Application constructor
 */
    initialize: function() {
        this.bindEvents();
        console.log("Starting SimpleSerial app");
    },
/*
    bind any events that are required on startup to listeners:
*/
    bindEvents: function() {
        document.addEventListener('deviceready', this.onDeviceReady, false);
        connectButton.addEventListener('touchend', app.manageConnection, false);
    },

/*
    this runs when the device is ready for user interaction:
*/
    onDeviceReady: function() {
        // Bluetooth Connect
        bluetoothSerial.list(
            function(results) {
                app.display(JSON.stringify(results));
            },
            function(error) {
                app.display(JSON.stringify(error));
            }
        );
    },
/*
    Connects if not connected, and disconnects if connected:
*/
    manageConnection: function() {
        app.display("I heard you");
        bluetoothSerial.isConnected (
            function() {
                // if not connected, do this:
                // clear the screen and display an attempt to connect
                app.clear();
                app.display("Attempting to connect. " +
                    "Make sure the serial port is open on the target device.");
                // attempt to connect:
                bluetoothSerial.connect(
                    app.macAddress,  // device to connect to
                    app.openPort,    // start listening if you succeed
                    app.showError    // show the error if you fail
                );
            },
            function () {
                console.log("attempting to disconnect");
                // if connected, do this:
                bluetoothSerial.disconnect(
                    app.closePort,     // stop listening to the port
                    app.showError      // show the error if you fail
                );
            }
        )
    },
/*
    subscribes to a Bluetooth serial listener for newline
    and changes the button:
*/
    openPort: function() {
        // if you get a good Bluetooth serial connection:
        app.display("Connected to: " + app.macAddress);
        // change the button's name:
        connectButton.innerHTML = "Disconnect";
        // set up a listener to listen for newlines
        // and display any new data that's come in since
        // the last newline:
        bluetoothSerial.subscribe('\n', function (data) {
            app.clear();
            app.display(data);
        });
    },

/*
    unsubscribes from any Bluetooth serial listener and changes the button:
*/
    closePort: function() {
        // if you get a good Bluetooth serial connection:
        app.display("Disconnected from: " + app.macAddress);
        // change the button's name:
        connectButton.innerHTML = "Connect";
        // unsubscribe from listening:
        bluetoothSerial.unsubscribe(
                function (data) {
                    app.display(data);
                },
                app.showError
        );
    },
/*
    appends @error to the message div:
*/
    showError: function(error) {
        app.display(error);
    },

/*
    appends @message to the message div:
*/
    display: function(message) {
        var display = document.getElementById("message"), // the message div
            lineBreak = document.createElement("br"),     // a line break
            label = document.createTextNode(message);     // create the label

        display.appendChild(lineBreak);          // add a line break
        display.appendChild(label);              // add the message node
    },
/*
    clears the message div:
*/
    clear: function() {
        var display = document.getElementById("message");
        display.innerHTML = "";
    }
};      // end of app

