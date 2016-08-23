#import <ExternalAccessory/ExternalAccessory.h>
#import <Cordova/CDVPlugin.h>

@interface CommunicationSession : NSObject <EAAccessoryDelegate, NSStreamDelegate>

/*!
 @brief Initialise the communication session
 */
- (id)init:(EAAccessory *)accessory :(NSString *)protocolString :(id <CDVCommandDelegate>)commandDelegate;

/*!
 @brief Opens the communication session
 */
- (bool)open;

/*!
 @brief Closes the communication session
 */
- (void)close;

/*!
 @brief Determines whether or not the communication session is open
 */
- (bool)isOpen;

/*!
 @brief Writes data from the write buffer to the output stream.
 */
- (bool)writeData;

/*!
 @brief Reads data from the stream and populates the read buffer
 */
- (void)readStreamData;

/*!
 @brief Append data to the write buffer
 */
- (void)appendToWriteBuffer: (NSData *)data;

/*!
 @brief Read everything out of the read buffer
 */
- (NSMutableString *)read;

/*!
 @brief Read a particular number of bytes from the read buffer
 */
- (NSData *)readBytesFromBuffer:(NSUInteger)bytesToRead;

/*!
 @brief Read from the input stream until a delimiter is hit
 */
- (NSString*)readUntilDelimiter:(NSString*)delimiter;

/*!
 @brief Clear the input stream and read buffer
 */
- (void)clear;

/*!
 @brief Add a subscribe callback ID and notification observer
 */
- (void)addSubscribeCallbackAndObserver: (NSString *)subscribeCallbackId;

/*!
 @brief Remove the subscription observer notification
 */
- (void)removeSubscribeObserver;

/*!
 @brief Unsubscribe from the sendDataToSubscriber callback function.
 */
- (void)unsubscribe;

/*!
 @brief Unsubscribe from the raw data callback function.
 */
- (void)unsubscribeRaw;

/*!
 @brief Subscribe to the raw data feed.
 */
- (void)subscribeRaw: (NSString *)callbackId;

@property (nonatomic, strong) EASession *session;
@property (nonatomic, strong) EAAccessory *accessory;
@property (nonatomic, weak) id <CDVCommandDelegate> commandDelegate;
@property (nonatomic, strong) NSString *protocolString;
@property (nonatomic, strong) NSMutableData *readBuffer;
@property (nonatomic, strong) NSMutableData *writeBuffer;
@property (nonatomic) uint8_t inputBufferSize;
@property (nonatomic, strong) NSString *subscribeCallbackId;
@property (nonatomic, strong) NSString *readDelimiter;
@property (nonatomic, strong) NSString *subscribeRawDataCallbackID;


@end
