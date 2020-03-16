/*global cordova*/
module.exports = {
    isEnabled: function(success, failure) {
        cordova.exec(success, failure, "BluetoothSerial", "isEnabled", []);
    },

    enable: function(success, failure) {
        cordova.exec(success, failure, "BluetoothSerial", "enable", []);
    },

    connect: function (macAddress, success, failure) {
        cordova.exec(success, failure, "BluetoothSerial", "connect", [macAddress]);
    },

    disconnect: function (success, failure) {
        cordova.exec(success, failure, "BluetoothSerial", "disconnect", []);
    },

    // writes data to the bluetooth serial port
    // data can be an ArrayBuffer, string, integer array, or Uint8Array
    send: function (data, success, failure) {

        // convert to ArrayBuffer
        if (typeof data === 'string') {
            data = stringToArrayBuffer(data);
        } else if (data instanceof Array) {
            // assuming array of interger
            data = new Uint8Array(data).buffer;
        } else if (data instanceof Uint8Array) {
            data = data.buffer;
        }

        cordova.exec(success, failure, "BluetoothSerial", "send", [data]);
    },

    // calls the success callback when new data is available with an ArrayBuffer
    listen: function (success, failure) {
        cordova.exec(success, failure, "BluetoothSerial", "listen", []);
    },

    getAddress: function (success, failure) {
        cordova.exec(success, failure, "BluetoothSerial", "getAddress", []);
    },

    registerOnDataCallback: function (success) {
        cordova.exec(success, null, "BluetoothSerial", "registerDataCallback", []);
    },

    registerOnConnectCallback: function (success) {
        cordova.exec(success, null, "BluetoothSerial", "registerConnectCallback", []);
    },

    registerOnCloseCallback: function (success) {
        cordova.exec(success, null, "BluetoothSerial", "registerCloseCallback", []);
    }
};

var stringToArrayBuffer = function(str) {
    var ret = new Uint8Array(str.length);
    for (var i = 0; i < str.length; i++) {
        ret[i] = str.charCodeAt(i);
    }
    return ret.buffer;
};