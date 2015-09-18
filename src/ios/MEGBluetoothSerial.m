//
//  MEGBluetoothSerial.m
//  Bluetooth Serial Cordova Plugin
//
//  Created by Don Coleman on 5/21/13.
//
//

#import "MEGBluetoothSerial.h"
#import <Cordova/CDV.h>

@interface MEGBluetoothSerial()
- (NSString *)readUntilDelimiter:(NSString *)delimiter;
- (NSMutableArray *)getPeripheralList;
- (void)sendDataToSubscriber;
- (CBPeripheral *)findPeripheralByUUID:(NSString *)uuid;
- (void)connectToUUID:(NSString *)uuid;
- (void)listPeripheralsTimer:(NSTimer *)timer;
- (void)connectFirstDeviceTimer:(NSTimer *)timer;
- (void)connectUuidTimer:(NSTimer *)timer;
@end

@implementation MEGBluetoothSerial

- (void)pluginInitialize {

    NSLog(@"Bluetooth Serial Cordova Plugin - BLE version");
    NSLog(@"(c)2013-2014 Don Coleman");

    [super pluginInitialize];

    _bleShield = [[BLE alloc] init];
    [_bleShield controlSetup];
    [_bleShield setDelegate:self];

    _buffer = [[NSMutableString alloc] init];
}

#pragma mark - Cordova Plugin Methods

- (void)connect:(CDVInvokedUrlCommand *)command {

    NSLog(@"connect");
    NSString *uuid = [command.arguments objectAtIndex:0];

    // if the uuid is null or blank, scan and
    // connect to the first available device

    if (uuid == (NSString*)[NSNull null]) {
        [self connectToFirstDevice];
    } else if ([uuid isEqualToString:@""]) {
        [self connectToFirstDevice];
    } else {
        [self connectToUUID:uuid];
    }

    _connectCallbackId = [command.callbackId copy];
}

- (void)disconnect:(CDVInvokedUrlCommand*)command {

    NSLog(@"disconnect");

    _connectCallbackId = nil;
    CDVPluginResult *pluginResult = nil;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];

    if (_bleShield.activePeripheral) {
        if(_bleShield.activePeripheral.state == CBPeripheralStateConnected)
        {
            [[_bleShield CM] cancelPeripheralConnection:[_bleShield activePeripheral]];
        }
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)subscribe:(CDVInvokedUrlCommand*)command {
    NSLog(@"subscribe");

    CDVPluginResult *pluginResult = nil;
    NSString *delimiter = [command.arguments objectAtIndex:0];

    if (delimiter != nil) {
        _subscribeCallbackId = [command.callbackId copy];
        _delimiter = [delimiter copy];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"delimiter was null"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)unsubscribe:(CDVInvokedUrlCommand*)command {
    NSLog(@"unsubscribe");

    _delimiter = nil;
    _subscribeCallbackId = nil;

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)subscribeRaw:(CDVInvokedUrlCommand*)command {
    NSLog(@"subscribeRaw");

    _subscribeBytesCallbackId = [command.callbackId copy];
}

- (void)unsubscribeRaw:(CDVInvokedUrlCommand*)command {
    NSLog(@"unsubscribeRaw");

    _subscribeBytesCallbackId = nil;

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


- (void)write:(CDVInvokedUrlCommand*)command {
    NSLog(@"write");

    CDVPluginResult *pluginResult = nil;
    NSData *data  = [command.arguments objectAtIndex:0];

    if (data != nil) {

        [_bleShield write:data];

        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"data was null"];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)list:(CDVInvokedUrlCommand*)command {

    [self scanForBLEPeripherals:3];

    [NSTimer scheduledTimerWithTimeInterval:(float)3.0
                                     target:self
                                   selector:@selector(listPeripheralsTimer:)
                                   userInfo:[command.callbackId copy]
                                    repeats:NO];
}

- (void)isEnabled:(CDVInvokedUrlCommand*)command {

    // short delay so CBCentralManger can spin up bluetooth
    [NSTimer scheduledTimerWithTimeInterval:(float)0.2
                                     target:self
                                   selector:@selector(bluetoothStateTimer:)
                                   userInfo:[command.callbackId copy]
                                    repeats:NO];

}

- (void)isConnected:(CDVInvokedUrlCommand*)command {

    CDVPluginResult *pluginResult = nil;

    if (_bleShield.isConnected) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Not connected"];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)available:(CDVInvokedUrlCommand*)command {
    CDVPluginResult *pluginResult = nil;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:[_buffer length]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)read:(CDVInvokedUrlCommand*)command {
    CDVPluginResult *pluginResult = nil;
    NSString *message = @"";

    if ([_buffer length] > 0) {
        int end = [_buffer length] - 1;
        message = [_buffer substringToIndex:end];
        NSRange entireString = NSMakeRange(0, end);
        [_buffer deleteCharactersInRange:entireString];
    }

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)readUntil:(CDVInvokedUrlCommand*)command {

    NSString *delimiter = [command.arguments objectAtIndex:0];
    NSString *message = [self readUntilDelimiter:delimiter];
    CDVPluginResult *pluginResult = nil;

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)clear:(CDVInvokedUrlCommand*)command {
    int end = [_buffer length] - 1;
    NSRange truncate = NSMakeRange(0, end);
    [_buffer deleteCharactersInRange:truncate];
}

- (void)readRSSI:(CDVInvokedUrlCommand*)command {
    NSLog(@"readRSSI");

    _rssiCallbackId = [command.callbackId copy];
    [_bleShield readRSSI];
}

#pragma mark - BLEDelegate

- (void)bleDidReceiveData:(unsigned char *)data length:(int)length {
    NSLog(@"bleDidReceiveData");

    // Append to the buffer
    NSData *d = [NSData dataWithBytes:data length:length];
    NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    NSLog(@"Received %@", s);

    if (s) {
        [_buffer appendString:s];

        if (_subscribeCallbackId) {
            [self sendDataToSubscriber]; // only sends if a delimiter is hit
        }

    } else {
        NSLog(@"Error converting received data into a String.");
    }

    // Always send raw data if someone is listening
    if (_subscribeBytesCallbackId) {
        NSData* nsData = [NSData dataWithBytes:(const void *)data length:length];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArrayBuffer:nsData];
        [pluginResult setKeepCallbackAsBool:TRUE];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_subscribeBytesCallbackId];
    }

}

