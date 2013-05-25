
/*
 
 Copyright (c) 2012 RedBearLab
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
*/

#import "BLE.h"
#import "BLEDefines.h"

@implementation BLE

@synthesize delegate;
@synthesize CM;
@synthesize peripherals;
@synthesize activePeripheral;

static UInt16 libver = 0;
static unsigned char vendor_name[20] = {0};
static bool isConnected = false;
static int rssi = 0;

-(void) enableWrite
{
    CBUUID *uuid_service = [CBUUID UUIDWithString:@BLE_DEVICE_SERVICE_UUID];
    CBUUID *uuid_char = [CBUUID UUIDWithString:@BLE_DEVICE_RESET_RX_UUID];
    unsigned char bytes[] = {0x01};
    NSData *d = [[NSData alloc] initWithBytes:bytes length:1];
    [self writeValue:uuid_service characteristicUUID:uuid_char p:activePeripheral data:d];
}

-(void) readLibVerFromPeripheral
{
    CBUUID *uuid_service = [CBUUID UUIDWithString:@BLE_DEVICE_SERVICE_UUID];
    CBUUID *uuid_char = [CBUUID UUIDWithString:@BLE_DEVICE_LIB_VERSION_UUID];
    
    [self readValue:uuid_service characteristicUUID:uuid_char p:activePeripheral];
}

-(void) readVendorNameFromPeripheral
{
    CBUUID *uuid_service = [CBUUID UUIDWithString:@BLE_DEVICE_SERVICE_UUID];
    CBUUID *uuid_char = [CBUUID UUIDWithString:@BLE_DEVICE_VENDOR_NAME_UUID];
    
    [self readValue:uuid_service characteristicUUID:uuid_char p:activePeripheral];
}

-(BOOL) isConnected
{
    return isConnected;
}

-(void) read
{
    CBUUID *uuid_service = [CBUUID UUIDWithString:@BLE_DEVICE_SERVICE_UUID];
    CBUUID *uuid_char = [CBUUID UUIDWithString:@BLE_DEVICE_RX_UUID];
    
    [self readValue:uuid_service characteristicUUID:uuid_char p:activePeripheral];
}

-(void) write:(NSData *)d
{
    CBUUID *uuid_service = [CBUUID UUIDWithString:@BLE_DEVICE_SERVICE_UUID];
    CBUUID *uuid_char = [CBUUID UUIDWithString:@BLE_DEVICE_TX_UUID];
    
    [self writeValue:uuid_service characteristicUUID:uuid_char p:activePeripheral data:d];
}

-(void) enableReadNotification:(CBPeripheral *)p
{
    CBUUID *uuid_service = [CBUUID UUIDWithString:@BLE_DEVICE_SERVICE_UUID];
    CBUUID *uuid_char = [CBUUID UUIDWithString:@BLE_DEVICE_RX_UUID];
    
    [self notification:uuid_service characteristicUUID:uuid_char p:p on:YES];
}

