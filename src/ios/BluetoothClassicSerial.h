#import <UIKit/UIKit.h>
#import <ExternalAccessory/ExternalAccessory.h>
#import <Cordova/CDVPlugin.h>

@interface BluetoothClassicSerial : CDVPlugin <EAAccessoryDelegate, NSStreamDelegate>

// get the currently connected devices.
- (void)list:(CDVInvokedUrlCommand *)command;

// call to connect to a bluetooth device
- (void)connect:(CDVInvokedUrlCommand *)command;

// close a connected session
- (void)closeSession:(CDVInvokedUrlCommand *)command;

@property (nonatomic, strong) EASession *session;
@property (nonatomic, strong) EAAccessory *accessory;
@property (nonatomic, strong) NSMutableArray *accessoriesList;

@end