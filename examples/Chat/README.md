## Bluetooth Serial Chat Example

This example program demonstrates using the Bluetooth Serial Cordova plugin for communications between a iOS or Android phone and an Arduino.  It is not very useful for chat, but it demonstrates sending data to and receiving data from the Arduino.  This should help you integrate Bluetooth Serial into your PhoneGap projects.

Some assembly required.

I'll assume you've cloned https://github.com/don/BluetoothSerial into ~/BluetoothSerial

Copy the chat example to a new directory.  

    $ cp -R ~/BluetoothSerial/examples/Chat ~/Chat

This code requires [cordova-cli](https://github.com/apache/cordova-cli), which require [node.js](http://nodejs.org)

    $ npm install cordova -g

Adding platforms generates the native projects

    $ cd ~/Chat
    $ cordova platform add android
    $ cordova platform add ios

Install the Bluetooth Serial plugin with cordova

    $ cordova plugin add cordova-plugin-bluetooth-serial

This code requires an Android device since the emulator does not support Bluetooth. Pair your Android device the Bluetooth modem running on the Arduino.

Build and deploy to an Android device. (Emulate deploys to the connected device.)

    $ cordova run android

The code requires an iOS device, rather than the emulator, since the emulator doesn't support Bluetooth.  The iOS version uses Bluetooth Low Energy, so there's no need to pair with the remove device.  The iOS code *only* connects to BLE peripherals running a known UART-like services. See [BluetoothSerial](http://github.com/don/BluetoothSerial) the latest list of supported BLE hardware.

Build the code

    $ cordova build ios

Open Xcode and deploy to your device

    $ open platforms/ios/Chat.xcodeproj

NOTE: Don't edit the HTML or JS in the generated projects. Edit the source in ~/BluetoothSerial/examples/Chat/www and rebuild with cordova-cli.

See the Arduino Folder for Sketches

    Red Bear Labs BLEMini
    SeeedStudio Bluetooth Shield
    Sparkfun Bluetooth Mate Silver
