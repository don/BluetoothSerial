/*global cordova*/
module.exports = {

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
//
// // Byte Decode
//
// 'use strict'
//
// exports.toByteArray = toByteArray
// exports.fromByteArray = fromByteArray
//
// var lookup = []
// var revLookup = []
// var Arr = typeof Uint8Array !== 'undefined' ? Uint8Array : Array
//
// function init () {
//   var code = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
//   for (var i = 0, len = code.length; i < len; ++i) {
//     lookup[i] = code[i]
//     revLookup[code.charCodeAt(i)] = i
//   }
//
//   revLookup['-'.charCodeAt(0)] = 62
//   revLookup['_'.charCodeAt(0)] = 63
// }
//
// init()
//
// function toByteArray (b64) {
//   var i, j, l, tmp, placeHolders, arr
//   var len = b64.length
//
//   if (len % 4 > 0) {
//     throw new Error('Invalid string. Length must be a multiple of 4')
//   }
//
//   // the number of equal signs (place holders)
//   // if there are two placeholders, than the two characters before it
//   // represent one byte
//   // if there is only one, then the three characters before it represent 2 bytes
//   // this is just a cheap hack to not do indexOf twice
//   placeHolders = b64[len - 2] === '=' ? 2 : b64[len - 1] === '=' ? 1 : 0
//
//   // base64 is 4/3 + up to two characters of the original data
//   arr = new Arr(len * 3 / 4 - placeHolders)
//
//   // if there are placeholders, only get up to the last complete 4 chars
//   l = placeHolders > 0 ? len - 4 : len
//
//   var L = 0
//
//   for (i = 0, j = 0; i < l; i += 4, j += 3) {
//     tmp = (revLookup[b64.charCodeAt(i)] << 18) | (revLookup[b64.charCodeAt(i + 1)] << 12) | (revLookup[b64.charCodeAt(i + 2)] << 6) | revLookup[b64.charCodeAt(i + 3)]
//     arr[L++] = (tmp >> 16) & 0xFF
//     arr[L++] = (tmp >> 8) & 0xFF
//     arr[L++] = tmp & 0xFF
//   }
//
//   if (placeHolders === 2) {
//     tmp = (revLookup[b64.charCodeAt(i)] << 2) | (revLookup[b64.charCodeAt(i + 1)] >> 4)
//     arr[L++] = tmp & 0xFF
//   } else if (placeHolders === 1) {
//     tmp = (revLookup[b64.charCodeAt(i)] << 10) | (revLookup[b64.charCodeAt(i + 1)] << 4) | (revLookup[b64.charCodeAt(i + 2)] >> 2)
//     arr[L++] = (tmp >> 8) & 0xFF
//     arr[L++] = tmp & 0xFF
//   }
//
//   return arr
// }
//
// function tripletToBase64 (num) {
//   return lookup[num >> 18 & 0x3F] + lookup[num >> 12 & 0x3F] + lookup[num >> 6 & 0x3F] + lookup[num & 0x3F]
// }
//
// function encodeChunk (uint8, start, end) {
//   var tmp
//   var output = []
//   for (var i = start; i < end; i += 3) {
//     tmp = (uint8[i] << 16) + (uint8[i + 1] << 8) + (uint8[i + 2])
//     output.push(tripletToBase64(tmp))
//   }
//   return output.join('')
// }
//
// function fromByteArray (uint8) {
//   var tmp
//   var len = uint8.length
//   var extraBytes = len % 3 // if we have 1 byte left, pad 2 bytes
//   var output = ''
//   var parts = []
//   var maxChunkLength = 16383 // must be multiple of 3
//
//   // go through the array every three bytes, we'll deal with trailing stuff later
//   for (var i = 0, len2 = len - extraBytes; i < len2; i += maxChunkLength) {
//     parts.push(encodeChunk(uint8, i, (i + maxChunkLength) > len2 ? len2 : (i + maxChunkLength)))
//   }
//
//   // pad the end with zeros, but make sure to not forget the extra bytes
//   if (extraBytes === 1) {
//     tmp = uint8[len - 1]
//     output += lookup[tmp >> 2]
//     output += lookup[(tmp << 4) & 0x3F]
//     output += '=='
//   } else if (extraBytes === 2) {
//     tmp = (uint8[len - 2] << 8) + (uint8[len - 1])
//     output += lookup[tmp >> 10]
//     output += lookup[(tmp >> 4) & 0x3F]
//     output += lookup[(tmp << 2) & 0x3F]
//     output += '='
//   }
//
//   parts.push(output)
//
//   return parts.join('')
// }
