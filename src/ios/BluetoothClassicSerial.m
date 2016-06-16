#import "BluetoothClassicSerial.h"

@implementation BluetoothClassicSerial

/**
 Initialisation code for the plugin goes in here.
 */
- (void)pluginInitialize {

    // Initialise properties
    self.accessory = nil;
    self.session = nil;
    self.protocolString = nil;
    self.writeData = nil;
    self.writeError = nil;
    self.readData = nil;
    self.SessionDataReceivedNotification = @"SessionDataReceivedNotification";
    self.inputBufferSize = 128;

    // Initialise base bluetooth settings
    self.bluetoothEnabled = false;

    // State the core bluetooth central manager
    self.bluetoothManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];

    // Register for accessory manager notifications
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(accessoryConnected:) name:EAAccessoryDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(accessoryDisconnected:) name:EAAccessoryDidDisconnectNotification object:nil];
    [[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications];

}


/**
 To report on whether Bluetooth is enabled on the target device.
 */
- (void)isEnabled: (CDVInvokedUrlCommand *)command {

//    [self.commandDelegate runInBackground:^{

        // Check if the Bluetooth state has been updated
        [self centralManagerDidUpdateState: self.bluetoothManager];

        // Fire the appropriate callback based on the state
        CDVPluginResult *pluginResult = nil;
        if (self.bluetoothEnabled) {
            NSLog(@"Bluetooth enabled");
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        } else {
            NSLog(@"Bluetooth disabled");
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        }

        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

//    }];

}

/**
 Checks the Core Bluetooth Central Manager state to determine if Bluetooth is enabled or not.
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {

    if([central state] == CBCentralManagerStatePoweredOn) {
        self.bluetoothEnabled = true;
    } else {
        self.bluetoothEnabled = false;
    }
}

/**
 To report whether or not we're currently connected to the device.
 */
- (void)isConnected:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{

        CDVPluginResult *pluginResult = nil;

        // If we've got an accessory and a session then we're connected.
        if (self.session != nil && self.accessory != nil) {
            NSLog(@"Connected");
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        } else {
            NSLog(@"Disconnected");
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        }

        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

    }];
}

/**
 Close the session with the accessory.
 */
