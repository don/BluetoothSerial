//
//  MEGBluetoothSerial.h
//  Bluetooth Serial Cordova Plugin
//
//  Created by Don Coleman on 5/21/13.
//
//

#ifndef SimpleSerial_MEGBluetoothSerial_h
#define SimpleSerial_MEGBluetoothSerial_h

#import <Cordova/CDV.h>
#import "BLE.h"

@interface MEGBluetoothSerial : CDVPlugin <BLEDelegate> {
    BLE *_bleShield;
    NSString* _connectCallbackId;
    NSString* _subscribeCallbackId;
    NSMutableString *_buffer;
    NSString *_delimiter;
}

- (void)connect:(CDVInvokedUrlCommand *)command;
- (void)disconnect:(CDVInvokedUrlCommand *)command;

- (void)subscribe:(CDVInvokedUrlCommand *)command;
- (void)write:(CDVInvokedUrlCommand *)command;

- (void)list:(CDVInvokedUrlCommand *)command;
- (void)isEnabled:(CDVInvokedUrlCommand *)command;
- (void)isConnected:(CDVInvokedUrlCommand *)command;

- (void)available:(CDVInvokedUrlCommand *)command;
- (void)read:(CDVInvokedUrlCommand *)command;
- (void)readUntil:(CDVInvokedUrlCommand *)command;
- (void)clear:(CDVInvokedUrlCommand *)command;

@end

#endif
