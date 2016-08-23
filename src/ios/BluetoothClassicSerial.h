#import <UIKit/UIKit.h>
#import <ExternalAccessory/ExternalAccessory.h>
#import <Cordova/CDVPlugin.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "CommunicationSession.h"

@interface BluetoothClassicSerial : CDVPlugin <EAAccessoryDelegate, NSStreamDelegate, CBCentralManagerDelegate>

/*!
 @brief Used as a "constructor" to initialise the Cordova IOS Plugin
 */
- (void)pluginInitialize;

/*!
 @brief List all currently connected devices
 @discussion Will return a list - either empty or populated with all currently connected devices to the successCallback.

 JavaScript API:
 @code
 bluetoothClassicSerial.list(successCallback);
 @endcode
 */
- (void)list:(CDVInvokedUrlCommand *)command;

/*!
 @brief Connect to the device by opening a communication session
 @discussion This methods opens a communication session with the device enabling reading and writing to and from the device.

 The JavaScript API accepts a unique connectionID which can be used to select a particular device that adheres to the provided communication protocols. The communication protocols should be specified as an array in the second parameter.

 JavaScript API:
 @code
 bluetoothClassicSerial.connect(connectionID, [protocolStrings], successCallback, failCallback);
 @endcode
 */
- (void)connect:(CDVInvokedUrlCommand *)command;

/*!
 @brief Disconnect the communication session with the device
 @discussion It is not possible to completely disconnect from a device using the External Accessory Framework. Instead disconnection in this context means disconnecting from the communication session with the device so no data can be sent or received

 JavaScript API:
 @code
 bluetoothClassicSerial.disconnect(successCallback, failCallback);
 @endcode
 */
- (void)disconnect:(CDVInvokedUrlCommand *)command;


/*!
 @brief Discover any unpaired devices and allow the user to choose one to connect to.
 @discussion This method on IOS when triggered will open a native device selector allowing the user to select an external accessory to connect to. The accessory must adhere to one of the apps supported communication protocols defined in the application plist file.

 If the user cancels the device selector or selection of the device fails for any reason the application will call the failCallback.

 If the user selects a device that is still connected then the successCallback will be fired and the currently active accessory for the current application instance will be returned. It should be noted that on IOS via the device selector - user selection of a currently connected device is considered an error. Unfortunately Apple, in their wisdom, decided because of this that they wouldn't provide any information about the accessory that the user attempted to reconnect to. Because of this if the user does select an already connected device, the successCallback will be called and will contain either the currently connected app for the app instance, or a list of all connected items if no currently connected app exists.

 If the user selects a device that has not been connected and the user has defined a setDeviceDiscoveredListener then upon successful connection the device discovered listener will be fired and the accessory details will be returned via that method.

 JavaScript API:
 @code
 bluetoothClassicSerial.discoverUnpaired(successCallback, failCallback);
 @endcode


 */
- (void)discoverUnpaired:(CDVInvokedUrlCommand *)command;

/*!
 @brief Check to see if Bluetooth is enabled on the target device.
 @discussion If bluetooth is enabled the success callback is fired. If it's not then failCallback is fired.

 JavaScript API:
 @code
 bluetoothClassicSerial.isEnabled(successCallback, failCallback);
 @endcode

 */
- (void)isEnabled:(CDVInvokedUrlCommand *)command;

/*!
 @brief Check to see if the accessory is connected.
 @discussion Connected in this context means that the accessory is paired and connected to the App, and that the communication session is open with the device.

 JavaScript API:
 @code
 bluetoothClassicSerial.isConnected(successCallback, failCallback);
 @endcode

 */
- (void)isConnected:(CDVInvokedUrlCommand*)command;

/*!
 @brief Write data to the device for a particular protocol

 JavaScript API:
 @code
 bluetoothClassicSerial.write(data, protocolString, successCallback, failCallback);
 @endcode
 */
- (void)write:(CDVInvokedUrlCommand *)command;

/*!
 @brief Read all data in the input stream for a particular protocol
 @discussion If the communication session is not open the failCallback will be called

 @code
 bluetoothClassicSerial.read(protocolString, successCallback, failCallback);
 @endcode
 */
- (void)read:(CDVInvokedUrlCommand *)command;

/*!
 @brief Read data in the input stream of the particular protocol until the specified delimiter occurs
 @discussion This method is passed a delimiter via the JavaScript API. If no delimiter is specified then the failCallback will fire. Or if the communication session is not open the failCallback will be called.

 @code
 bluetoothClassicSerial.readUntil(delimiter, protocolString, successCallback, failCallback);
 @encode
 */
- (void)readUntil:(CDVInvokedUrlCommand*)command;

