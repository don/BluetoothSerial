# Bluetooth Classic Serial Plugin for Cordova

This plugin enables serial communication over Bluetooth. It is a fork of https://github.com/don/BluetoothSerial.  The core difference is that https://github.com/don/BluetoothSerial supports Bluetooth Low Energy on iOS.  This plugin is written using the iOS Accessory Framework (MFi) to support Classic Bluetooth on iOS.  Windows Phone 8 Support has been removed in the fork.

* **Beta Release**
* **Breaking API Changes from version 0.9.5 'MultiInterface'**

## Supported Platforms

* Android
* iOS (devices must be MFi certified)
* Browser (Testing only. See [comments](https://github.com/don/BluetoothSerial/blob/master/src/browser/bluetoothSerial.js).)

## Limitations

 * The phone must initiate the Bluetooth connection
 * Will *not* connect Android to Android (https://github.com/don/BluetoothSerial/issues/50#issuecomment-66405396)
 * Will *not* connect iOS to iOS
 * Android Target SDK must be 22 or less.  New Permission model for SDK 23 (Android 6.0) not yet implemented
 * Does not connect to multiple devices, however with 0.9.5 and above multiple interfaces (serial ports) on the same device are supported.

# Installing

Install with Cordova cli

    $ cordova plugin add cordova-plugin-bluetoothClassic-serial

Note that this plugin's id changed from 'cordova-plugin-bluetooth-serial' to 'cordova-plugin-bluetoothClassic-serial' as part of the fork.

## iOS Notes

iOS requires that the device's protocol string is in the p-list.  This plugin has a dependency on [cordova-custom-config](https://github.com/dpa99c/cordova-custom-config) which enables plist entries to be created from entries the application's cordova config.xml file.

The Phonegap Build service doesn't use this plugin, and instead appears to have it's own method for passing entries into the iOS plist.  Examples below.

### Examples

Replace the text 'first.device.protocol.string' with the protocol string for the Bluetooth accessory you are connecting to. Create a new line for each protocol string.  Some devices may have more than one.  The plugin only allows for connection to one device and one protocol.  If you need to connect to another, disconnect, then connect to the required device and protocol.

#### Cordova Command Line config.xml entry for Supported Accessories

```xml
<platform name="ios">
    <config-file target="*-Info.plist" parent="UISupportedExternalAccessoryProtocols">
        <array>
            <string>first.device.protocol.string</string>
            <string>second.device.protocol.string</string>
         </array>
    </config-file>
</platform>
```

#### Phonegap Build config.xml entry for Supported Accessories

```xml
<config-file platform="ios" parent="UISupportedExternalAccessoryProtocols">
    <array>
        <string>first.device.protocol.string</string>
         <string>second.device.protocol.string</string>
    </array>
</config-file>
```

# Examples

# API

## Methods

- [bluetoothClassicSerial.connect](#connect)
- [bluetoothClassicSerial.connectInsecure](#connectInsecure)
- [bluetoothClassicSerial.disconnect](#disconnect)
- [bluetoothClassicSerial.write](#write)
- [bluetoothClassicSerial.available](#available)
- [bluetoothClassicSerial.read](#read)
- [bluetoothClassicSerial.readUntil](#readuntil)
- [bluetoothClassicSerial.subscribe](#subscribe)
- [bluetoothClassicSerial.unsubscribe](#unsubscribe)
- [bluetoothClassicSerial.subscribeRawData](#subscriberawdata)
- [bluetoothClassicSerial.unsubscribeRawData](#unsubscriberawdata)
- [bluetoothClassicSerial.clear](#clear)
- [bluetoothClassicSerial.list](#list)
- [bluetoothClassicSerial.isEnabled](#isenabled)
- [bluetoothClassicSerial.isConnected](#isconnected)
- [bluetoothClassicSerial.showBluetoothSettings](#showbluetoothsettings)
- [bluetoothClassicSerial.enable](#enable)
- [bluetoothClassicSerial.discoverUnpaired](#discoverunpaired)
- [bluetoothClassicSerial.setDeviceDiscoveredListener](#setdevicediscoveredlistener)
- [bluetoothClassicSerial.clearDeviceDiscoveredListener](#cleardevicediscoveredlistener)

## connect

Connect to a Bluetooth device.

    bluetoothClassicSerial.connect(deviceId, interfaceIdArray, connectSuccess, connectFailure);

### Description

Function `connect` connects to a Bluetooth device.  The callback is long running.  Success will be called when the connection is successful.  Failure is called if the connection fails, or later if the connection disconnects. An error message is passed to the failure callback.  If a device has multiple interfaces then you can connect to them by providind the inteface Ids.

### Parameters

- __connectSuccess__: Success callback function that is invoked when the connection is successful.
- __connectFailure__: Error callback function, invoked when error occurs or the connection disconnects.

#### Android

- __deviceId__: Identifier of the remote device. For Android this is the MAC address.
- __interfaceIdArray__: This identifies the serial port to connect to. For Android this is the SPP_UUID. A common SPP_UUID string is "00001101-0000-1000-8000-00805F9B34FB".  The device doumentation should provide the SPP_UUID.

#### iOS

- __deviceId__: For iOS this is the connection ID
- __interfaceIdArray__: This identifies the serial port to connect to. For iOS the interfaceId is the Protocol String. The Protocol String must be one of those specified in your config.xml.

For iOS, `connect` takes the ConnectionID as the deviceID, and the Protocol String as the interfaceId.

## connectInsecure

Connect insecurely to a Bluetooth device.
```
bluetoothClassicSerial.connectInsecure(deviceId, interfaceIdArray, connectSuccess, connectFailure);
```

### Description

Function `connectInsecure` works like [connect](#connect), but creates an insecure connection to a Bluetooth device.  See the [Android docs](http://goo.gl/1mFjZY) for more information.

#### Android

For Android, see [connect](#connect).

#### iOS

`connectInsecure` is **not supported**.

### Parameters

- __deviceId__: Identifier of the remote device. For Android this is the MAC address.
- __interfaceIdArray__: This identifies the serial port to connect to. For Android this is the SPP_UUID. A common SPP_UUID string is "00001101-0000-1000-8000-00805F9B34FB".  The device documentation should provide the SPP_UUID.
- __connectSuccess__: Success callback function that is invoked when the connection is successful.
- __connectFailure__: Error callback function, invoked when error occurs or the connection disconnects.

## disconnect
```
bluetoothClassicSerial.disconnect(success, failure);
```

### Description

Function `disconnect` disconnects the current connection.

### Parameters

- __success__: Success callback function that is invoked when the connection is successful. [optional]
- __failure__: Error callback function, invoked when error occurs. [optional]

## write

Writes data to the serial port.
```
bluetoothClassicSerial.write(interfaceId, data, success, failure);
```

### Description

Function `write` data to the serial port. Data can be an ArrayBuffer, string, array of integers, or a Uint8Array.

Internally string, integer array, and Uint8Array are converted to an ArrayBuffer. String conversion assume 8bit characters.

### Parameters

- __interfaceId__: The interface to send the data to
- __data__: ArrayBuffer of data
- __success__: Success callback function that is invoked when the connection is successful. [optional]
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example
```
// string
bluetoothClassicSerial.write("00001101-0000-1000-8000-00805F9B34FB", "hello, world", success, failure);

// array of int (or bytes)
bluetoothClassicSerial.write("00001101-0000-1000-8000-00805F9B34FB", [186, 220, 222], success, failure);

// Typed Array
var data = new Uint8Array(4);
data[0] = 0x41;
data[1] = 0x42;
data[2] = 0x43;
data[3] = 0x44;
bluetoothClassicSerial.write(interfaceId, data, success, failure);

// Array Buffer
bluetoothClassicSerial.write(interfaceId, data.buffer, success, failure);
```

## available

Gets the number of bytes of data available.
```
bluetoothClassicSerial.available(interfaceId, success, failure);
```

### Description

Function `available` gets the number of bytes of data available.  The bytes are passed as a parameter to the success callback.

#### iOS

`available` is **not supported**.

### Parameters

- __interfaceId__: The interface to check
- __success__: Success callback function that is invoked when the connection is successful. [optional]
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example
```
bluetoothClassicSerial.available("00001101-0000-1000-8000-00805F9B34FB", function (numBytes) { console.log("There are " + numBytes + " available to read."); }, failure);
```

## read

Reads data from the buffer.
```
bluetoothClassicSerial.read(interfaceId, success, failure);
```

### Description

Function `read` reads the data from the buffer. The data is passed to the success callback as a String.  Calling `read` when no data is available will pass an empty String to the callback.

### Parameters

- __interfaceId__: The interface to read
- __success__: Success callback function that is invoked with the number of bytes available to be read.
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example
```
bluetoothClassicSerial.read("00001101-0000-1000-8000-00805F9B34FB", function (data) { console.log(data);}, failure);
```
## readUntil

Reads data from the buffer until it reaches a delimiter.

    bluetoothClassicSerial.readUntil(interfaceId, '\n', success, failure);

### Description

Function `readUntil` reads the data from the buffer until it reaches a delimiter.  The data is passed to the success callback as a String.  If the buffer does not contain the delimiter, an empty String is passed to the callback. Calling `read` when no data is available will pass an empty String to the callback.

### Parameters

- __interfaceId__: The interface to read
- __delimiter__: delimiter
- __success__: Success callback function that is invoked with the data.
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example
```
bluetoothClassicSerial.readUntil("00001101-0000-1000-8000-00805F9B34FB", '\n', function (data) {console.log(data);}, failure);
```

## subscribe

Subscribe to be notified when data is received.

    bluetoothClassicSerial.subscribe(interfaceId, '\n', success, failure);

### Description

Function `subscribe` registers a callback that is called when data is received.  A delimiter must be specified.  The callback is called with the data as soon as the delimiter string is read.  The callback is a long running callback and will exist until `unsubscribe` is called.

### Parameters

- __interfaceId__: The interface to subscribe to
- __delimiter__: delimiter
- __success__: Success callback function that is invoked with the data.
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example
```
// the success callback is called whenever data is received
bluetoothClassicSerial.subscribe("00001101-0000-1000-8000-00805F9B34FB", '\n', function (data) {
    console.log(data);
}, failure);
```

## unsubscribe

Unsubscribe from a subscription.

    bluetoothClassicSerial.unsubscribe(interfaceId, success, failure);

### Description

Function `unsubscribe` removes any notification added by `subscribe` and kills the callback.

### Parameters

- __interfaceId__: The interface to unsubscribe from
- __success__: Success callback function that is invoked when the connection is successful. [optional]
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example

    bluetoothClassicSerial.unsubscribe();

## subscribeRawData

Subscribe to be notified when data is received.

    bluetoothClassicSerial.subscribeRawData(interfaceId, success, failure);

### Description

Function `subscribeRawData` registers a callback that is called when data is received. The callback is called immediately when data is received. The data is sent to callback as an ArrayBuffer. The callback is a long running callback and will exist until `unsubscribeRawData` is called.

### Parameters

- __interfaceId__: The interface to subscribe to
- __success__: Success callback function that is invoked with the data.
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example
```
// the success callback is called whenever data is received
bluetoothClassicSerial.subscribeRawData(function (data) {
    var bytes = new Uint8Array(data);
    console.log(bytes);
}, failure);
```

## unsubscribeRawData

Unsubscribe from a subscription.

    bluetoothClassicSerial.unsubscribeRawData(interfaceId, success, failure);

### Description

Function `unsubscribeRawData` removes any notification added by `subscribeRawData` and kills the callback.

### Parameters

- __interfaceId__: The interface to unsubscribe from
- __success__: Success callback function that is invoked when the unsubscribe is successful. [optional]
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example
```
bluetoothClassicSerial.unsubscribeRawData("00001101-0000-1000-8000-00805F9B34FB");
```

## clear

Clears data in the buffer.

    bluetoothClassicSerial.clear(interfaceId, success, failure);

### Description

Function `clear` removes any data from the receive buffer.

### Parameters

- __success__: Success callback function that is invoked when the connection is successful. [optional]
- __failure__: Error callback function, invoked when error occurs. [optional]

## list

Lists bonded devices

    bluetoothClassicSerial.list(success, failure);

### Description

#### Android

Function `list` lists the paired Bluetooth devices.  The success callback is called with a list of objects.

Example list passed to success callback.  See [BluetoothDevice](http://developer.android.com/reference/android/bluetooth/BluetoothDevice.html#getName\(\)) and [BluetoothClass#getDeviceClass](http://developer.android.com/reference/android/bluetooth/BluetoothClass.html#getDeviceClass\(\)).

    [{
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

#### iOS

Function `list` lists the paired Bluetooth devices.  The success callback is called with a list of objects.

Example list passed to success callback for iOS.

    TBC

### Note

`id` is the generic name for `connection Id` or [mac]`address` so that code can be platform independent.

### Parameters

- __success__: Success callback function that is invoked with a list of bonded devices.
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example
```
bluetoothClassicSerial.list(function(devices) {
    devices.forEach(function(device) {
        console.log(device.id);
    })
}, failure);
```

## isConnected

Reports the connection status.  If all interfaces are connected then the success callback is called.  If one interface is not connected then the failure callback is called.  The connect method does not allow the status of a single interface to be determined (unless you have only specified a single interfaceId in the prior connect method).

    bluetoothClassicSerial.isConnected(success, failure);

### Description

Function `isConnected` calls the success callback when connected to a peer and the failure callback when *not* connected.

### Parameters

- __success__: Success callback function, invoked when device connected.
- __failure__: Error callback function, invoked when device is NOT connected.

### Quick Example
```
bluetoothClassicSerial.isConnected(
    function() {
        console.log("Bluetooth is connected");
    },
    function() {
        console.log("Bluetooth is *not* connected");
    }
);
```

## isEnabled

Reports if bluetooth is enabled.

    bluetoothClassicSerial.isEnabled(success, failure);

### Description

Function `isEnabled` calls the success callback when bluetooth is enabled and the failure callback when bluetooth is *not* enabled.

### Parameters

- __success__: Success callback function, invoked when Bluetooth is enabled.
- __failure__: Error callback function, invoked when Bluetooth is NOT enabled.

### Quick Example
```
bluetoothClassicSerial.isEnabled(
    function() {
        console.log("Bluetooth is enabled");
    },
    function() {
        console.log("Bluetooth is *not* enabled");
    }
);
```

## showBluetoothSettings

Show the Bluetooth settings on the device.

    bluetoothClassicSerial.showBluetoothSettings(success, failure);

### Description

Function `showBluetoothSettings` opens the Bluetooth settings on the operating systems.

#### iOS

`showBluetoothSettings` is not supported.

### Parameters

- __success__: Success callback function [optional]
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example
```
bluetoothClassicSerial.showBluetoothSettings();
```

## enable

Enable Bluetooth on the device.

    bluetoothClassicSerial.enable(success, failure);

### Description

Function `enable` prompts the user to enable Bluetooth. If `enable` is called when Bluetooth is already enabled, the user will not prompted and the success callback will be invoked.

#### iOS

`enable` is **not supported**.

`enable` is only supported on Android and does not work on iOS.

If `enable` is called when Bluetooth is already enabled, the user will not prompted and the success callback will be invoked.

### Parameters

- __success__: Success callback function, invoked if the user enabled Bluetooth.
- __failure__: Error callback function, invoked if the user does not enabled Bluetooth.

### Quick Example
```
bluetoothClassicSerial.enable(
    function() {
        console.log("Bluetooth is enabled");
    },
    function() {
        console.log("The user did *not* enable Bluetooth");
    }
);
```

## discoverUnpaired

Discover unpaired devices

    bluetoothClassicSerial.discoverUnpaired(success, failure);

### Description

The behaviour of this method varies between Android and iOS.

#### Android

Function `discoverUnpaired` discovers unpaired Bluetooth devices. The success callback is called with a list of objects similar to `list`, or an empty list if no unpaired devices are found.

Example list passed to success callback.
```
[{
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
```

The discovery process takes a while to happen. You can register notify callback with [setDeviceDiscoveredListener](#setdevicediscoveredlistener).
You may also want to show a progress indicator while waiting for the discover process to finish, and the success callback to be invoked.

Calling `connect` on an unpaired Bluetooth device should begin the Android pairing process.

#### iOS

Function `discoverUnpaired` will launch a native iOS window showing all devices which match the protocol string defined in the application's cordova config.xml file.  Choosing a device from the list will initiate pairing and the details of that device will **not** trigger the success callback function. **The device discovered listener must be used**. Once paired the device is available for connection.

### Parameters

- __success__: Success callback function that is invoked with a list of unpaired devices.
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example
```
bluetoothClassicSerial.discoverUnpaired(function(devices) {
    devices.forEach(function(device) {
        console.log(device.id);
    })
}, failure);
```

## setDeviceDiscoveredListener

### Description

Register a notify callback function to be called during bluetooth device discovery.

#### Android

Register a notify callback function to be called during bluetooth device discovery. For callback to work, discovery process must
be started with [discoverUnpaired](#discoverunpaired).
There can be only one registered callback.

Example object passed to notify callback.
```
{
    "class": 276,
    "id": "10:BF:48:CB:00:00",
    "address": "10:BF:48:CB:00:00",
    "name": "Nexus 7"
}
```

#### iOS

When a device is paired from the [discoverUnpaired](#discoverunpaired) function it's details will be passed to the callback function.  Unlike Android this will only be fired once for the selected device, not for all the available devices.

### Parameters

- __notify__: Notify callback function that is invoked when device is discovered during discovery process.

### Quick Example
```
bluetoothClassicSerial.setDeviceDiscoveredListener(function(device) {
  console.log('Found: ',device.id);
});
```

## clearDeviceDiscoveredListener

Clears notify callback function registered with [setDeviceDiscoveredListener](#setdevicediscoveredlistener).

### Quick Example
```
bluetoothClassicSerial.clearDeviceDiscoveredListener();
```

# Misc

## Where does this work?

### Android

Development Devices include
 * Nexus 7 (2013) with Android 6.1
 * Samsung Galaxy S6 with Android 6.0
 * Samsung Galaxy S5 with Android 5.0

### iOS

Development Devices include
  * iPhone 5s
  * iPad Gen 4

## Props

This project is a fork of Don Coleman's https://github.com/don/BluetoothSerial so all the big props to him.

The multi interface implementation for Android borrowed ideas from Shikoruma's pull request https://github.com/don/BluetoothSerial/pull/205 to Don Coleman's [Cordova BluetoothSerial Plugin](https://github.com/don/BluetoothSerial).

### Android

Most of the Bluetooth implementation was borrowed from the Bluetooth Chat example in the Android SDK.

### iOS

### API

The API for available, read, readUntil was influenced by the [BtSerial Library for Processing for Arduino](https://github.com/arduino/BtSerial)

## Wrong Bluetooth Plugin?

If you don't need **serial** over Bluetooth, try the [PhoneGap Bluetooth Plugin for Android](https://github.com/phonegap/phonegap-plugins/tree/DEPRECATED/Android/Bluetooth/2.2.0) or perhaps [phonegap-plugin-bluetooth](https://github.com/tanelih/phonegap-bluetooth-plugin).

If you need generic Bluetooth Low Energy support checkout Don Colemans's [Cordova BLE Plugin](https://github.com/don/cordova-plugin-ble-central).

If you need BLE for RFduino checkout Don Colemans's [RFduino Plugin](https://github.com/don/cordova-plugin-rfduino).

For Windows Phone 8 support see the original project, Don Coleman's [Cordova BluetoothSerial Plugin](https://github.com/don/BluetoothSerial)

## What format should the Mac Address be in?
An example a properly formatted mac address is "AA:BB:CC:DD:EE:FF"

## Feedback

Try the code. If you find an problem or missing feature, file an issue or create a pull request.
