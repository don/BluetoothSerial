# Bluetooth Classic Serial Plugin for Cordova

This plugin enables serial communication over Bluetooth. It is a fork of https://github.com/don/BluetoothSerial.  The core difference is that https://github.com/don/BluetoothSerial supports Bluetooth Low Energy on iOS.  This plugin will written against the iOS Accessory Framework (MFi) to support Classic Bluetooth on iOS.

** Initial Stages - Do not use! **
** iOS Implementation not in place! **

## Supported Platforms

* Android
* iOS (devices must be MFi certified (link))
* Windows Phone 8
* Browser (Testing only. See [comments](https://github.com/don/BluetoothSerial/blob/master/src/browser/bluetoothSerial.js).)

## Limitations

 * The phone must initiate the Bluetooth connection
 * Will *not* connect Android to Android[*](https://github.com/don/BluetoothSerial/issues/50#issuecomment-66405396)
 * Will *not* connect iOS to iOS[*](https://github.com/don/BluetoothSerial/issues/75#issuecomment-52591397)
 * Android Target SDK must be 22 or less.  New Permission model for SDK 23 not implemented

# Installing

Install with Cordova cli

    $ cordova plugin add cordova-plugin-bluetoothClassic-serial

Note that this plugin's id changed from `cordova-plugin-bluetooth-serial` to 'cordova-plugin-bluetoothClassic-serial' as part of the fork.  An npmjs repository does not yet exist.

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
- [bluetoothClassicSerial.setName](#setname)
- [bluetoothClassicSerial.setDiscoverable](#setdiscoverable)
- [bluetoothClassicSerial.getInsecureUUID](#getinsecureuuid)
- [bluetoothClassicSerial.getSecureUUID](#getsecureuuid)
- [bluetoothClassicSerial.setInsecureUUID](#setinsecureuuid)
- [bluetoothClassicSerial.setSecureUUID](#setsecureuuid)

## connect

Connect to a Bluetooth device.

    bluetoothClassicSerial.connect(macAddress_or_uuid, connectSuccess, connectFailure);

### Description

Function `connect` connects to a Bluetooth device.  The callback is long running.  Success will be called when the connection is successful.  Failure is called if the connection fails, or later if the connection disconnects. An error message is passed to the failure callback.

#### Android
For Android, `connect` takes a MAC address of the remote device.

#### iOS
For iOS, `connect` takes the UUID of the remote device.  Optionally, you can pass an **empty string** and the plugin will connect to the first BLE peripheral.

#### Windows Phone
For Windows Phone, `connect` takes a MAC address of the remote device. The MAC address can optionally surrounded with parenthesis. e.g. `(AA:BB:CC:DD:EE:FF)`


### Parameters

- __macAddress_or_uuid__: Identifier of the remote device.
- __connectSuccess__: Success callback function that is invoked when the connection is successful.
- __connectFailure__: Error callback function, invoked when error occurs or the connection disconnects.

## connectInsecure

Connect insecurely to a Bluetooth device.

    bluetoothClassicSerial.connectInsecure(macAddress, connectSuccess, connectFailure);

### Description

Function `connectInsecure` works like [connect](#connect), but creates an insecure connection to a Bluetooth device.  See the [Android docs](http://goo.gl/1mFjZY) for more information.

#### Android
For Android, `connectInsecure` takes a macAddress of the remote device.

#### iOS
`connectInsecure` is **not supported** on iOS.

#### Windows Phone
`connectInsecure` is **not supported** on Windows Phone.

### Parameters

- __macAddress__: Identifier of the remote device.
- __connectSuccess__: Success callback function that is invoked when the connection is successful.
- __connectFailure__: Error callback function, invoked when error occurs or the connection disconnects.


## disconnect

Disconnect.

    bluetoothClassicSerial.disconnect([success], [failure]);

### Description

Function `disconnect` disconnects the current connection.

### Parameters

- __success__: Success callback function that is invoked when the connection is successful. [optional]
- __failure__: Error callback function, invoked when error occurs. [optional]

## write

Writes data to the serial port.

    bluetoothClassicSerial.write(data, success, failure);

### Description

Function `write` data to the serial port. Data can be an ArrayBuffer, string, array of integers, or a Uint8Array.

Internally string, integer array, and Uint8Array are converted to an ArrayBuffer. String conversion assume 8bit characters.

### Parameters

- __data__: ArrayBuffer of data
- __success__: Success callback function that is invoked when the connection is successful. [optional]
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example

    // string
    bluetoothClassicSerial.write("hello, world", success, failure);

    // array of int (or bytes)
    bluetoothClassicSerial.write([186, 220, 222], success, failure);

    // Typed Array
    var data = new Uint8Array(4);
    data[0] = 0x41;
    data[1] = 0x42;
    data[2] = 0x43;
    data[3] = 0x44;
    bluetoothClassicSerial.write(data, success, failure);

    // Array Buffer
    bluetoothClassicSerial.write(data.buffer, success, failure);

## available

Gets the number of bytes of data available.

    bluetoothClassicSerial.available(success, failure);

### Description

Function `available` gets the number of bytes of data available.  The bytes are passed as a parameter to the success callback.

### Parameters

- __success__: Success callback function that is invoked when the connection is successful. [optional]
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example

    bluetoothClassicSerial.available(function (numBytes) {
        console.log("There are " + numBytes + " available to read.");
    }, failure);

## read

Reads data from the buffer.

    bluetoothClassicSerial.read(success, failure);

### Description

Function `read` reads the data from the buffer. The data is passed to the success callback as a String.  Calling `read` when no data is available will pass an empty String to the callback.

### Parameters

- __success__: Success callback function that is invoked with the number of bytes available to be read.
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example

    bluetoothClassicSerial.read(function (data) {
        console.log(data);
    }, failure);

## readUntil

Reads data from the buffer until it reaches a delimiter.

    bluetoothClassicSerial.readUntil('\n', success, failure);

### Description

Function `readUntil` reads the data from the buffer until it reaches a delimiter.  The data is passed to the success callback as a String.  If the buffer does not contain the delimiter, an empty String is passed to the callback. Calling `read` when no data is available will pass an empty String to the callback.

### Parameters

- __delimiter__: delimiter
- __success__: Success callback function that is invoked with the data.
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example

    bluetoothClassicSerial.readUntil('\n', function (data) {
        console.log(data);
    }, failure);

## subscribe

Subscribe to be notified when data is received.

    bluetoothClassicSerial.subscribe('\n', success, failure);

### Description

Function `subscribe` registers a callback that is called when data is received.  A delimiter must be specified.  The callback is called with the data as soon as the delimiter string is read.  The callback is a long running callback and will exist until `unsubscribe` is called.

### Parameters

- __delimiter__: delimiter
- __success__: Success callback function that is invoked with the data.
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example

    // the success callback is called whenever data is received
    bluetoothClassicSerial.subscribe('\n', function (data) {
        console.log(data);
    }, failure);

## unsubscribe

Unsubscribe from a subscription.

    bluetoothClassicSerial.unsubscribe(success, failure);

### Description

Function `unsubscribe` removes any notification added by `subscribe` and kills the callback.

### Parameters

- __success__: Success callback function that is invoked when the connection is successful. [optional]
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example

    bluetoothClassicSerial.unsubscribe();

## subscribeRawData

Subscribe to be notified when data is received.

    bluetoothClassicSerial.subscribeRawData(success, failure);

### Description

Function `subscribeRawData` registers a callback that is called when data is received. The callback is called immediately when data is received. The data is sent to callback as an ArrayBuffer. The callback is a long running callback and will exist until `unsubscribeRawData` is called.

### Parameters

- __success__: Success callback function that is invoked with the data.
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example

    // the success callback is called whenever data is received
    bluetoothClassicSerial.subscribeRawData(function (data) {
        var bytes = new Uint8Array(data);
        console.log(bytes);
    }, failure);

## unsubscribeRawData

Unsubscribe from a subscription.

    bluetoothClassicSerial.unsubscribeRawData(success, failure);

### Description

Function `unsubscribeRawData` removes any notification added by `subscribeRawData` and kills the callback.

### Parameters

- __success__: Success callback function that is invoked when the connection is successful. [optional]
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example

    bluetoothClassicSerial.unsubscribeRawData();

## clear

Clears data in the buffer.

    bluetoothClassicSerial.clear(success, failure);

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

Function `list` lists the discovered Bluetooth Low Energy peripheral.  The success callback is called with a list of objects.

Example list passed to success callback for iOS.

    [{
        "id": "CC410A23-2865-F03E-FC6A-4C17E858E11E",
        "uuid": "CC410A23-2865-F03E-FC6A-4C17E858E11E",
        "name": "Biscuit",
        "rssi": -68
    }]

The advertised RSSI **may** be included if available.

#### Windows Phone

Function `list` lists the paired Bluetooth devices.  The success callback is called with a list of objects.

Example list passed to success callback for Windows Phone.

    [{
        "id": "(10:BF:48:CB:00:00)",
        "name": "Nexus 7"
    }, {
        "id": "(00:06:66:4D:00:00)",
        "name": "RN42"
    }]

### Note

`id` is the generic name for `uuid` or [mac]`address` so that code can be platform independent.

### Parameters

- __success__: Success callback function that is invoked with a list of bonded devices.
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example

    bluetoothClassicSerial.list(function(devices) {
        devices.forEach(function(device) {
            console.log(device.id);
        })
    }, failure);

## isConnected

Reports the connection status.

    bluetoothClassicSerial.isConnected(success, failure);

### Description

Function `isConnected` calls the success callback when connected to a peer and the failure callback when *not* connected.

### Parameters

- __success__: Success callback function, invoked when device connected.
- __failure__: Error callback function, invoked when device is NOT connected.

### Quick Example

    bluetoothClassicSerial.isConnected(
        function() {
            console.log("Bluetooth is connected");
        },
        function() {
            console.log("Bluetooth is *not* connected");
        }
    );

## isEnabled

Reports if bluetooth is enabled.

    bluetoothClassicSerial.isEnabled(success, failure);

### Description

Function `isEnabled` calls the success callback when bluetooth is enabled and the failure callback when bluetooth is *not* enabled.

### Parameters

- __success__: Success callback function, invoked when Bluetooth is enabled.
- __failure__: Error callback function, invoked when Bluetooth is NOT enabled.

### Quick Example

    bluetoothClassicSerial.isEnabled(
        function() {
            console.log("Bluetooth is enabled");
        },
        function() {
            console.log("Bluetooth is *not* enabled");
        }
    );

## showBluetoothSettings

Show the Bluetooth settings on the device.

    bluetoothClassicSerial.showBluetoothSettings(success, failure);

### Description

Function `showBluetoothSettings` opens the Bluetooth settings on the operating systems.

#### iOS

`showBluetoothSettings` is not supported on iOS.

### Parameters

- __success__: Success callback function [optional]
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example

    bluetoothClassicSerial.showBluetoothSettings();

## enable

Enable Bluetooth on the device.

    bluetoothClassicSerial.enable(success, failure);

### Description

Function `enable` prompts the user to enable Bluetooth.

#### Android

`enable` is only supported on Android and does not work on iOS or Windows Phone.

If `enable` is called when Bluetooth is already enabled, the user will not prompted and the success callback will be invoked.

### Parameters

- __success__: Success callback function, invoked if the user enabled Bluetooth.
- __failure__: Error callback function, invoked if the user does not enabled Bluetooth.

### Quick Example

    bluetoothClassicSerial.enable(
        function() {
            console.log("Bluetooth is enabled");
        },
        function() {
            console.log("The user did *not* enable Bluetooth");
        }
    );

## discoverUnpaired

Discover unpaired devices

    bluetoothClassicSerial.discoverUnpaired(success, failure);

### Description

#### Android

Function `discoverUnpaired` discovers unpaired Bluetooth devices. The success callback is called with a list of objects similar to `list`, or an empty list if no unpaired devices are found.

Example list passed to success callback.

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

The discovery process takes a while to happen. You can register notify callback with [setDeviceDiscoveredListener](#setdevicediscoveredlistener).
You may also want to show a progress indicator while waiting for the discover proces to finish, and the sucess callback to be invoked.

Calling `connect` on an unpaired Bluetooth device should begin the Android pairing process.

#### iOS

`discoverUnpaired` TBA.

#### Windows Phone

`discoverUnpaired` is not supported on Windows Phone.

### Parameters

- __success__: Success callback function that is invoked with a list of unpaired devices.
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example

    bluetoothClassicSerial.discoverUnpaired(function(devices) {
        devices.forEach(function(device) {
            console.log(device.id);
        })
    }, failure);

## setDeviceDiscoveredListener

Register a notify callback function to be called during bluetooth device discovery. For callback to work, discovery process must
be started with [discoverUnpaired](#discoverunpaired).
There can be only one registered callback.

Example object passed to notify callback.

    {
        "class": 276,
        "id": "10:BF:48:CB:00:00",
        "address": "10:BF:48:CB:00:00",
        "name": "Nexus 7"
    }

#### iOS & Windows Phone

See [discoverUnpaired](#discoverunpaired).

### Parameters

- __notify__: Notify callback function that is invoked when device is discovered during discovery process.

### Quick Example

    bluetoothClassicSerial.setDeviceDiscoveredListener(function(device) {
		console.log('Found: '+device.id);
    });

## clearDeviceDiscoveredListener

Clears notify callback function registered with [setDeviceDiscoveredListener](#setdevicediscoveredlistener).

### Quick Example

    bluetoothClassicSerial.clearDeviceDiscoveredListener();

## setName

Sets the human readable device name that is broadcasted to other devices.

    bluetoothClassicSerial.setName(newName);

#### Android
For Android, `setName` takes a String for the new name.

#### iOS
Not currently implemented.

#### Windows Phone
Not currently implemented.

### Parameters

- __newName__: Desired name of device.

### Quick Example

    bluetoothClassicSerial.setName("Really cool name");

## setDiscoverable

Makes the device discoverable by other devices.

    bluetoothClassicSerial.setDiscoverable(discoverableDuration);

#### Android
For Android, `setDiscoverable` takes an int for the number of seconds device should be discoverable. A time of 0 will make it permanently discoverable.

#### iOS
Not currently implemented.

#### Windows Phone
Not currently implemented.

### Parameters

- __discoverableDuration__: Desired number of seconds device should be discoverable for.

### Quick Example

    bluetoothClassicSerial.setDiscoverable(0);

#getinsecureuuid

Returns the SPP_UUID used for  [connectInsecure](#connectinsecure)

    bluetoothClassicSerial.getInsecureUUID(success, failure);

### Description

Some devices require a non standard SPP_UUID, `getInsecureUUID` allows you to check the SPP_UUID which will be used for an insecure connection.

#### Android

Implemented for Android

### iOS

Not Implemented for iOS

### Windows

Not Implemented for Windows

#getsecureuuid

Returns the SPP_UUID used for  [connect](#connect)

    bluetoothClassicSerial.getSecureUUID(success, failure);

### Description

Some devices require a non standard SPP_UUID, `getSecureUUID` allows you to check the SPP_UUID which will be used for a secure connection.

#### Android

Implemented for Android

### iOS

Not Implemented for iOS

### Windows

Not Implemented for Windows

#setinsecureuuid

Sets the SPP_UUID used for [connectInsecure](#connectinsecure)

    bluetoothClassicSerial.setInsecureUUID(uuidString, success, failure);

### Description

Some devices require a non standard SPP_UUID, `setInsecureUUID` allows you to provide a custom SPP_UUID string to be used for an insecure connection.  If successful the UUID string will be returned to the success callback function.

#### Android

Implemented for Android

### iOS

Not Implemented for iOS

### Windows

Not Implemented for Windows

#setsecureuuid

Sets the SPP_UUID used for  [connect](#connect)

    bluetoothClassicSerial.setSecureUUID(uuidString, success, failure);

### Description

Some devices require a non standard SPP_UUID, `setSsecureUUID` allows you to provide a custom SPP_UUID string to be used for an secure connection.  If successful the UUID string will be returned to the success callback function.

#### Android

Implemented for Android

### iOS

Not Implemented for iOS

### Windows

Not Implemented for Windows

# Misc

## Where does this work?

### Android

Current development is done with Cordova 6.2.0 on Android 5. Theoretically this code runs on PhoneGap 2.9 and greater.  It should support Android-10 (2.3.2) and greater, but I only test with Android 5.x+.

Development Devices include
 * Nexus 7 (2013) with Android 6
 * Samsung Galaxy S6 with Android 6.0
 * Samsung Galaxy S5 with Android 5.0

### iOS

TBA

## Props

This project is a fork of Don Coleman's https://github.com/don/BluetoothSerial so all the big props to him.

### Android

Most of the Bluetooth implementation was borrowed from the Bluetooth Chat example in the Android SDK.

### iOS

### API

The API for available, read, readUntil was influenced by the [BtSerial Library for Processing for Arduino](https://github.com/arduino/BtSerial)

## Wrong Bluetooth Plugin?

If you don't need **serial** over Bluetooth, try the [PhoneGap Bluetooth Plugin for Android](https://github.com/phonegap/phonegap-plugins/tree/DEPRECATED/Android/Bluetooth/2.2.0) or perhaps [phonegap-plugin-bluetooth](https://github.com/tanelih/phonegap-bluetooth-plugin).

If you need generic Bluetooth Low Energy support checkout Don Colemans's [Cordova BLE Plugin](https://github.com/don/cordova-plugin-ble-central).

If you need BLE for RFduino checkout Don Colemans's [RFduino Plugin](https://github.com/don/cordova-plugin-rfduino).

## What format should the Mac Address be in?
An example a properly formatted mac address is ``AA:BB:CC:DD:EE:FF``

## Feedback

Try the code. If you find an problem or missing feature, file an issue or create a pull request.
