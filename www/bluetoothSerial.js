/*global cordova*/
module.exports = {

    connect: function (macAddress, success, failure) {
        cordova.exec(success, failure, "BluetoothSerial", "connect", [macAddress]);
    },

    // Android only - see http://goo.gl/1mFjZY
    connectInsecure: function (macAddress, success, failure) {
        cordova.exec(success, failure, "BluetoothSerial", "connectInsecure", [macAddress]);
    },

    disconnect: function (success, failure,macAddress) {
		macAddress = typeof macAddress !== 'undefined' ? macAddress : null;
        cordova.exec(success, failure, "BluetoothSerial", "disconnect", [macAddress]);
    },

    // list bound devices
    list: function (success, failure) {
        cordova.exec(success, failure, "BluetoothSerial", "list", []);
    },

    isEnabled: function (success, failure) {
        cordova.exec(success, failure, "BluetoothSerial", "isEnabled", []);
    },

    isConnected: function (success, failure,macAddress) {
		macAddress = typeof macAddress !== 'undefined' ? macAddress : null;
        cordova.exec(success, failure, "BluetoothSerial", "isConnected", [macAddress]);
    },

    // the number of bytes of data available to read is passed to the success function
    available: function (success, failure,macAddress) {
		macAddress = typeof macAddress !== 'undefined' ? macAddress : null;
        cordova.exec(success, failure, "BluetoothSerial", "available", [macAddress]);
    },

    // read all the data in the buffer
    read: function (success, failure,macAddress) {
		macAddress = typeof macAddress !== 'undefined' ? macAddress : null;
        cordova.exec(success, failure, "BluetoothSerial", "read", [macAddress]);
    },

    // reads the data in the buffer up to and including the delimiter
    readUntil: function (delimiter, success, failure,macAddress) {
		macAddress = typeof macAddress !== 'undefined' ? macAddress : null;
        cordova.exec(success, failure, "BluetoothSerial", "readUntil", [delimiter,macAddress]);
    },

    // writes data to the bluetooth serial port
    // data can be an ArrayBuffer, string, integer array, or Uint8Array
    write: function (data, success, failure,macAddress) {
		macAddress = typeof macAddress !== 'undefined' ? macAddress : null;

        // convert to ArrayBuffer
        if (typeof data === 'string') {
            data = stringToArrayBuffer(data);
        } else if (data instanceof Array) {
            // assuming array of interger
            data = new Uint8Array(data).buffer;
        } else if (data instanceof Uint8Array) {
            data = data.buffer;
        }

        cordova.exec(success, failure, "BluetoothSerial", "write", [data,macAddress]);
    },

    // calls the success callback when new data is available
    subscribe: function (delimiter, success, failure,macAddress) {
		macAddress = typeof macAddress !== 'undefined' ? macAddress : null;
        cordova.exec(success, failure, "BluetoothSerial", "subscribe", [delimiter,macAddress]);
    },

    // removes data subscription
    unsubscribe: function (success, failure,macAddress) {
		macAddress = typeof macAddress !== 'undefined' ? macAddress : null;
        cordova.exec(success, failure, "BluetoothSerial", "unsubscribe", [macAddress]);
    },

    // calls the success callback when new data is available with an ArrayBuffer
    subscribeRawData: function (success, failure,macAddress) {
		macAddress = typeof macAddress !== 'undefined' ? macAddress : null;

        successWrapper = function(data) {
            // Windows Phone flattens an array of one into a number which
            // breaks the API. Stuff it back into an ArrayBuffer.
            if (typeof data === 'number') {
                var a = new Uint8Array(1);
                a[0] = data;
                data = a.buffer;
            }
            success(data);
        };
        cordova.exec(successWrapper, failure, "BluetoothSerial", "subscribeRaw", [macAddress]);
    },

    // removes data subscription
    unsubscribeRawData: function (success, failure,macAddress) {
		macAddress = typeof macAddress !== 'undefined' ? macAddress : null;
        cordova.exec(success, failure, "BluetoothSerial", "unsubscribeRaw", [macAddress]);
    },

    // clears the data buffer
    clear: function (success, failure,macAddress) {
		macAddress = typeof macAddress !== 'undefined' ? macAddress : null;
        cordova.exec(success, failure, "BluetoothSerial", "clear", [macAddress]);
    },

    // reads the RSSI of the *connected* peripherial
    readRSSI: function (success, failure,macAddress) {
		macAddress = typeof macAddress !== 'undefined' ? macAddress : null;
        cordova.exec(success, failure, "BluetoothSerial", "readRSSI", [macAddress]);
    },

    showBluetoothSettings: function (success, failure) {
        cordova.exec(success, failure, "BluetoothSerial", "showBluetoothSettings", []);
    },

    enable: function (success, failure) {
        cordova.exec(success, failure, "BluetoothSerial", "enable", []);
    },

    discoverUnpaired: function (success, failure) {
        cordova.exec(success, failure, "BluetoothSerial", "discoverUnpaired", []);
    },

    setDeviceDiscoveredListener: function (notify) {
        if (typeof notify != 'function')
            throw 'BluetoothSerial.setDeviceDiscoveredListener: Callback not a function';

        cordova.exec(notify, null, "BluetoothSerial", "setDeviceDiscoveredListener", []);
    },

    clearDeviceDiscoveredListener: function () {
        cordova.exec(null, null, "BluetoothSerial", "clearDeviceDiscoveredListener", []);
    },

    setName: function (newName) {
        cordova.exec(null, null, "BluetoothSerial", "setName", [newName]);
    },

    setDiscoverable: function (discoverableDuration) {
        cordova.exec(null, null, "BluetoothSerial", "setDiscoverable", [discoverableDuration]);
    }


};

var stringToArrayBuffer = function(str) {
    var ret = new Uint8Array(str.length);
    for (var i = 0; i < str.length; i++) {
        ret[i] = str.charCodeAt(i);
    }
    return ret.buffer;
};
