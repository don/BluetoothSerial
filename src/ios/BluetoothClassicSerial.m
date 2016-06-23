#import "BluetoothClassicSerial.h"

@implementation BluetoothClassicSerial

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
    self.deviceDiscoveredCallbackID = nil;
    self.sessionDataReadCallbackID = nil;
    self.readDelimiter = nil;

    // Initialise base bluetooth settings
    self.bluetoothEnabled = false;

    // State the core bluetooth central manager
    self.bluetoothManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];

    // Register for accessory manager notifications
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(accessoryConnected:) name:EAAccessoryDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(accessoryDisconnected:) name:EAAccessoryDidDisconnectNotification object:nil];
    [[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications];

    // Grab the available protocol strings from the plist and set the highest one as the default protocol string
    NSArray *protocolStrings = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UISupportedExternalAccessoryProtocols"];
    if (protocolStrings.count > 0) {
        self.protocolString = protocolStrings[0];
    }

}

#pragma mark - Cordova Plugin Methods

- (void)clearDeviceDiscoveredListener:(CDVInvokedUrlCommand *)command {
    self.deviceDiscoveredCallbackID = nil;
}

- (void)setDeviceDiscoveredListener:(CDVInvokedUrlCommand *)command {
    self.deviceDiscoveredCallbackID = command.callbackId;
}

- (void)subscribe:(CDVInvokedUrlCommand *)command {

    // Save the callback for read data
    self.sessionDataReadCallbackID = command.callbackId;

    // Grab the read delimiter
    NSString *delimiter = [command.arguments objectAtIndex:0];

    CDVPluginResult *pluginResult = nil;

    if (delimiter != nil) {
        self.readDelimiter = delimiter;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendDataToSubscriber:) name:self.SessionDataReceivedNotification object:nil];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Delimiter was null"];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];


}

- (void)unsubscribe:(CDVInvokedUrlCommand *)command {

    // Remove the notification and the callback ID
    [[NSNotificationCenter defaultCenter] removeObserver:self name:self.SessionDataReceivedNotification object:nil];
    self.sessionDataReadCallbackID = nil;

    // Fire the success callback
    CDVPluginResult *pluginResult = nil;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

}

- (void)clear:(CDVInvokedUrlCommand *)command {

    CDVPluginResult *pluginResult = nil;

    // If we have a session read and discard of everything in the inputStream.
    if (self.session) {

        uint8_t buf[self.inputBufferSize];

        // Clear everything out of the input stream
        while ([[self.session inputStream] hasBytesAvailable]) {
            [[self.session inputStream] read:buf maxLength:self.inputBufferSize];
        }

    }

    // Reset read data
    self.readData = nil;

    // Fire the callback
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

}


- (void)isEnabled: (CDVInvokedUrlCommand *)command {

    // Check if the Bluetooth state has been updated
    [self centralManagerDidUpdateState: self.bluetoothManager];

    // Fire the appropriate callback based on the state
    CDVPluginResult *pluginResult = nil;
    if (self.bluetoothEnabled) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:true];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsBool:false];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

}


- (void)isConnected:(CDVInvokedUrlCommand*)command {

    CDVPluginResult *pluginResult = nil;

    // If we've got an accessory a session and the accessory is connected we're connected
    if ([self isCommunicationSessionOpen]) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:true];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsBool:false];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

}


- (void)disconnect:(CDVInvokedUrlCommand *)command {

    // Close the session with the device
    [self closeSession];

    CDVPluginResult *pluginResult = nil;

    if (self.session == nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:true];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsBool:false];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

}


- (void)connect:(CDVInvokedUrlCommand *)command {

    if (self.session) {
        [self closeSession];
    }

    CDVPluginResult *pluginResult = nil;
    bool inError = false;

    /* Set the connection ID. If a blank connectionID has been passed set it to 0.
     This will allow the connect method to instead connect to the first connected device that contains the correct protocol string.
     */
    NSUInteger connectionId;

    if ([command.arguments objectAtIndex:0] == (id)[NSNull null]) {
        connectionId = 0;
    } else {

        @try {
            connectionId = (NSUInteger)[[command.arguments objectAtIndex:0] integerValue];
        }
        @catch (NSException *e) {
            // If we've got any exception passing the connectionID into an integer then set in error
            inError = true;
        }

    }

    // If we're not in error then try and open a communication session
    if (!inError && [self openSessionForConnectionId:connectionId]) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:true];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsBool:false];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];


}


