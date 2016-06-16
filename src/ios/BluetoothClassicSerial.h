#import <UIKit/UIKit.h>
#import <ExternalAccessory/ExternalAccessory.h>
#import <Cordova/CDVPlugin.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface BluetoothClassicSerial : CDVPlugin <EAAccessoryDelegate, NSStreamDelegate, CBCentralManagerDelegate>

// Initialisation method for the plugin
- (void)pluginInitialize;

// get the currently connected devices.
- (void)list:(CDVInvokedUrlCommand *)command;

// call to connect to a bluetooth device
- (void)connect:(CDVInvokedUrlCommand *)command;

// call to disconnect from the bluetooth device
- (void)disconnect:(CDVInvokedUrlCommand *)command;

// close a connected session
- (void)closeSession;

// Discover unpaired devices
- (void)discoverUnpaired:(CDVInvokedUrlCommand *)command;

// Determine whether or not bluetooth is enabled
- (void)isEnabled:(CDVInvokedUrlCommand *)command;

// Determine whether we have a connection or not
- (void)isConnected:(CDVInvokedUrlCommand*)command;

// Write to the device
- (void)write:(CDVInvokedUrlCommand *)command;

// Subscribe to the read data notifications
- (void)subscribe:(CDVInvokedUrlCommand *)command;

// Unsubscribe from the read data notifications
- (void)unsubscribe:(CDVInvokedUrlCommand *)command;

@property (nonatomic, strong) EASession *session;
@property (nonatomic, strong) EAAccessory *accessory;
@property (nonatomic, strong) NSMutableArray *accessoriesList;
@property (nonatomic, strong) NSString *deviceDiscoveredCallbackID;
@property (nonatomic, strong) NSMutableData *readData;
@property (nonatomic, strong) NSMutableData *writeData;
@property (nonatomic, strong) NSString *protocolString;
@property (nonatomic, strong) CDVInvokedUrlCommand *sessionCommand;
@property CBCentralManager* bluetoothManager;
@property (nonatomic) bool bluetoothEnabled;
@property (nonatomic) bool writeError;
@property (nonatomic) uint8_t inputBufferSize;
@property (nonatomic, strong) NSString *SessionDataReceivedNotification;

@end