- (void)bleDidConnect {
    NSLog(@"bleDidConnect");
    CDVPluginResult *pluginResult = nil;

    if (_connectCallbackId) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [pluginResult setKeepCallbackAsBool:TRUE];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_connectCallbackId];
    }
}

- (void)bleDidDisconnect {
    // TODO is there anyway to figure out why we disconnected?
    NSLog(@"bleDidDisconnect");

    CDVPluginResult *pluginResult = nil;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Disconnected"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:_connectCallbackId];

    _connectCallbackId = nil;
}

- (void)bleDidUpdateRSSI:(NSNumber *)rssi {
    if (_rssiCallbackId) {
        CDVPluginResult *pluginResult = nil;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDouble:[rssi doubleValue]];
        [pluginResult setKeepCallbackAsBool:TRUE]; // TODO let expire, unless watching RSSI
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_rssiCallbackId];
    }
}

#pragma mark - timers

-(void)listPeripheralsTimer:(NSTimer *)timer {
    NSString *callbackId = [timer userInfo];
    NSMutableArray *peripherals = [self getPeripheralList];

    CDVPluginResult *pluginResult = nil;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray: peripherals];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

-(void)connectFirstDeviceTimer:(NSTimer *)timer {

    if(_bleShield.peripherals.count > 0) {
        NSLog(@"Connecting");
        [_bleShield connectPeripheral:[_bleShield.peripherals objectAtIndex:0]];
    } else {
        NSString *error = @"Did not find any BLE peripherals";
        NSLog(@"%@", error);
        CDVPluginResult *pluginResult;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_connectCallbackId];
    }
}

-(void)connectUuidTimer:(NSTimer *)timer {

    NSString *uuid = [timer userInfo];

    CBPeripheral *peripheral = [self findPeripheralByUUID:uuid];

    if (peripheral) {
        [_bleShield connectPeripheral:peripheral];
    } else {
        NSString *error = [NSString stringWithFormat:@"Could not find peripheral %@.", uuid];
        NSLog(@"%@", error);
        CDVPluginResult *pluginResult;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_connectCallbackId];
    }
}