- (void)closeSession {

    NSLog(@"Closing session");
    if (self.session != nil) {

        // Close off the input and output streams
        [[self.session inputStream] removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [[self.session inputStream] setDelegate:nil];
        [[self.session inputStream] close];

        [[self.session outputStream] removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [[self.session outputStream] setDelegate:nil];
        [[self.session outputStream] close];

        // Reset the session
        self.session = nil;
        self.readData = nil;

    }

}

/**
 Disconnect from a device
 */
- (void)disconnect:(CDVInvokedUrlCommand *)command {

//    [self.commandDelegate runInBackground:^{

        // Close the session with the device
        [self closeSession];

        CDVPluginResult *pluginResult = nil;

        if (self.session == nil) {
            NSLog(@"Disconnected");
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        } else {
            NSLog(@"Failed to disconnect");
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        }

        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

//    }];

}

/**
 Listener to watch for the appearance of a device and try to reestablish a connection to the device.
 */
- (void)accessoryConnected:(NSNotification *)notification {

    NSLog(@"EAController::accessoryConnected");

    // If we don't have an existing session and we do have a protocol string then reconnect to the device.
    if(!self.session && self.protocolString){
        [self openSessionForProtocol:self.protocolString];
    }
}


/**
 Will listen to determine if the accessory disconnects and then close the session.
 */
- (void)accessoryDisconnected:(NSNotification *)notification {
    NSLog(@"EAController::accessoryDisconnected");
    [self closeSession];
}


/**
 Connect to a device using protocol string
 Can't run this in the background as it affects the input output stream event handlers
 which are trying to run on the currentRunLoop.
 */
- (void)connect: (CDVInvokedUrlCommand *)command {

//    [self.commandDelegate runInBackground:^{


        if (self.session) {
            [self closeSession];
        }

        self.sessionCommand = command;

        self.protocolString = [command.arguments objectAtIndex:0];
        [self openSessionForProtocol:self.protocolString];

//    }];

}


/**
 Open a communication session with an accessory based on a provided
 protocol string.
 */
- (void)openSessionForProtocol:(NSString *)protocolString {

    NSArray *accessories = [[EAAccessoryManager sharedAccessoryManager]
                            connectedAccessories];

    for (EAAccessory *obj in accessories) {
        if ([[obj protocolStrings] containsObject:protocolString]){
            self.accessory = obj;
            break;
        }
    }

    if (self.accessory != nil){
        [self.accessory setDelegate:self];
        self.session = [[EASession alloc] initWithAccessory:self.accessory
                                            forProtocol:protocolString];
        if (self.session) {
            [[_session inputStream] setDelegate:self];
            [[_session inputStream] scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                              forMode:NSDefaultRunLoopMode];
            [[_session inputStream] open];

            [[_session outputStream] setDelegate:self];
            [[_session outputStream] scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                               forMode:NSDefaultRunLoopMode];
            [[_session outputStream] open];
            NSLog(@"Open session");
        }
    }

    CDVPluginResult *pluginResult = nil;

    if (self.accessory != nil && self.session != nil) {
        NSLog(@"Opened session with device");
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        NSLog(@"Could not open session with device");
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.sessionCommand.callbackId];

}

/**
 To discover any unpaired accessories. This will prompt the user to select a device. If the user
 selects a device the connected accessory list is returned.
 The contents of this method cannot be runInBackground - causes NSException.
 */
- (void)discoverUnpaired:(CDVInvokedUrlCommand *)command {

    [[EAAccessoryManager sharedAccessoryManager] showBluetoothAccessoryPickerWithNameFilter:nil completion:^(NSError *error){
        NSLog(@"EAAccessoryManager::showBluetoothAccessoryPickerWithNameFilter");

        // If the user hits the cancel button on the prompt then return fail.
        if(error != nil &&
           (
                [error code] == EABluetoothAccessoryPickerResultCancelled
                || [error code] == EABluetoothAccessoryPickerResultNotFound
                || [error code] == EABluetoothAccessoryPickerResultFailed
            )
           ) {

            NSLog(@"Bluetooth picker cancelled or result not found");
            CDVPluginResult *pluginResult = nil;
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

        } else {
            // Return the list of devices to the callback.
            [self list:command];
        }
    }];

}

/**
 List any currently connected devices.
 */
- (void)list:(CDVInvokedUrlCommand *)command {

    NSLog(@"Listing connected devices");

    self.accessoriesList = [[NSMutableArray alloc] initWithArray:[[EAAccessoryManager sharedAccessoryManager] connectedAccessories]];

    NSMutableArray *dictArray = [[NSMutableArray alloc] init];

    for(int i = 0; i < [self.accessoriesList count]; i++){
        EAAccessory *accessory = [self.accessoriesList objectAtIndex:i];
        NSMutableDictionary *accessoryDict = [[NSMutableDictionary alloc] init];

        [accessoryDict setValue:[NSNumber numberWithBool:accessory.connected] forKeyPath:@"connected"];
        [accessoryDict setValue:[NSNumber numberWithLong:accessory.connectionID] forKeyPath:@"connectionID"];
        [accessoryDict setValue:accessory.name forKey:@"name"];
        [accessoryDict setValue:accessory.manufacturer forKeyPath:@"manufacturer"];
        [accessoryDict setValue:accessory.modelNumber forKeyPath:@"modelNumber"];
        [accessoryDict setValue:accessory.serialNumber forKeyPath:@"serialNumber"];
        [accessoryDict setValue:accessory.firmwareRevision forKeyPath:@"firmwareRevision"];
        [accessoryDict setValue:accessory.hardwareRevision forKeyPath:@"hardwareRevision"];
        [accessoryDict setValue:accessory.protocolStrings forKeyPath:@"protocols"];

        [dictArray insertObject:accessoryDict atIndex:i];

    }

    NSLog(@"%@", dictArray);

    CDVPluginResult *pluginResult = nil;

    if (self.accessoriesList > 0) {
        NSArray *array = [NSArray arrayWithArray:dictArray];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:array];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

}

/**
 Write a message to the device's serial port
 */
- (void)write:(CDVInvokedUrlCommand *)command {

//    [self.commandDelegate runInBackground:^{

    if (self.session != nil) {

        NSString* rawMessage = [[NSString alloc] initWithData:[command.arguments objectAtIndex:0] encoding:NSUTF8StringEncoding];

        NSString *formattedMessage = [rawMessage stringByAppendingString:@"\r\n"];
        NSData *data = [formattedMessage dataUsingEncoding:NSASCIIStringEncoding];

        NSLog(@"Raw data: %@", rawMessage);
        NSLog(@"Formatted data: %@", formattedMessage);

        self.writeData = [[NSMutableData alloc] init];
        [self.writeData appendData:data];

        [self writeSessionData];

        CDVPluginResult *pluginResult = nil;

        if (self.writeError) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        }

        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }


//    }];

}

/**
 Subscribe to be notified when data is received from the device
 */
- (void)subscribe:(CDVInvokedUrlCommand *)command {
//    [self.commandDelegate runInBackground:^{
        NSLog(@"Subscribing to device notifications");
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionDataReceived:) name:self.SessionDataReceivedNotification object:nil];
//    }];
}

