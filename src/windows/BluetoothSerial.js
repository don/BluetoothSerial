var bluetooth = Windows.Devices.Bluetooth;
var gatt = Windows.Devices.Bluetooth.GenericAttributeProfile;
var deviceInfo = Windows.Devices.Enumeration.DeviceInformation;
var wsc = Windows.Security.Cryptography;

var initialized = false;
var cachedServices = [];


var app = WinJS.Application;
var rfcomm = Windows.Devices.Bluetooth.Rfcomm;
var sockets = Windows.Networking.Sockets;
var streams = Windows.Storage.Streams;
var service;
var socket;
var services;
var writer;
var reader;
var buffer;
var delimiter;
var subscribeCallback;



var receiveStringLoop = function(reader) {
	// Read first byte (length of the subsequent message, 255 or less). 
	reader.loadAsync(1).done(function (size) {		
		if (size != 1) {
			bluetoothSerial.disconnect();
			console.log("The underlying socket was closed before we were able to read the whole data. Client disconnected.", "sample", "status");
			return;
		}

		// Read the message. 
		var messageLength = reader.readByte();
		console.log("messageLength: " + messageLength);
		
		reader.loadAsync(messageLength).done(function(actualMessageLength) {
			if (messageLength != actualMessageLength)
			{
				// The underlying socket was closed before we were able to read the whole data. 
				console.log("The underlying socket was closed before we were able to read the whole data.", "sample", "status");
				return;
			}
			
			// ATTENTION: NEED TO IMPLEMENT readBytes...
			var message = reader.readString(actualMessageLength);
			console.log("Message readed: " + message + "\nLength: " + message.length);
			buffer = message;
			
			if (subscribeCallback && typeof(subscribeCallback) !== "undefined") {
				console.log("trying to execute the callback..."); //trying to load new data
				var tmp = readUntil(delimiter);
				console.log("Data to send to subscriber: " + tmp);

				subscribeCallback(tmp);
			}
			
			WinJS.Promise.timeout().done(function () { return receiveStringLoop(reader); });
		}, function (error) {
			console.log("loadAsync -> Failed to read the message, with error: " + error, "sample", "error");
		});
	}, function (error) {
		console.log("Failed to read the message size, with error: " + error, "sample", "error");
	});
}

var readUntil = function(chars) {
	var index = buffer.indexOf(chars);
	var data = "";
	
	if (index > -1) {
		data = buffer.substring(0, index + chars.length);
		buffer.replace(data, "");
	}
	
	return data;
}



module.exports = {
	
	list: function(success, failure, args) {
		deviceInfo.findAllAsync(
			Windows.Devices.Bluetooth.Rfcomm.RfcommDeviceService.getDeviceSelector(
				Windows.Devices.Bluetooth.Rfcomm.RfcommServiceId.serialPort			
			),
			null
		).then(function(devices) {
			if (devices.length > 0) {
				var results = [];
				
				for (var i = 0; i < devices.length; i++) {
					var devName = devices[i].name;
					var devAddress = devices[i].id;
					
					results.push({ name: devName, uuid: devAddress, address: devAddress });
				}
				success(results);
			}
			else {
				failure({error: "list", message: "No Bluetooth devices found." });
			}
		});
	},
	
	connect: function(success, failure, args) {
		var id = args[0];
		
		// Initialize the target Rfcomm service
		rfcomm.RfcommDeviceService.fromIdAsync(id).then(
			function (service) {
				if (service === null) {
					var msg = "connect\nservice is null";
					navigator.notification.alert(
						msg,  // message
						function () {
						},         // callback
						'Game Over',            // title
						'Done'                  // buttonName
					);
					failure({error: "connect", message: "Access to the device is denied because the application was not granted access.", ids: id });	
				}
				else {					
					socket = new sockets.StreamSocket();

					if (service.connectionHostName && service.connectionServiceName) {
						socket.connectAsync(
							service.connectionHostName,
							service.connectionServiceName
						).done(function () {
							writer = new streams.DataWriter(socket.outputStream);
							writer.byteOrder = streams.ByteOrder.littleEndian;
							writer.unicodeEncoding = streams.UnicodeEncoding.utf8;
							
							reader = new streams.DataReader(socket.inputStream);
							reader.unicodeEncoding = streams.UnicodeEncoding.Utf8;
							reader.byteOrder = streams.ByteOrder.littleEndian;
							
							buffer = [];
							
							receiveStringLoop(reader);
							
							success("Connected...");
						});
					}
					else {
						failure({error: "connect->service", message: "asd." });
					}
					
				}
				
			}
		);
	},
	
	connectInsecure: function(success, failure, args) {
		
	},
	
	disconnect: function(success, failure, args) {
		if (writer) {
			writer.detachStream();
			writer = null;
		}

		if (socket) {
			socket.close();
			socket = null;
		}
		
		success({message: "Device disconnected." });
	},
	
	isEnabled: function(success, failure, args) {
		
	},
	
	available: function(success, failure, args) {
		
	},
	
	read: function(success, failure, args) {

	},
	
	readUntil: function(success, failure, args) {
		
	},
	
	write: function(success, failure, args) {
		var data = args[0];
		var ui8Data = new Uint8Array(data);
		
		try {
			writer.writeByte(ui8Data.length);
			writer.writeBytes(ui8Data);
			
			// this is where the data is sent
			writer.storeAsync().done(function () {
				success("Data sent to the device correctly!");
			}, function (error) {
				console.log("Failed to send the message to the server, error: " + error, "sample", "error");
			});
		} catch (error) {
			WinJS.log && WinJS.log("Sending message failed with error: " + error);
		}
	},
	
	subscribe: function(success, failure, args) {
		delimiter = args[0];
		subscribeCallback = success;
	},
	
	unsubscribe: function(success, failure, args) {
		
	},
	
	subscribeRawData: function(success, failure, args) {
		
	},
	
	unsubscribeRawData: function(success, failure, args) {
		
	},
	
	clear: function(success, failure, args) {
		
	},
	
	readRSSI: function(success, failure, args) {
		
	},
	
	showBluetoothSettings: function(success, failure, args) {
		
	},
	
	setDeviceDiscoveredListener: function(success, failure, args) {
		
	},
	
	clearDeviceDiscovered: function(success, failure, args) {
		
	},
	
	setName: function(success, failure, args) {
		
	},
	
	setDiscoverable: function(success, failure, args) {
		
	}
}

require("cordova/exec/proxy").add("BluetoothSerial", module.exports);
