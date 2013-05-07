# Bluetooth Serial Plugin for PhoneGap

This plugin enables serial communication over Bluetooth. It was written for communicating between Android and an Arduino.

## Supported Platforms

* Android

## Limitations

 * The phone must initiate the Bluetooth connection
 * Data sent over the connection is assumed to be Strings

# Installing 

Use [plugman](https://github.com/imhotep/plugman) to add BluetoothSerial to your Android project.  Plugman requires [node.js](http://nodejs.org) and is installed through npm.

Install plugman

    $ npm install -g plugman

Get the latest source code

    $ git clone https://github.com/don/BluetoothSerial.git

Install the plugin

    $ plugman --platform android --project /path/to/your/project --plugin /path/to/BluetoothSerial

Modify your HTML to include bluetoothSerial.js

    <script type="text/javascript" src="js/bluetoothSerial.js"></script>

Require bluetoothSerial in your JavaScript

    var bluetoothSerial = cordova.require('bluetoothSerial');
    
# Props

Most of the Bluetooth implementation was borrows from the Bluetooth Chat example in the Android SDK.

The API for available, read, readUntil was influenced by the [BtSerial Library for Processing for Arduino](https://github.com/arduino/BtSerial)

# Wrong Bluetooth Plugin?

If you don't need **serial** over Bluetooth, try the [PhoneGap Bluetooth Plugin for Android](https://github.com/phonegap/phonegap-plugins/tree/master/Android/Bluetooth)

# Feedback
    
Try the code. If you find an problem, file an issue or create a pull request!