- (void)bluetoothStateTimer:(NSTimer *)timer {

    NSString *callbackId = [timer userInfo];
    CDVPluginResult *pluginResult = nil;

    int bluetoothState = [[_bleShield CM] state];

    BOOL enabled = bluetoothState == CBCentralManagerStatePoweredOn;

    if (enabled) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsInt:bluetoothState];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

#pragma mark - internal implemetation

- (NSString*)readUntilDelimiter: (NSString*) delimiter {

    NSRange range = [_buffer rangeOfString: delimiter];
    NSString *message = @"";

    if (range.location != NSNotFound) {

        int end = range.location + range.length;
        message = [_buffer substringToIndex:end];

        NSRange truncate = NSMakeRange(0, end);
        [_buffer deleteCharactersInRange:truncate];
    }
    return message;
}

- (NSMutableArray*) getPeripheralList {

    NSMutableArray *peripherals = [NSMutableArray array];

    for (int i = 0; i < _bleShield.peripherals.count; i++) {
        NSMutableDictionary *peripheral = [NSMutableDictionary dictionary];
        CBPeripheral *p = [_bleShield.peripherals objectAtIndex:i];

        NSString *uuid = p.identifier.UUIDString;
        [peripheral setObject: uuid forKey: @"uuid"];
        [peripheral setObject: uuid forKey: @"id"];

        NSString *name = [p name];
        if (!name) {
            name = [peripheral objectForKey:@"uuid"];
        }
        [peripheral setObject: name forKey: @"name"];

        NSNumber *rssi = [p advertisementRSSI];
        if (rssi) { // BLEShield doesn't provide advertised RSSI
            [peripheral setObject: rssi forKey:@"rssi"];
        }

        [peripherals addObject:peripheral];
    }

    return peripherals;
}

// calls the JavaScript subscriber with data if we hit the _delimiter
- (void) sendDataToSubscriber {

    NSString *message = [self readUntilDelimiter:_delimiter];

    if ([message length] > 0) {
        CDVPluginResult *pluginResult = nil;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: message];
        [pluginResult setKeepCallbackAsBool:TRUE];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_subscribeCallbackId];

        [self sendDataToSubscriber];
    }

}

// Ideally we'd get a callback when found, maybe _bleShield can be modified
// to callback on centralManager:didRetrievePeripherals. For now, use a timer.
- (void)scanForBLEPeripherals:(int)timeout {

    NSLog(@"Scanning for BLE Peripherals");

    // disconnect
    if (_bleShield.activePeripheral) {
        if(_bleShield.activePeripheral.state == CBPeripheralStateConnected)
        {
            [[_bleShield CM] cancelPeripheralConnection:[_bleShield activePeripheral]];
            return;
        }
    }

    // remove existing peripherals
    if (_bleShield.peripherals) {
        _bleShield.peripherals = nil;
    }

    [_bleShield findBLEPeripherals:timeout];
}

- (void)connectToFirstDevice {

    [self scanForBLEPeripherals:3];

    [NSTimer scheduledTimerWithTimeInterval:(float)3.0
                                     target:self
                                   selector:@selector(connectFirstDeviceTimer:)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)connectToUUID:(NSString *)uuid {

    int interval = 0;

    if (_bleShield.peripherals.count < 1) {
        interval = 3;
        [self scanForBLEPeripherals:interval];
    }

    [NSTimer scheduledTimerWithTimeInterval:interval
                                     target:self
                                   selector:@selector(connectUuidTimer:)
                                   userInfo:uuid
                                    repeats:NO];
}

- (CBPeripheral*)findPeripheralByUUID:(NSString*)uuid {

    NSMutableArray *peripherals = [_bleShield peripherals];
    CBPeripheral *peripheral = nil;

    for (CBPeripheral *p in peripherals) {

        NSString *other = p.identifier.UUIDString;

        if ([uuid isEqualToString:other]) {
            peripheral = p;
            break;
        }
    }
    return peripheral;
}

@end