- (void)discoverUnpaired:(CDVInvokedUrlCommand *)command {

    [[EAAccessoryManager sharedAccessoryManager] showBluetoothAccessoryPickerWithNameFilter:nil completion:^(NSError *error){

        // If the user hits the cancel button on the prompt then return fail.
        if(error != nil &&
           (
                [error code] == EABluetoothAccessoryPickerResultCancelled
                || [error code] == EABluetoothAccessoryPickerResultNotFound
                || [error code] == EABluetoothAccessoryPickerResultFailed
            )
           ) {

            NSString *errorMessage;
            if ([error code] == EABluetoothAccessoryPickerResultCancelled) {
                errorMessage = @"Cancelled";
            } else if ([error code] == EABluetoothAccessoryPickerResultNotFound) {
                errorMessage = @"Device not found";
            } else {
                errorMessage = @"Device selection failed";
            }

            CDVPluginResult *pluginResult = nil;
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

        } else {

            bool sendBackList = false;

            // If the device was already connected send back the currently selected accessory.
            if (error != nil && [error code] == EABluetoothAccessoryPickerAlreadyConnected) {
                if (self.accessory != nil && [self.accessory isConnected]) {
                    NSMutableArray *dictArray = [[NSMutableArray alloc] init];
                    [dictArray insertObject:[self accessoryDetails:self.accessory] atIndex:0];
                    NSArray *accessoryDetailsArray = [NSArray arrayWithArray:dictArray];
                    CDVPluginResult *pluginResult = nil;
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:accessoryDetailsArray];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                } else {
                    sendBackList = true;
                }
            }

            if (sendBackList) {
                // Return a list of all devices
                [self list:command];
            }

        }
    }];

}


- (void)list:(CDVInvokedUrlCommand *)command {

    NSMutableArray *accessoriesList = [[NSMutableArray alloc] initWithArray:[[EAAccessoryManager sharedAccessoryManager] connectedAccessories]];

    NSMutableArray *dictArray = [[NSMutableArray alloc] init];

    for(int i = 0; i < [accessoriesList count]; i++){
        EAAccessory *accessory = [accessoriesList objectAtIndex:i];
        [dictArray insertObject:[self accessoryDetails:accessory] atIndex:i];

    }

    CDVPluginResult *pluginResult = nil;

    NSArray *array = [NSArray arrayWithArray:dictArray];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:array];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

}


- (void)write:(CDVInvokedUrlCommand *)command {

    CDVPluginResult *pluginResult = nil;

    if (self.session != nil) {

        NSString* rawMessage = [[NSString alloc] initWithData:[command.arguments objectAtIndex:0] encoding:NSUTF8StringEncoding];

        NSString *formattedMessage = [rawMessage stringByAppendingString:@"\r\n"];
        NSData *data = [formattedMessage dataUsingEncoding:NSASCIIStringEncoding];

        if (self.writeData == nil) {
            self.writeData = [[NSMutableData alloc] init];
        }

        [self.writeData appendData:data];
        [self writeSessionData];

        if (self.writeError) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"A write error occurred"];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        }

    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Communication session not open. Call connect() prior to using this method."];

    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

}


- (void)read:(CDVInvokedUrlCommand *)command {

    NSUInteger bytesAvailable = 0;
    NSMutableString *dataOuput = [[NSMutableString alloc] init];

    while ((bytesAvailable = [self.readData length]) > 0) {
        NSData *data = [self readHighData:bytesAvailable];
        if (data) {

            NSString* dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [dataOuput appendString:dataString];

        }
    }

    CDVPluginResult *pluginResult = nil;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:dataOuput];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

}


- (void)readUntil:(CDVInvokedUrlCommand*)command {

    CDVPluginResult *pluginResult = nil;
    NSString *delimiter = [command.arguments objectAtIndex:0];

    if (delimiter != nil) {
        NSString *message = [self readUntilDelimiter:delimiter];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Delimiter was null"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }

}

#pragma mark - Internal implementation methods

/**
 Read the input stream until a delimiter is found.
 */
- (NSString*)readUntilDelimiter: (NSString*) delimiter {

    NSString *dataString = [[NSString alloc] initWithData:self.readData encoding:NSUTF8StringEncoding];
    NSRange range = [dataString rangeOfString: delimiter];
    NSString *message = @"";

    if (range.location != NSNotFound) {

        long end = range.location + range.length;
        message = [dataString substringToIndex:end];

        NSRange truncate = NSMakeRange(0, end);
        [self.readData replaceBytesInRange:truncate withBytes:NULL length:0];
    }

    return message;
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
            self.writeError = true;
            break;
        } else if (bytesWritten > 0) {
            self.writeError = false;
            [self.writeData replaceBytesInRange:NSMakeRange(0, bytesWritten) withBytes:NULL length:0];
        }
    }

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

