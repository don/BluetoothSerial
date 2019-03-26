// This implementation is for testing in the brower. Future implemetations *might* be able to use
// Chrome Bluetooth APIs https://developer.chrome.com/apps/bluetooth or Web Bluetooth.

// Code from PhracturedBlue https://github.com/don/BluetoothSerial/issues/115

// When using the browser, it is necessary to have a processing function that
// can emulate the bluetooth device.

// Use the 'register' function as follows:
//
// bluetoothSerial.register(function(buf) {
//      //buf.input is the data that was received via bluetoothSerial.write
//      //buf.output is data that will be transmitted via a bluetoothSerial.read or subscribe
//      //Do processing here
//      buf.input = ""
// });

// Function emulates a Bluetooth device echoing back input
//
// var echoProxy = function(buf) {
//   if (buf && buf.input) {
//     console.log("Received: " + buf.input);
//     buf.output = buf.input + "\n";
//     buf.input = ""; // clear input
//   }
//   return buf;
// }
// bluetoothSerial.register(echoProxy);

module.exports = (function() {
    var connected = false;
    var enabled = true;
    var buf = {
        input: "",
        output: "",
        };
    var subscribe_cb = function(value) {};
    var raw_cb = false;
    var subscribe_delim = false;
    var interval;
    var process_cb;

    var btlog = function(str) { console.log(str); }
    var timer_cb = function() {
        if(process_cb) {
            process_cb(buf);
        }
        if (buf.output.length) {
            if(subscribe_delim) {
                var index = buf.output.indexOf(subscribe_delim);
                if (index > -1) {
                    var data = buf.output.substr(0, index+subscribe_delim.length);
                    buf.output = buf.output.substr(index+subscribe_delim.length);
                    subscribe_cb(data);
                }
            }
        }
    };
    return {
        connect : function(mac, success_cb, fail_cb) {
            btlog("bluetoothSerial.connect: " + mac);
            connected = true;
            if (success_cb) { success_cb(); }
        },
        register : function(data_cb) {
            interval = window.setInterval(timer_cb, 100);
            process_cb = data_cb;
        },
        disconnect : function(success_cb, fail_cb) {
            btlog("bluetoothSerial.disconnect");
            connected = false;
            window.clearInterval(interval);
            if (success_cb) { success_cb(); }
        },
        write : function(data, success_cb, fail_cb) {
            btlog("bluetoothSerial.write: " + data);
            buf.input += data;
            if(success_cb) { success_cb(); }
        },
        available : function(success_cb, fail_cb) {
            btlog("bluetoothSerial.available");
            success_cb(buf.output.length);
        },
        read : function(success_cb, fail_cb) {
            btlog("bluetoothSerial.read: " + buf.output);
            var data = buf.output;
            buf.output = "";
            success_cb(data);
        },
        readUntil : function(delimiter, success_cb, fail_cb) {
            btlog("bluetoothSerial.readUntil");
            var index = buf.output.indexOf(delimiter);
            if (index == -1) {
                success_cb("");
            } else {
                var data = buf.output.substr(0, index+subscribe_delim.length);
                buf.output = buf.output.substr(index+subscribe_delim.length);
                success_cb(data);
            }
        },
        subscribe : function(delimiter, success_cb, fail_cb) {
            btlog("bluetoothSerial.subscribe '"+delimiter+"'");
            subscribe_cb = success_cb;
            subscribe_delim = delimiter;
        },
        unsubscribe : function(success_cb, fail_cb) {
            btlog("bluetoothSerial.unsubscribe");
            subscribe_delim = false;
            if(success_cb) { success_cb(); }
        },
        subscribeRawData : function(success_cb, fail_cb) {
            btlog("bluetoothSerial.subscribeRawData");
            raw_cb = success_cb;
        },
        unsubscribeRawData : function(success_cb, fail_cb) {
            btlog("bluetoothSerial.unsubscribeRawData");
            raw_cb = false;
            if(success_cb) { success_cb(); }
        },
        clear : function(success_cb, fail_cb) {
            btlog("bluetoothSerial.clear");
            buf.output = "";
            if(success_cb) { success_cb(); }
        },
        list : function(success_cb, fail_cb) {
          var devices = [{
              "class": 276,
              "id": "10:BF:48:CB:00:00",
              "address": "10:BF:48:CB:00:00",
              "name": "Nexus 7"
          }, {
              "class": 7936,
              "id": "00:06:66:4D:00:00",
              "address": "00:06:66:4D:00:00",
              "name": "RN42"
          }]
          success_cb(devices);        },
        isConnected : function(success_cb, fail_cb) {
            btlog("bluetoothSerial.isConnected: " + connected);
            if(connected) {
                if(success_cb) { success_cb(); }
            } else {
                if(fail_cb) { fail_cb(); }
            }
        },
        isEnabled : function(success_cb, fail_cb) {
            btlog("bluetoothSerial.isEnabled: " + enabled);
            if(enabled) {
                if(success_cb) { success_cb(); }
            } else {
                if(fail_cb) { fail_cb(); }
            }
        },
        readRSSI : function(success_cb, fail_cb) {
            alert("bluetoothSerial.readRSSI is not implemented");
        },
        showBluetoothSettings : function(success_cb, fail_cb) {
            alert("bluetoothSerial.showBluetoothSettings is not implemented");
        },
        enable : function(success_cb, fail_cb) {
            btlog("bluetoothSerial.enable");
            enable = true;
            if(success_cb) { success_cb(); }
        },
        discoverUnpaired : function(success_cb, fail_cb) {
            alert("bluetoothSerial.discoverUnpaired is not implemented");
        },
    }
})();
