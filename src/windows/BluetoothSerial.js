var app = WinJS.Application;
var bluetooth = Windows.Devices.Bluetooth;
var deviceInfo = Windows.Devices.Enumeration.DeviceInformation;
var rfcomm = Windows.Devices.Bluetooth.Rfcomm;
var sockets = Windows.Networking.Sockets;
var streams = Windows.Storage.Streams;

var socket;
var writer;
var reader;
var bufferBytes, buffer;
var delimiter;
var subscribeCallback, subscribeRawCallback;


var readUntil = function(chars) {
	var index = buffer.indexOf(chars);
	var data = "";
	
	if (index > -1) {
		data = buffer.substring(0, index + chars.length);
		buffer = buffer.replace(data, "");
	}
	
	return data;
}

/*
 * http://stackoverflow.com/questions/17191945/conversion-between-utf-8-arraybuffer-and-string
 * Niccolò Campolungo's answer
*/
var uintToString = function(uintArray) {
	var encodedString = String.fromCharCode.apply(null, uintArray);
	var decodedString = decodeURIComponent(escape(encodedString));
	return decodedString;
}

module.exports = {
	sendDataToSubscriber: function() {
		var data = readUntil(delimiter);
		
		if (data && data.length > 0) {
			subscribeCallback(data);
			
			// in case there is more data to send
			module.exports.sendDataToSubscriber();
		}
	},
	
	receiveStringLoop:  function(reader) {
		// Read first byte (length of the subsequent message, 255 or less). 
		reader.loadAsync(1).done(function (size) {		
			if (size != 1) {
				bluetoothSerial.disconnect();
				console.log("The underlying socket was closed before we were able to read the whole data. Client disconnected.", "sample", "status");
				return;
			}

			// Read the message. 
			var messageLength = reader.readByte();			
			reader.loadAsync(messageLength).done(function(actualMessageLength) {
				if (messageLength != actualMessageLength)
				{
					console.log("The underlying socket was closed before we were able to read the whole data.", "sample", "status");
					return;
				}
				
				//var message = reader.readString(actualMessageLength);
				bufferBytes = new Uint8Array(actualMessageLength);
				reader.readBytes(bufferBytes);
				
				// unfortunately IE doesn't support TextDecoder, so we need another solution...
				buffer = uintToString(bufferBytes);
				
				if (subscribeRawCallback && typeof(subscribeRawCallback) !== "undefined") {
					subscribeRawCallback(bufferBytes);
				}
				
				if (subscribeCallback && typeof(subscribeCallback) !== "undefined") {
					module.exports.sendDataToSubscriber();
				}
				
				WinJS.Promise.timeout().done(function () { return module.exports.receiveStringLoop(reader); });
			}, function (error) {
				console.log("loadAsync -> Failed to read the message, with error: " + error, "sample", "error");
			});
		}, function (error) {
			console.log("Failed to read the message size, with error: " + error, "sample", "error");
		});
	},
	
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
				failure("No Bluetooth devices found.");
			}
		});
	},
	
	connect: function(success, failure, args) {
		var id = args[0];
		
		// Initialize the target Rfcomm service
		rfcomm.RfcommDeviceService.fromIdAsync(id).then(
			function (service) {
				if (service === null) {
					failure("Access to the device is denied because the application was not granted access.");	
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
							module.exports.receiveStringLoop(reader);
							
							success("Connected.");
						});
					}
					else {
						failure("Impossible to determine the HostName or the ServiceName.");
					}
				}
			}
		);
	},
	
	connectInsecure: function(success, failure, args) {
		failure("Not yet implemented...");
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
		
		success("Device disconnected.");		
	},
	
	isEnabled: function(success, failure, args) {
		deviceInfo.findAllAsync(
			Windows.Devices.Bluetooth.Rfcomm.RfcommDeviceService.getDeviceSelector(
				Windows.Devices.Bluetooth.Rfcomm.RfcommServiceId.serialPort			
			),
			null
		).then(function(devices) {
			if (devices.length > 0) {
				success(1);
			}
			else {
				success(0);
			}
		});
	},
	
	available: function(success, failure, args) {
		success(buffer.length);
	},
	
	read: function(success, failure, args) {
		var ret = buffer;
		buffer = "";
		success(ret);
	},
	
	readUntil: function(success, failure, args) {
		var delim = args[0];
		console.log(delim);
		success(readUntil(delim));
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
				console.log("Failed to send the message to the server, error: " + error);
			});
		} catch (error) {
			console.log("Sending message failed with error: " + error);
		}
	},
	
	subscribe: function(success, failure, args) {
		delimiter = args[0];
		subscribeCallback = args[1];
	},
	
	unsubscribe: function(success, failure, args) {
		delimiter = "";
		subscribeCallback = null;
		success("Unsubscribed.");
	},
	
	subscribeRaw: function(success, failure, args) {
		subscribeRawCallback = args[0];
	},
	
	unsubscribeRaw: function(success, failure, args) {
		subscribeRawCallback = null;
		success("Unsubscribed from raw data.");
	},
	
	clear: function(success, failure, args) {
		buffer = "";
		success("Buffer cleared");
	},
	
	readRSSI: function(success, failure, args) {
		failure("Not yet implemented...");
	},
	
	showBluetoothSettings: function(success, failure, args) {
		failure("Not yet implemented...");
	},
	
	setDeviceDiscoveredListener: function(success, failure, args) {
		failure("Not yet implemented...");
	},
	
	clearDeviceDiscovered: function(success, failure, args) {
		failure("Not yet implemented...");
	},
	
	setName: function(success, failure, args) {
		failure("Not yet implemented...");
	},
	
	setDiscoverable: function(success, failure, args) {
		failure("Not yet implemented...");
	}
}

require("cordova/exec/proxy").add("BluetoothSerial", module.exports);
