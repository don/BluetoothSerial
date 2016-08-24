#import "CommunicationSession.h"

@implementation CommunicationSession

- (id)init:(EAAccessory *)accessory :(NSString *)protocolString :(id <CDVCommandDelegate>)commandDelegate  {
    self = [super init];
    if (self) {

        // Set the accessory and protocol string against the object
        self.accessory = accessory;
        self.protocolString = protocolString;
        self.commandDelegate = commandDelegate;

        // Initialize properties
        self.writeBuffer = nil;
        self.readBuffer = nil;
        self.subscribeCallbackId = nil;
        self.readDelimiter = nil;
        self.subscribeRawDataCallbackID = nil;
        self.inputBufferSize = 128;

    }

    return self;
}

- (void)removeSubscribeObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:self.protocolString object:nil];
}

- (void)addSubscribeCallbackAndObserver: (NSString *)subscribeCallbackId {
    [self removeSubscribeObserver];
    self.subscribeCallbackId = subscribeCallbackId;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendSubscribeData:) name:self.protocolString object:nil];
}

- (void)sendSubscribeData:(NSNotification *)notification {

    // Make sure we have a callback method to fire
    if (self.subscribeCallbackId != nil) {

        NSString *message = [self readUntilDelimiter:self.readDelimiter];
        if ([message length] > 0) {
            CDVPluginResult *pluginResult = nil;
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: message];
            [pluginResult setKeepCallbackAsBool:TRUE];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.subscribeCallbackId];

            // Fire again until we've cleared the buffer.
            [self sendSubscribeData:nil];

        }

    }
}

- (void)unsubscribe {

    // Remove any subscribe callback id
    self.subscribeCallbackId = nil;

    // Remove the observer.
    [self removeSubscribeObserver];

}

- (void)unsubscribeRaw {
    self.subscribeRawDataCallbackID = nil;
}

- (void)subscribeRaw: (NSString *)callbackId {
    self.subscribeRawDataCallbackID = callbackId;
}



- (bool)open {

    self.session = [[EASession alloc] initWithAccessory:self.accessory
                                            forProtocol:self.protocolString];
    if (self.session) {
        [[self.session inputStream] setDelegate:self];
        [[self.session inputStream] scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                          forMode:NSDefaultRunLoopMode];
        [[self.session inputStream] open];

        [[self.session outputStream] setDelegate:self];
        [[self.session outputStream] scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                           forMode:NSDefaultRunLoopMode];
        [[self.session outputStream] open];

        return true;

    } else {

        return false;

    }

}

- (void)close {

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

    // Remove read and write buffers
    self.readBuffer = nil;
    self.writeBuffer = nil;

}

- (bool)isOpen {

    if (self.session == nil) {
        return false;
    } else {
        return true;
    }

}

- (void)appendToWriteBuffer: (NSData *)data {

    if (self.writeBuffer == nil) {
        self.writeBuffer = [[NSMutableData alloc] init];
    }

    [self.writeBuffer appendData:data];

}


-(bool)writeData {


    while (([[self.session outputStream] hasSpaceAvailable]) && ([self.writeBuffer length] > 0))
    {
        // Write the bytes to the outputStream
        NSInteger bytesWritten = [[self.session outputStream] write:[self.writeBuffer bytes] maxLength:[self.writeBuffer length]];

        // If no bytes get written return false
        if (bytesWritten == -1) {
            return false;
        } else if (bytesWritten > 0) {
            [self.writeBuffer replaceBytesInRange:NSMakeRange(0, bytesWritten) withBytes:NULL length:0];
        }
    }

    return true;

}

- (NSData *)readBytesFromBuffer:(NSUInteger)bytesToRead {
    NSData *data = nil;
    if ([self.readBuffer length] >= bytesToRead) {
        NSRange range = NSMakeRange(0, bytesToRead);
        data = [self.readBuffer subdataWithRange:range];
        [self.readBuffer replaceBytesInRange:range withBytes:NULL length:0];
    }
    return data;
}

- (NSMutableString *)read {

    NSUInteger bytesAvailable = 0;
    NSMutableString *dataOutput = [[NSMutableString alloc] init];

    while ((bytesAvailable = [self.readBuffer length]) > 0) {
        NSData *data = [self readBytesFromBuffer:bytesAvailable];
        if (data) {

            NSString* dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (dataString != nil) {
                [dataOutput appendString:dataString];
            }

        }
    }

    return dataOutput;
}

- (NSString*)readUntilDelimiter:(NSString*)delimiter {

    NSString *dataString = [[NSString alloc] initWithData:self.readBuffer encoding:NSUTF8StringEncoding];
    NSRange range = [dataString rangeOfString:delimiter];
    NSString *message = @"";

    if (range.location != NSNotFound) {

        long end = range.location + range.length;
        message = [dataString substringToIndex:end];

        NSRange truncate = NSMakeRange(0, end);
        [self.readBuffer replaceBytesInRange:truncate withBytes:NULL length:0];

    }

    return message;
}

- (void)readStreamData {

    NSMutableData *rawDataRead = nil;
    if (self.subscribeRawDataCallbackID != nil) {
        rawDataRead = [[NSMutableData alloc] init];
    }

    uint8_t buf[self.inputBufferSize];
    while ([[self.session inputStream] hasBytesAvailable])
    {
        NSInteger bytesRead = [[self.session inputStream] read:buf maxLength:self.inputBufferSize];
        if (self.readBuffer == nil) {
            self.readBuffer = [[NSMutableData alloc] init];
        }
        [self.readBuffer appendBytes:(void *)buf length:bytesRead];


        if (self.subscribeRawDataCallbackID != nil) {
            [rawDataRead appendBytes:(void *)buf length:bytesRead];
        }

    }

    // If someone is listening for raw data send that back.
    if (self.subscribeRawDataCallbackID != nil && rawDataRead != nil) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArrayBuffer:rawDataRead];
        [pluginResult setKeepCallbackAsBool:true];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.subscribeRawDataCallbackID];
    }

    // When data is read in from the session send to the received notification.
    [[NSNotificationCenter defaultCenter] postNotificationName:self.protocolString object:self userInfo:nil];

}

- (void)clear {

    if (self.session != nil) {
        uint8_t buf[self.inputBufferSize];

        // Clear everything out of the input stream
        while ([[self.session inputStream] hasBytesAvailable]) {
            [[self.session inputStream] read:buf maxLength:self.inputBufferSize];
        }
    }

    self.readBuffer = nil;

}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
    switch(eventCode) {
        case NSStreamEventErrorOccurred:
        case NSStreamEventEndEncountered: {
            [stream close];
            [stream removeFromRunLoop:[NSRunLoop currentRunLoop]
                              forMode:NSDefaultRunLoopMode];
            stream = nil;
            self.session = nil;
            break;
        }
        case NSStreamEventHasBytesAvailable: {
            [self readStreamData];
            break;
        }

        case NSStreamEventHasSpaceAvailable: {
            [self writeData];
            break;
        }
        case NSStreamEventNone:
        case NSStreamEventOpenCompleted: {
            break;
        }
    }
}

@end