/**
 Unsubscribe from the data received notification
 */
- (void)unsubscribe:(CDVInvokedUrlCommand *)command {
//    [self.commandDelegate runInBackground:^{
        NSLog(@"Unsubscribing from device notifications");
        [[NSNotificationCenter defaultCenter] removeObserver:self name:self.SessionDataReceivedNotification object:nil];
//    }];
}

/**
 Anytime data is read from the device this method will fire and the data can then be read and sent back to the Javascript API callback.
 */
- (void)sessionDataReceived:(NSNotification *)notification {

    NSLog(@"Session data received");
    uint32_t bytesAvailable = 0;

    while ((bytesAvailable = [self.readData length]) > 0) {
        NSData *data = [self readHighData:bytesAvailable];
        if (data) {
            NSString* newStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"Data received = %@", newStr);
        }
    }
}

/**
 High level read data method. Accepts the number of bytes to read and reads those bytes from self.readData property.
 */
- (NSData *)readHighData:(NSUInteger)bytesToRead
{
    NSData *data = nil;
    if ([self.readData length] >= bytesToRead) {
        NSRange range = NSMakeRange(0, bytesToRead);
        data = [self.readData subdataWithRange:range];
        [self.readData replaceBytesInRange:range withBytes:NULL length:0];
    }
    return data;
}

/**
 Low level read data method
 Reads data in from the inputStream if the stream has bytes available.
 */
- (void)readSessionData {

    NSLog(@"Reading session data");
    uint8_t buf[self.inputBufferSize];
    while ([[self.session inputStream] hasBytesAvailable])
    {
        NSInteger bytesRead = [[self.session inputStream] read:buf maxLength:self.inputBufferSize];
        if (self.readData == nil) {
            self.readData = [[NSMutableData alloc] init];
        }
        [self.readData appendBytes:(void *)buf length:bytesRead];
    }

    // When data is read in from the session send to the received notification.
    [[NSNotificationCenter defaultCenter] postNotificationName:self.SessionDataReceivedNotification object:self userInfo:nil];
}

/**
 Low level write method. Writes NSData to the outputstream.
 If a write error occurs it is saved as a property against the object so that higher level plugin
 methods can use that error to determine the appropriate state for return to the JS API.
 */
-(void)writeSessionData {

    // Default write error state. Set to error if outputStream doesn't have space available or or the data length is 0.
    self.writeError = true;

    while (([[self.session outputStream] hasSpaceAvailable]) && ([self.writeData length] > 0))
    {
        // Write the bytes to the outputStream
        NSInteger bytesWritten = [[self.session outputStream] write:[self.writeData bytes] maxLength:[self.writeData length]];

        // Determine state.
        if (bytesWritten == -1) {
            NSLog(@"write error");
            self.writeError = true;
            break;
        } else if (bytesWritten > 0) {
            self.writeError = false;
            [self.writeData replaceBytesInRange:NSMakeRange(0, bytesWritten) withBytes:NULL length:0];
        }
    }

}


/**
 Session stream object reports events to this method.
 Anytime an input or output stream event occurs it is handled by this method.
 */
- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
    NSLog(@"stream:handleEvent: is invoked...");
    switch(eventCode) {
        case NSStreamEventErrorOccurred: {
            NSLog(@"Stream error. Closing stream");
            [stream close];
            [stream removeFromRunLoop:[NSRunLoop currentRunLoop]
                              forMode:NSDefaultRunLoopMode];
            self.session = nil;
            break;
        }
        case NSStreamEventHasBytesAvailable: {
            [self readSessionData];
            break;
        }

        case NSStreamEventHasSpaceAvailable: {
            NSLog(@"Stream has space avaiable");
            [self writeSessionData];
            break;
        }
        case NSStreamEventNone: {
            break;
        }
        case NSStreamEventOpenCompleted: {
            break;
        }
        case NSStreamEventEndEncountered: {
            [stream close];
            [stream removeFromRunLoop:[NSRunLoop currentRunLoop]
                              forMode:NSDefaultRunLoopMode];
            stream = nil;
            self.session = nil;
            break;
        }
    }
}


@end