/*!
 @brief Subscribe to be notified when data is received from the device for a particular protocol via the sendDataToSubscriber callback.
 @discussion It takes a delimiter as the first argument which specifies at what point the callback should be triggered to return data.

 JavaScript API:
 @code
 bluetoothClassicSerial.subscribe(delimiter, protocolString, successCallback, failCallback);
 @endcode
 */
- (void)subscribe:(CDVInvokedUrlCommand *)command;

/*!
 @brief Subscribe to be notified when raw data is received from the device.

 JavaScript API:
 @code
 bluetoothClassicSerial.subscribeRawData(successCallback, failCallback);
 @encode
 */
- (void)subscribeRaw:(CDVInvokedUrlCommand *)command;

/*!
 @brief Unsubscribe from notifications that raw data has been received from the device.

 JavaScript API:
 @code
 bluetoothClassicSerial.unsubscribeRawData(successCallback, failCallback);
 @encode
 */
- (void)unsubscribeRaw:(CDVInvokedUrlCommand *)command;

/*!
 @brief Unsubscribe from the sendDataToSubscriber callback function.

 JavaScript API:
 @code
 bluetoothClassicSerial.unsubscribe(protocolString, successCallback);
 @endcode
 */
- (void)unsubscribe:(CDVInvokedUrlCommand *)command;

/*!
 @brief Set a callback that gets fired whenever a device is discovered for connection.
 @discussion Once set this notification callback will be fired under the following conditions:

 1. There is currently no other accessory connected in the plugin instance.

 2. The External Accessory Framework detects that a device has connected to the application. This happens if a previously unconnected device is selected via the device picker or a previously paired device connects automatically while the app is running.

 JavaScript API:
 @code
 bluetoothClassicSerial.setDeviceDiscoveredListener(notifyCallback);
 @endcode
 */
- (void)setDeviceDiscoveredListener:(CDVInvokedUrlCommand *)command;

/*!
 @brief Clear the device discovered listener

 Javascript API:
 @code
 bluetoothClassicSerial.clearDeviceDiscoveredListener();
 @endcode
 */
- (void)clearDeviceDiscoveredListener:(CDVInvokedUrlCommand *)command;

/*!
 @brief Clear the input stream read buffer

 Javascript API:
 @code
 bluetoothClassicSerial.clear(successCallback);
 @endcode
 */
- (void)clear:(CDVInvokedUrlCommand *)command;


/*!
 @brief Close the communication sessions with the connected device.
 */
- (void)closeCommunicationSessions;

/*!
 @brief Open a communication session for an accessory with a given connectionID and a given protocolString
 @discussion If the connectionID is passed in as 0 then the method will attempt to open a session with the first connected device that matches the provided communication protocol.
 @return NSMutableDictionary - True for session open. False for not
 */
- (NSMutableDictionary*)openSessionForConnectionIdAndProtocolStrings:(NSUInteger)connectionId :(NSArray *)protocolStrings;

/*!
 @brief Get all the details for a given accessory
 @return Dictionary of accessory details
 */
- (NSMutableDictionary*)accessoryDetails:(EAAccessory *)accessory;

/*!
 @brief Checks the core bluetooth manager to see if Bluetooth is active and enabled.
 @discussion If bluetooth is active and enabled the bluetoothEnabled property is set to true.
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central;

/*!
 @brief An external accessory framework notification
 @discussion This will trigger whenever a device connects via the External Accessory Framework
 */
- (void)accessoryConnected:(NSNotification *)notification;

/*!
 @brief To fire the device discovered listener if one has been set by the user via setDeviceDiscoveredListener
 */
-(void)fireDeviceDiscoveredListener:(EAAccessory *)accessory;

/*!
 @brief An External Accessory Framework notification that fires whenever a connected accessory disconnects from the device.
 @discussion When this triggers any open communication session with a device is closed.
 */
- (void)accessoryDisconnected:(NSNotification *)notification;

/*!
 @brief Determines whether all not all communication sessions are open on the device.
 */
- (bool)isAllCommunicationSessionsOpen;

/*!
 @brief Get the active communication session for a particular protocol string.
 */
- (CommunicationSession*)getCommunicationSessionForProtocolString: (NSString *)protocolString;


@property (nonatomic, strong) EAAccessory *accessory;
@property (nonatomic, strong) NSString *deviceDiscoveredCallbackID;
@property (nonatomic, strong) NSString *sessionDataReadCallbackID;
@property CBCentralManager* bluetoothManager;
@property (nonatomic) bool bluetoothEnabled;
@property (nonatomic, strong) NSMutableArray *connectionError;
@property (nonatomic, strong) NSMutableDictionary *connectionErrorDetails;
@property (nonatomic, strong) NSString *SessionDataReceivedNotification;
@property (nonatomic, strong) NSMutableArray *communicationSessions;
@property (nonatomic, strong) NSMutableArray *subscribeCallbackIds;
@property (nonatomic, strong) NSMutableArray *subscribeRawCallbackIds;





@end