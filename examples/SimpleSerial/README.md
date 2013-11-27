# Simple Serial Example

Pair your phone with the remote bluetooth device.

Edit www/js/index.js and set app.macAddress to the MAC address of the remote bluetooth adapter.

Install the Bluetooth Serial Cordova plugin

    $ cordova plugin add com.megster.cordova.bluetoothserial

Create an Android project

    $ cordova platform add android
    
Build and deploy the code to your Android device

    $ cordova run
    
Sometimes it might take more than one time to connect to the remove device.