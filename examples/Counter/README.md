# PhoneGap Arduino Counter Example

Simple Bluetooth Example. Arduino increments a counter and sends the value over Bluetooth. Android phone displays the value.

Some assembly required.

I'll assume you've cloned https://github.com/don/BluetoothSerial into ~/BluetoothSerial

Copy the chat example to a new directory.  

    $ cp -R ~/BluetoothSerial/examples/Counter ~/Counter
    
You need to copy the project to a new directory, otherwise the plugin installer will fail.

## Arduino

Hardware
 * Arduino Uno
 * Bluetooth radio that support Serial Port Protocol (SPP)
     * [SparkFun Bluetooth Mate Silver](https://www.sparkfun.com/products/10393)
     * [Seeed Studio Bluetooth Shield](http://www.seeedstudio.com/depot/bluetooth-shield-p-866.html)

### Upload the sketch

Upload the [sketch](https://github.com/don/BluetoothSerial/blob/master/examples/Counter/Arduino/Counter/Counter.ino) to your Uno using the Arduino IDE.

### Pair your phone

Pair your Android phone with the bluetooth adapter.

## PhoneGap

### Install Cordova

    $ npm install cordova -g

### Android SDK

This assumes you have the [Android SDK](http://developer.android.com/sdk/index.html) installed and $ANDROID_HOME/tools and $ANDROID_HOME/platform-tools in your system path

### Edit Mac Address of Bluetooth Radio

Edit [assets/www/js/index.js](http://github.com/don/BluetoothSerial/examples/LED/assets/www/js/index.js) and change the Mac Address to match the address of **your** Bluetooth modem.

### Install Platform and Plugin

    $ cordova platform add android
    $ cordova plugin add cordova-plugin-bluetooth-serial

### Build and Deploy

Compile and run the application

    $ cordova run android
    