-(void) notification:(CBUUID *)serviceUUID characteristicUUID:(CBUUID *)characteristicUUID p:(CBPeripheral *)p on:(BOOL)on
{
    CBService *service = [self findServiceFromUUID:serviceUUID p:p];
    
    if (!service)
    {
        printf("Could not find service with UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:serviceUUID],[self UUIDToString:p.UUID]);
        return;
    }
    
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:characteristicUUID service:service];
    
    if (!characteristic)
    {
        printf("Could not find characteristic with UUID %s on service with UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:characteristicUUID],[self CBUUIDToString:serviceUUID],[self UUIDToString:p.UUID]);
        return;
    }
    
    [p setNotifyValue:on forCharacteristic:characteristic];
}

-(int) readRSSI
{
    return rssi;
}

-(UInt16) readLibVer
{
    return libver;
}

-(UInt16) readFrameworkVersion
{
    return BLE_FRAMEWORK_VERSION;
}

-(NSString *) readVendorName
{
    return [NSString stringWithFormat:@"%s", vendor_name];
}

-(void) readValue: (CBUUID *)serviceUUID characteristicUUID:(CBUUID *)characteristicUUID p:(CBPeripheral *)p
{
    CBService *service = [self findServiceFromUUID:serviceUUID p:p];
    
    if (!service)
    {
        printf("Could not find service with UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:serviceUUID],[self UUIDToString:p.UUID]);
        return;
    }
    
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:characteristicUUID service:service];
    
    if (!characteristic)
    {
        printf("Could not find characteristic with UUID %s on service with UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:characteristicUUID],[self CBUUIDToString:serviceUUID],[self UUIDToString:p.UUID]);
        return;
    }
    
    [p readValueForCharacteristic:characteristic];
}

-(void) writeValue:(CBUUID *)serviceUUID characteristicUUID:(CBUUID *)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data
{
    CBService *service = [self findServiceFromUUID:serviceUUID p:p];
    
    if (!service)
    {
        printf("Could not find service with UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:serviceUUID],[self UUIDToString:p.UUID]);
        return;
    }
    
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:characteristicUUID service:service];
    
    if (!characteristic)
    {
        printf("Could not find characteristic with UUID %s on service with UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:characteristicUUID],[self CBUUIDToString:serviceUUID],[self UUIDToString:p.UUID]);
        return;
    }
    
    [p writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
}

-(UInt16) swap:(UInt16)s
{
    UInt16 temp = s << 8;
    temp |= (s >> 8);
    return temp;
}

- (int) controlSetup: (int) s
{
    self.CM = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    return 0;
}

- (int) findBLEPeripherals:(int) timeout
{
    if (self.CM.state != CBCentralManagerStatePoweredOn) {
        printf("CoreBluetooth not correctly initialized !\r\n");
        printf("State = %d (%s)\r\n", self.CM.state,[self centralManagerStateToString:self.CM.state]);
        return -1;
    }
    
    [NSTimer scheduledTimerWithTimeInterval:(float)timeout target:self selector:@selector(scanTimer:) userInfo:nil repeats:NO];
    
#if TARGET_OS_IPHONE
    [self.CM scanForPeripheralsWithServices:[NSArray arrayWithObject:[CBUUID UUIDWithString:@BLE_DEVICE_SERVICE_UUID]] options:nil];
#else
    [self.CM scanForPeripheralsWithServices:nil options:nil]; // Start scanning
#endif
    
    NSLog(@"scanForPeripheralsWithServices");
    
    return 0; // Started scanning OK !
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
{
    done = false;

    [[self delegate] bleDidDisconnect];
    
    isConnected = false;
}

- (void) connectPeripheral:(CBPeripheral *)peripheral {
    printf("Connecting to peripheral with UUID : %s\r\n",[self UUIDToString:peripheral.UUID]);
    self.activePeripheral = peripheral;
    self.activePeripheral.delegate = self;
    [self.CM connectPeripheral:self.activePeripheral options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
}

- (const char *) centralManagerStateToString: (int)state
{
    switch(state)
    {
        case CBCentralManagerStateUnknown:
            return "State unknown (CBCentralManagerStateUnknown)";
        case CBCentralManagerStateResetting:
            return "State resetting (CBCentralManagerStateUnknown)";
        case CBCentralManagerStateUnsupported:
            return "State BLE unsupported (CBCentralManagerStateResetting)";
        case CBCentralManagerStateUnauthorized:
            return "State unauthorized (CBCentralManagerStateUnauthorized)";
        case CBCentralManagerStatePoweredOff:
            return "State BLE powered off (CBCentralManagerStatePoweredOff)";
        case CBCentralManagerStatePoweredOn:
            return "State powered up and ready (CBCentralManagerStatePoweredOn)";
        default:
            return "State unknown";
    }
    
    return "Unknown state";
}

- (void) scanTimer:(NSTimer *)timer
{
    [self.CM stopScan];
    printf("Stopped Scanning\r\n");
    printf("Known peripherals : %d\r\n",[self.peripherals count]);
    [self printKnownPeripherals];
}

- (void) printKnownPeripherals
{
    int i;
    
    printf("List of currently known peripherals : \r\n");
    
    for (i = 0; i < self.peripherals.count; i++)
    {
        CBPeripheral *p = [self.peripherals objectAtIndex:i];
        
        if (p.UUID != NULL)
        {
            CFStringRef s = CFUUIDCreateString(NULL, p.UUID);
            printf("%d  |  %s\r\n",i,CFStringGetCStringPtr(s, 0));
        }
        else
            printf("%d  |  NULL\r\n",i);
        
        [self printPeripheralInfo:p];
    }
}

- (void) printPeripheralInfo:(CBPeripheral*)peripheral
{
    printf("------------------------------------\n");
    printf("Peripheral Info :\n");
    
    if (peripheral.UUID != NULL)
    {
        CFStringRef s = CFUUIDCreateString(NULL, peripheral.UUID);
        printf("UUID : %s\n",CFStringGetCStringPtr(s, 0));
    }
    else
        printf("UUID : NULL\n");
    
    printf("Name : %s\n",[peripheral.name cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
    printf("-------------------------------------\n");
}

- (int) UUIDSAreEqual:(CFUUIDRef)u1 u2:(CFUUIDRef)u2
{
    CFUUIDBytes b1 = CFUUIDGetUUIDBytes(u1);
    CFUUIDBytes b2 = CFUUIDGetUUIDBytes(u2);
    
    if (memcmp(&b1, &b2, 16) == 0) {
        return 1;
    }
    else
        return 0;
}

-(void) getAllServicesFromPeripheral:(CBPeripheral *)p
{
    [p discoverServices:nil]; // Discover all services without filter
}

-(void) getAllCharacteristicsFromPeripheral:(CBPeripheral *)p
{
    for (int i=0; i < p.services.count; i++)
    {
        CBService *s = [p.services objectAtIndex:i];
        //        printf("Fetching characteristics for service with UUID : %s\r\n",[self CBUUIDToString:s.UUID]);
        [p discoverCharacteristics:nil forService:s];
    }
}

-(const char *) CBUUIDToString:(CBUUID *) UUID
{
    return [[UUID.data description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy];
}

-(const char *) UUIDToString:(CFUUIDRef)UUID
{
    if (!UUID)
        return "NULL";
    
    CFStringRef s = CFUUIDCreateString(NULL, UUID);
    
    return CFStringGetCStringPtr(s, 0);
}

-(int) compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2
{
    char b1[16];
    char b2[16];
    [UUID1.data getBytes:b1];
    [UUID2.data getBytes:b2];
    if (memcmp(b1, b2, UUID1.data.length) == 0)return 1;
    else return 0;
}

-(int) compareCBUUIDToInt:(CBUUID *)UUID1 UUID2:(UInt16)UUID2
{
    char b1[16];
    
    [UUID1.data getBytes:b1];
    UInt16 b2 = [self swap:UUID2];
    
    if (memcmp(b1, (char *)&b2, 2) == 0)
        return 1;
    else
        return 0;
}

-(UInt16) CBUUIDToInt:(CBUUID *) UUID
{
    char b1[16];
    [UUID.data getBytes:b1];
    return ((b1[0] << 8) | b1[1]);
}

-(CBUUID *) IntToCBUUID:(UInt16)UUID
{
    char t[16];
    t[0] = ((UUID >> 8) & 0xff); t[1] = (UUID & 0xff);
    NSData *data = [[NSData alloc] initWithBytes:t length:16];
    return [CBUUID UUIDWithData:data];
}

-(CBService *) findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p
{
    for(int i = 0; i < p.services.count; i++)
    {
        CBService *s = [p.services objectAtIndex:i];
        if ([self compareCBUUID:s.UUID UUID2:UUID]) return s;
    }
    
    return nil; //Service not found on this peripheral
}

-(CBCharacteristic *) findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service
{
    for(int i=0; i < service.characteristics.count; i++)
    {
        CBCharacteristic *c = [service.characteristics objectAtIndex:i];
        if ([self compareCBUUID:c.UUID UUID2:UUID]) return c;
    }
    
    return nil; //Characteristic not found on this service
}

#if TARGET_OS_IPHONE
    //-- no need for iOS
#else
- (BOOL) isLECapableHardware
{
    NSString * state = nil;
    
    switch ([CM state])
    {
        case CBCentralManagerStateUnsupported:
            state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;
        case CBCentralManagerStateUnauthorized:
            state = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBCentralManagerStatePoweredOff:
            state = @"Bluetooth is currently powered off.";
            break;
        case CBCentralManagerStatePoweredOn:
            return TRUE;
        case CBCentralManagerStateUnknown:
        default:
            return FALSE;
            
    }
    
    NSLog(@"Central manager state: %@", state);
        
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:state];
    [alert addButtonWithTitle:@"OK"];
    [alert setIcon:[[NSImage alloc] initWithContentsOfFile:@"AppIcon"]];
    [alert beginSheetModalForWindow:nil modalDelegate:self didEndSelector:nil contextInfo:nil];
    return FALSE;
}
#endif

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
#if TARGET_OS_IPHONE
    printf("Status of CoreBluetooth central manager changed %d (%s)\r\n",central.state,[self centralManagerStateToString:central.state]);
#else
    [self isLECapableHardware];
#endif
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (!self.peripherals)
        self.peripherals = [[NSMutableArray alloc] initWithObjects:peripheral,nil];
    else
    {
        for(int i = 0; i < self.peripherals.count; i++)
        {
            CBPeripheral *p = [self.peripherals objectAtIndex:i];
            
            if ((p.UUID == NULL) || (peripheral.UUID == NULL))
                continue;
            
            if ([self UUIDSAreEqual:p.UUID u2:peripheral.UUID])
            {
                [self.peripherals replaceObjectAtIndex:i withObject:peripheral];
                printf("Duplicate UUID found updating ...\n");
                return;
            }
        }
        
        [self.peripherals addObject:peripheral];
        
        printf("New UUID, adding\r\n");
    }
    
    printf("didDiscoverPeripheral\r\n");
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    if (peripheral.UUID != NULL)
        printf("Connected to %s successful\n",[self UUIDToString:peripheral.UUID]);
    else
        printf("Connected to NULL successful\n");    
    self.activePeripheral = peripheral;
    [self.activePeripheral discoverServices:nil];
    [self getAllServicesFromPeripheral:peripheral];
}

static bool done = false;

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (!error)
    {
        //        printf("Characteristics of service with UUID : %s found\n",[self CBUUIDToString:service.UUID]);
        
        for (int i=0; i < service.characteristics.count; i++)
        {
            //            CBCharacteristic *c = [service.characteristics objectAtIndex:i];
            //            printf("Found characteristic %s\n",[ self CBUUIDToString:c.UUID]);
            CBService *s = [peripheral.services objectAtIndex:(peripheral.services.count - 1)];
            
            if ([service.UUID isEqual:s.UUID])
            {
                if (!done)
                {
                    [self enableReadNotification:activePeripheral];
                    [self readLibVerFromPeripheral];
                    [self readVendorNameFromPeripheral];
                    
                    [[self delegate] bleDidConnect];
                    
                    isConnected = true;
                    [activePeripheral readRSSI];

                    done = true;
                }
                
                break;
            }
        }
    }
    else
    {
        printf("Characteristic discorvery unsuccessful!\r\n");
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (!error)
    {
        //        printf("Services of peripheral with UUID : %s found\n",[self UUIDToString:peripheral.UUID]);
        [self getAllCharacteristicsFromPeripheral:peripheral];
    }
    else
    {
        printf("Service discovery was unsuccessful!\n");
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (!error)
    {
        //        printf("Updated notification state for characteristic with UUID %s on service with  UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:characteristic.UUID],[self CBUUIDToString:characteristic.service.UUID],[self UUIDToString:peripheral.UUID]);
    }
    else
    {
        printf("Error in setting notification state for characteristic with UUID %s on service with  UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:characteristic.UUID],[self CBUUIDToString:characteristic.service.UUID],[self UUIDToString:peripheral.UUID]);
        printf("Error code was %s\r\n",[[error description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    unsigned char data[BLE_DEVICE_RX_READ_LEN];
    
    static unsigned char buf[512];
    static int len = 0;
    int data_len;
    
    if (!error)
    {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@BLE_DEVICE_RX_UUID]])
        {
            data_len = characteristic.value.length;
            [characteristic.value getBytes:data length:data_len];
            
            if (data_len == 20)
            {
                memcpy(&buf[len], data, 20);
                len += data_len;
                
                if (len >= 64)
                {
                    [[self delegate] bleDidReceiveData:buf length:len];
                    len = 0;
                }
            }
            else if (data_len < 20)
            {
                memcpy(&buf[len], data, data_len);
                len += data_len;
                
                [[self delegate] bleDidReceiveData:buf length:len];
                len = 0;
            }
            
            [self enableWrite];
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@BLE_DEVICE_VENDOR_NAME_UUID]])
        {
            data_len = characteristic.value.length;
            [characteristic.value getBytes:vendor_name length:data_len];
//            NSLog(@"Vendor: %s", vendor_name);
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@BLE_DEVICE_LIB_VERSION_UUID]])
        {
            [characteristic.value getBytes:&libver length:2];
//            NSLog(@"Lib. ver.: %X", libver);
        }
    }
    else
    {
        printf("updateValueForCharacteristic failed!");
    }
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
    if (!isConnected)
        return;
    
    if (rssi != peripheral.RSSI.intValue)
    {
        rssi = peripheral.RSSI.intValue;
        [[self delegate] bleDidUpdateRSSI:activePeripheral.RSSI];
    }
    [activePeripheral readRSSI];
}

@end
