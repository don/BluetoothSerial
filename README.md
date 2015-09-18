# Bluetooth Serial Plugin for PhoneGap

This plugin enables serial communication over Bluetooth. It was written for communicating between Android or iOS and an Arduino.

Android and Windows Phone use Classic Bluetooth.  iOS uses Bluetooth Low Energy.

## Supported Platforms

* Android
* iOS with [RedBearLab](http://redbearlab.com) BLE hardware, [Adafruit Bluefruit LE](http://www.adafruit.com/products/1697), [Laird BL600](http://www.lairdtech.com/Products/Embedded-Wireless-Solutions/Bluetooth-Radio-Modules/BL600-Series/#.VBI7AS5dUzI), or [BlueGiga](https://bluegiga.zendesk.com/entries/29185293--BGScript-spp-over-ble-AT-command-SPP-implementation-for-BLE)
* Windows Phone 8

[Supporting other Bluetooth Low Energy hardware](#supporting-other-ble-hardware)

## Limitations

 * The phone must initiate the Bluetooth connection
 * iOS Bluetooth Low Energy requires iPhone 4S, iPhone5, iPod 5, or iPad3+
 * Will *not* connect Android to Android[*](https://github.com/don/BluetoothSerial/issues/50#issuecomment-66405396)
 * Will *not* connect iOS to iOS[*](https://github.com/don/BluetoothSerial/issues/75#issuecomment-52591397)

# Installing

Install with Cordova cli

    $ cordova plugin add cordova-plugin-bluetooth-serial

Note that this plugin's id changed from `com.megster.cordova.bluetoothserial` to `cordova-plugin-bluetooth-serial` as part of the migration from the [Cordova plugin repo](http://plugins.cordova.io/) to [npm](https://www.npmjs.com/).

# Examples

There are some [sample projects](https://github.com/don/BluetoothSerial/tree/master/examples) included with the plugin.

# API

## Methods

- [bluetoothSerial.connect](#connect)
- [bluetoothSerial.connectInsecure](#connectInsecure)
- [bluetoothSerial.disconnect](#disconnect)
- [bluetoothSerial.write](#write)
- [bluetoothSerial.available](#available)
- [bluetoothSerial.read](#read)
- [bluetoothSerial.readUntil](#readuntil)
- [bluetoothSerial.subscribe](#subscribe)
- [bluetoothSerial.unsubscribe](#unsubscribe)
- [bluetoothSerial.subscribeRawData](#subscriberawdata)
- [bluetoothSerial.unsubscribeRawData](#unsubscriberawdata)
- [bluetoothSerial.clear](#clear)
- [bluetoothSerial.list](#list)
- [bluetoothSerial.isEnabled](#isenabled)
- [bluetoothSerial.isConnected](#isconnected)
- [bluetoothSerial.readRSSI](#readrssi)
- [bluetoothSerial.showBluetoothSettings](#showbluetoothsettings)
- [bluetoothSerial.enable](#enable)
- [bluetoothSerial.discoverUnpaired](#discoverunpaired)
- [bluetoothSerial.setDeviceDiscoveredListener](#setdevicediscoveredlistener)
- [bluetoothSerial.clearDeviceDiscoveredListener](#cleardevicediscoveredlistener)

## connect

Connect to a Bluetooth device.

    bluetoothSerial.connect(macAddress_or_uuid, connectSuccess, connectFailure);

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

    bluetoothSerial.connectInsecure(macAddress, connectSuccess, connectFailure);

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

    bluetoothSerial.disconnect([success], [failure]);

### Description

Function `disconnect` disconnects the current connection.

### Parameters

- __success__: Success callback function that is invoked when the connection is successful. [optional]
- __failure__: Error callback function, invoked when error occurs. [optional]

## write

Writes data to the serial port.

    bluetoothSerial.write(data, success, failure);

### Description

Function `write` data to the serial port. Data can be an ArrayBuffer, string, array of integers, or a Uint8Array.

Internally string, integer array, and Uint8Array are converted to an ArrayBuffer. String conversion assume 8bit characters.

### Parameters

- __data__: ArrayBuffer of data
- __success__: Success callback function that is invoked when the connection is successful. [optional]
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example

    // string
    bluetoothSerial.write("hello, world", success, failure);

    // array of int (or bytes)
    bluetoothSerial.write([186, 220, 222], success, failure);

    // Typed Array
    var data = new Uint8Array(4);
    data[0] = 0x41;
    data[1] = 0x42;
    data[2] = 0x43;
    data[3] = 0x44;
    bluetoothSerial.write(data, success, failure);

    // Array Buffer
    bluetoothSerial.write(data.buffer, success, failure);

## available

Gets the number of bytes of data available.

    bluetoothSerial.available(success, failure);

### Description

Function `available` gets the number of bytes of data available.  The bytes are passed as a parameter to the success callback.

### Parameters

- __success__: Success callback function that is invoked when the connection is successful. [optional]
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example

    bluetoothSerial.available(function (numBytes) {
        console.log("There are " + numBytes + " available to read.");
    }, failure);

## read

Reads data from the buffer.

    bluetoothSerial.read(success, failure);

### Description

Function `read` reads the data from the buffer. The data is passed to the success callback as a String.  Calling `read` when no data is available will pass an empty String to the callback.

### Parameters

- __success__: Success callback function that is invoked with the number of bytes available to be read.
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example

    bluetoothSerial.read(function (data) {
        console.log(data);
    }, failure);

## readUntil

Reads data from the buffer until it reaches a delimiter.

    bluetoothSerial.readUntil('\n', success, failure);

### Description

Function `readUntil` reads the data from the buffer until it reaches a delimiter.  The data is passed to the success callback as a String.  If the buffer does not contain the delimiter, an empty String is passed to the callback. Calling `read` when no data is available will pass an empty String to the callback.

### Parameters

- __delimiter__: delimiter
- __success__: Success callback function that is invoked with the data.
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example

    bluetoothSerial.readUntil('\n', function (data) {
        console.log(data);
    }, failure);

## subscribe

Subscribe to be notified when data is received.

    bluetoothSerial.subscribe('\n', success, failure);

### Description

Function `subscribe` registers a callback that is called when data is received.  A delimiter must be specified.  The callback is called with the data as soon as the delimiter string is read.  The callback is a long running callback and will exist until `unsubscribe` is called.

### Parameters

- __delimiter__: delimiter
- __success__: Success callback function that is invoked with the data.
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example

    // the success callback is called whenever data is received
    bluetoothSerial.subscribe('\n', function (data) {
        console.log(data);
    }, failure);

## unsubscribe

Unsubscribe from a subscription.

    bluetoothSerial.unsubscribe(success, failure);

### Description

Function `unsubscribe` removes any notification added by `subscribe` and kills the callback.

### Parameters

- __success__: Success callback function that is invoked when the connection is successful. [optional]
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example

    bluetoothSerial.unsubscribe();

## subscribeRawData

Subscribe to be notified when data is received.

    bluetoothSerial.subscribeRawData(success, failure);

### Description

Function `subscribeRawData` registers a callback that is called when data is received. The callback is called immediately when data is received. The data is sent to callback as an ArrayBuffer. The callback is a long running callback and will exist until `unsubscribeRawData` is called.

### Parameters

- __success__: Success callback function that is invoked with the data.
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example

    // the success callback is called whenever data is received
    bluetoothSerial.subscribeRawData(function (data) {
        var bytes = new Uint8Array(data);
        console.log(bytes);
    }, failure);

## unsubscribeRawData

Unsubscribe from a subscription.

    bluetoothSerial.unsubscribeRawData(success, failure);

### Description

Function `unsubscribeRawData` removes any notification added by `subscribeRawData` and kills the callback.

### Parameters

- __success__: Success callback function that is invoked when the connection is successful. [optional]
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example

    bluetoothSerial.unsubscribeRawData();

## clear

Clears data in the buffer.

    bluetoothSerial.clear(success, failure);

### Description

Function `clear` removes any data from the receive buffer.

### Parameters

- __success__: Success callback function that is invoked when the connection is successful. [optional]
- __failure__: Error callback function, invoked when error occurs. [optional]

## list

Lists bonded devices

    bluetoothSerial.list(success, failure);

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

    bluetoothSerial.list(function(devices) {
        devices.forEach(function(device) {
            console.log(device.id);
        })
    }, failure);

## isConnected

Reports the connection status.

    bluetoothSerial.isConnected(success, failure);

### Description

Function `isConnected` calls the success callback when connected to a peer and the failure callback when *not* connected.

### Parameters

- __success__: Success callback function, invoked when device connected.
- __failure__: Error callback function, invoked when device is NOT connected.

### Quick Example

    bluetoothSerial.isConnected(
        function() {
            console.log("Bluetooth is connected");
        },
        function() {
            console.log("Bluetooth is *not* connected");
        }
    );

## isEnabled

Reports if bluetooth is enabled.

    bluetoothSerial.isEnabled(success, failure);

### Description

Function `isEnabled` calls the success callback when bluetooth is enabled and the failure callback when bluetooth is *not* enabled.

### Parameters

- __success__: Success callback function, invoked when Bluetooth is enabled.
- __failure__: Error callback function, invoked when Bluetooth is NOT enabled.

### Quick Example

    bluetoothSerial.isEnabled(
        function() {
            console.log("Bluetooth is enabled");
        },
        function() {
            console.log("Bluetooth is *not* enabled");
        }
    );

## readRSSI

Reads the RSSI from the connected peripheral.

    bluetoothSerial.readRSSI(success, failure);

### Description

Function `readRSSI` calls the success callback with the rssi.

**BLE only** *This function is experimental and the API may change*

### Parameters

- __success__: Success callback function that is invoked with the rssi value.
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example

    bluetoothSerial.readRSSI(
        function(rssi) {
            console.log(rssi);
        }
    );

## showBluetoothSettings

Show the Bluetooth settings on the device.

    bluetoothSerial.showBluetoothSettings(success, failure);

### Description

Function `showBluetoothSettings` opens the Bluetooth settings on the operating systems.

#### iOS

`showBluetoothSettings` is not supported on iOS.

### Parameters

- __success__: Success callback function [optional]
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example

    bluetoothSerial.showBluetoothSettings();

## enable

Enable Bluetooth on the device.

    bluetoothSerial.enable(success, failure);

### Description

Function `enable` prompts the user to enable Bluetooth.

#### Android

`enable` is only supported on Android and does not work on iOS or Windows Phone.

If `enable` is called when Bluetooth is already enabled, the user will not prompted and the success callback will be invoked.

### Parameters

- __success__: Success callback function, invoked if the user enabled Bluetooth.
- __failure__: Error callback function, invoked if the user does not enabled Bluetooth.

### Quick Example

    bluetoothSerial.enable(
        function() {
            console.log("Bluetooth is enabled");
        },
        function() {
            console.log("The user did *not* enable Bluetooth");
        }
    );

## discoverUnpaired

Discover unpaired devices

    bluetoothSerial.discoverUnpaired(success, failure);

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

`discoverUnpaired` is not supported on iOS. iOS uses Bluetooth Low Energy and `list` discovers devices without pairing.

#### Windows Phone

`discoverUnpaired` is not supported on Windows Phone.

### Parameters

- __success__: Success callback function that is invoked with a list of unpaired devices.
- __failure__: Error callback function, invoked when error occurs. [optional]

### Quick Example

    bluetoothSerial.discoverUnpaired(function(devices) {
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

    bluetoothSerial.setDeviceDiscoveredListener(function(device) {
		console.log('Found: '+device.id);
    });

## clearDeviceDiscoveredListener

Clears notify callback function registered with [setDeviceDiscoveredListener](#setdevicediscoveredlistener).

### Quick Example

    bluetoothSerial.clearDeviceDiscoveredListener();

# Misc

## Where does this work?

### Android

Current development is done with Cordova 4.2 on Android 5. Theoretically this code runs on PhoneGap 2.9 and greater.  It should support Android-10 (2.3.2) and greater, but I only test with Android 4.x+.

Development Devices include
 * Nexus 5 with Android 5
 * Samsung Galaxy Tab 10.1 (GT-P7510) with Android 4.0.4 (see [Issue #8](https://github.com/don/BluetoothSerial/issues/8))
 * Google Nexus S with Android 4.1.2
 * Nexus 4 with Android 5
 * Samsung Galaxy S4 with Android 4.3

On the Arduino side I test with [Sparkfun Mate Silver](https://www.sparkfun.com/products/10393) and the [Seeed Studio Bluetooth Shield](http://www.seeedstudio.com/depot/bluetooth-shield-p-866.html?cPath=19_21). The code should be generic and work with most hardware.

I highly recommend [Adafruit's Bluefruit EZ-Link](http://www.adafruit.com/products/1588).

### iOS

**NOTE: Currently iOS only works with RedBear Labs Hardware, Adafruit Bluefruit LE, Laird BL600, and BlueGiga UART services**

This plugin was originally developed with Cordova 3.4 using iOS 7.x on an iPhone 5s connecting to a [RedBearLab BLEMini](http://redbearlab.com/blemini). Ensure that you have update the BLE Mini firmware to at least [Biscuit-UART_20130313.bin](https://github.com/RedBearLab/Biscuit/tree/master/release).

Most development is now done with iOS 8 with Cordova 4.2 using [RedBear Lab BLE Shield](http://redbearlab.com/bleshield/) or [Adafruit Bluefruit LE Friend](https://www.adafruit.com/product/2267).

### Supporting other BLE hardware

For Bluetooth Low Energy, this plugin supports some hardware running known UART-like services, but can support any Bluetooth Low Energy hardware with a "serial like" service. This means a transmit characteristic that is writable and a receive characteristic that supports notification.

Edit [BLEdefines.h](src/ios/BLEDefines.h) and adjust the UUIDs for your service.

## Props

### Android

Most of the Bluetooth implementation was borrowed from the Bluetooth Chat example in the Android SDK.

### iOS

The iOS code uses RedBearLab's [BLE_Framework](https://github.com/RedBearLab/iOS/tree/master/BLEFramework/BLE).

### API

The API for available, read, readUntil was influenced by the [BtSerial Library for Processing for Arduino](https://github.com/arduino/BtSerial)

## Wrong Bluetooth Plugin?

If you don't need **serial** over Bluetooth, try the [PhoneGap Bluetooth Plugin for Android](https://github.com/phonegap/phonegap-plugins/tree/DEPRECATED/Android/Bluetooth/2.2.0) or perhaps [phonegap-plugin-bluetooth](https://github.com/tanelih/phonegap-bluetooth-plugin).

If you need generic Bluetooth Low Energy support checkout my [Cordova BLE Plugin](https://github.com/don/cordova-plugin-ble-central).

If you need BLE for RFduino checkout my [RFduino Plugin](https://github.com/don/cordova-plugin-rfduino).

## What format should the Mac Address be in?
An example a properly formatted mac address is ``AA:BB:CC:DD:EE:FF``

## Feedback

Try the code. If you find an problem or missing feature, file an issue or create a pull request.