- (bool)isCommunicationSessionOpen {
    return self.session != nil && self.accessory != nil && self.accessory.isConnected;
}

/**
 Listener to watch for the appearance of a device and try to reestablish a connection to the device.
 */
- (void)accessoryConnected:(NSNotification *)notification {

    NSLog(@"EAController::accessoryConnected");

    // If we don't already have an accessory or if we have an accessory but it's not connected
    if (self.accessory == nil || ![self.accessory isConnected]) {

        NSLog(@"Setting the newly connected accessory");

        // Get the freshly connected accessory and set the connection ID
        self.accessory = [[notification userInfo] objectForKey:EAAccessoryKey];

        // If there's a device discovered listener then send back the device details
        if (self.deviceDiscoveredCallbackID != nil) {

            NSLog(@"Attempting to fire device discovered callback");
            [self fireDeviceDiscoveredListener:self.accessory];

        }

    }

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

    }

    // Remove data references
    self.readData = nil;
    self.accessory = nil;

}

-(void)fireDeviceDiscoveredListener:(EAAccessory *)accessory {

    // Copy the connected accessory details into an array and return it to the device discovered callback.
    NSArray *accessoryDetailsArray = [self accessoryDetails:accessory].copy;
    CDVPluginResult *pluginResult = nil;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:accessoryDetailsArray];
    [pluginResult setKeepCallbackAsBool:true];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.deviceDiscoveredCallbackID];

}

/**
 Will listen to determine if the accessory disconnects and then close the session.
 */
- (void)accessoryDisconnected:(NSNotification *)notification {
    NSLog(@"EAController::accessoryDisconnected");
    [self closeSession];
}

/**
 Open a communication session with an accessory based on a provided
 protocol string.
 */
- (bool)openSessionForConnectionId:(NSUInteger)connectionId {

    NSArray *accessories = [[EAAccessoryManager sharedAccessoryManager]
                            connectedAccessories];

    // Loop through the connected accessories. If we find one with the connectionID and the appropriate protocol. Connect.
    for (EAAccessory *obj in accessories) {

        if (
            (
             [obj connectionID] == connectionId
             && [[obj protocolStrings] containsObject:self.protocolString]
             )
            ||
            (
             connectionId == 0
             && [[obj protocolStrings] containsObject:self.protocolString]
             )
            ){
            self.accessory = obj;
            break;
        }

    }

    // If we've found an accessory then open a communication stream
    if (self.accessory != nil){
        [self.accessory setDelegate:self];
        self.session = [[EASession alloc] initWithAccessory:self.accessory
                                                forProtocol:self.protocolString];
        if (self.session) {
            [[_session inputStream] setDelegate:self];
            [[_session inputStream] scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                              forMode:NSDefaultRunLoopMode];
            [[_session inputStream] open];

            [[_session outputStream] setDelegate:self];
            [[_session outputStream] scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                               forMode:NSDefaultRunLoopMode];
            [[_session outputStream] open];
        }
    }

    return [self isCommunicationSessionOpen];

}

/**
 Build a dictionary of accessory details
 */
- (NSMutableDictionary*)accessoryDetails:(EAAccessory *)accessory {

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

    return accessoryDict;

}

/**
 Anytime data is read from the device this method will fire and the data can then be read and sent back to the Javascript API callback.
 */
- (void)sendDataToSubscriber:(NSNotification *)notification {

    NSLog(@"Session data received");

    // Make sure we have a callback method to fire
    if (self.sessionDataReadCallbackID != nil) {

        NSString *message = [self readUntilDelimiter:self.readDelimiter];

        if ([message length] > 0) {
            CDVPluginResult *pluginResult = nil;
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: message];
            [pluginResult setKeepCallbackAsBool:TRUE];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.sessionDataReadCallbackID];

            // Fire again until we've cleared the buffer.
            [self sendDataToSubscriber:nil];

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
 Session stream object reports events to this method.
 Anytime an input or output stream event occurs it is handled by this method.
 */
- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
    NSLog(@"stream:handleEvent: is invoked...");
    switch(eventCode) {
        case NSStreamEventErrorOccurred:
        case NSStreamEventEndEncountered: {
            NSLog(@"Stream error. Closing stream");
            [stream close];
            [stream removeFromRunLoop:[NSRunLoop currentRunLoop]
                              forMode:NSDefaultRunLoopMode];
            stream = nil;
            self.session = nil;
            break;
        }
        case NSStreamEventHasBytesAvailable: {
            [self readSessionData];
            break;
        }

        case NSStreamEventHasSpaceAvailable: {
            [self writeSessionData];
            break;
        }
        case NSStreamEventNone:
        case NSStreamEventOpenCompleted: {
            break;
        }
    }
}


@end