# Simple Serial Example

Pair your phone with the remote Bluetooth device.

Edit www/js/index.js and set app.macAddress to the MAC address of the remote Bluetooth adapter.

Install the Bluetooth Serial Cordova plugin

    $ cordova plugin add cordova-plugin-bluetooth-serial

Create an Android project

    $ cordova platform add android
    
Build and deploy the code to your Android device

    $ cordova run
    
This code also works on iOS if you have one of the limited Bluetooth Low Energy adapters this plugin supports. See [the documentation](https://github.com/don/BluetoothSerial/blob/master/README.md) for more info.

Edit www/js/index.js and set app.macAddress to the **UUID** of your Bluetooth adapter.

    $ cordova platform add ios
    $ open platforms/ios/SimpleSerial.xcodeproj
    
Deploy to your iPhone with Xcode.
