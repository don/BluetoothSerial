/*global cordova*/
module.exports = {

    version: '0.9.8',

    connect: function (deviceId, interfaceArray, success, failure) {

      if (typeof interfaceArray === 'string') {
        interfaceArray = [interfaceArray];
      }

        cordova.exec(success, failure, "BluetoothClassicSerial", "connect", [deviceId, interfaceArray]);
    },

    // Android only - see http://goo.gl/1mFjZY
    connectInsecure: function (deviceId, interfaceArray, success, failure) {

        if (typeof interfaceArray === 'string') {
          interfaceArray = [interfaceArray];
        }

        cordova.exec(success, failure, "BluetoothClassicSerial", "connectInsecure", [deviceId, interfaceArray]);
    },

    disconnect: function (success, failure) {
        cordova.exec(success, failure, "BluetoothClassicSerial", "disconnect", []);
    },

    // list bound devices
    list: function (success, failure) {
        cordova.exec(success, failure, "BluetoothClassicSerial", "list", []);
    },

    isEnabled: function (success, failure) {
        cordova.exec(success, failure, "BluetoothClassicSerial", "isEnabled", []);
    },

    isConnected: function (success, failure) {
        cordova.exec(success, failure, "BluetoothClassicSerial", "isConnected", []);
    },

    // the number of bytes of data available to read is passed to the success function
    available: function (interfaceId, success, failure) {
        cordova.exec(success, failure, "BluetoothClassicSerial", "available", [interfaceId]);
    },

    // read all the data in the buffer
    read: function (interfaceId, success, failure) {
        cordova.exec(success, failure, "BluetoothClassicSerial", "read", [interfaceId]);
    },

    // reads the data in the buffer up to and including the delimiter
    readUntil: function (interfaceId, delimiter, success, failure) {
        cordova.exec(success, failure, "BluetoothClassicSerial", "readUntil", [interfaceId, delimiter]);
    },

    // writes data to the bluetooth serial port
    // data can be an ArrayBuffer, string, integer array, or Uint8Array
    write: function (interfaceId, data, success, failure) {

        // convert to ArrayBuffer
        if (typeof data === 'string') {
            data = stringToArrayBuffer(data);
        } else if (data instanceof Array) {
            // assuming array of interger
            data = new Uint8Array(data).buffer;
        } else if (data instanceof Uint8Array) {
            data = data.buffer;
        }

        cordova.exec(success, failure, "BluetoothClassicSerial", "write", [interfaceId, data]);
    },

    // calls the success callback when new data is available
    subscribe: function (interfaceId, delimiter, success, failure) {
        cordova.exec(success, failure, "BluetoothClassicSerial", "subscribe", [interfaceId, delimiter]);
    },

    // removes data subscription
    unsubscribe: function (interfaceId, success, failure) {
        cordova.exec(success, failure, "BluetoothClassicSerial", "unsubscribe", [interfaceId]);
    },

    // calls the success callback when new data is available with an ArrayBuffer
    subscribeRawData: function (interfaceId,success, failure) {

        successWrapper = function(data) {

          // data = (typeof data === 'object') ? data : {};
          //
          // if (typeof data.rawDataB64 === 'string') {
          //   data.rawData = toByteArray(data.rawDataB64);
          // }

          success(data);
        };

        cordova.exec(successWrapper, failure, "BluetoothClassicSerial", "subscribeRaw", [interfaceId]);
    },

    // removes data subscription
    unsubscribeRawData: function (interfaceId, success, failure) {
        cordova.exec(success, failure, "BluetoothClassicSerial", "unsubscribeRaw", [interfaceId]);
    },

    // clears the data buffer
    clear: function (interfaceId, success, failure) {
        cordova.exec(success, failure, "BluetoothClassicSerial", "clear", [interfaceId]);
    },

    showBluetoothSettings: function (success, failure) {
        cordova.exec(success, failure, "BluetoothClassicSerial", "showBluetoothSettings", []);
    },

    enable: function (success, failure) {
        cordova.exec(success, failure, "BluetoothClassicSerial", "enable", []);
    },

    discoverUnpaired: function (success, failure) {
        cordova.exec(success, failure, "BluetoothClassicSerial", "discoverUnpaired", []);
    },

    setDeviceDiscoveredListener: function (notify) {
        if (typeof notify != 'function')
            throw 'BluetoothClassicSerial.setDeviceDiscoveredListener: Callback not a function';

        cordova.exec(notify, null, "BluetoothClassicSerial", "setDeviceDiscoveredListener", []);
    },

    clearDeviceDiscoveredListener: function () {
        cordova.exec(null, null, "BluetoothClassicSerial", "clearDeviceDiscoveredListener", []);
    }

};

var stringToArrayBuffer = function(str) {
    var ret = new Uint8Array(str.length);
    for (var i = 0; i < str.length; i++) {
        ret[i] = str.charCodeAt(i);
    }
    return ret.buffer;
};
