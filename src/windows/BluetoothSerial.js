var app = WinJS.Application;
var bluetooth = Windows.Devices.Bluetooth;
var deviceInfo = Windows.Devices.Enumeration.DeviceInformation;
var rfcomm = Windows.Devices.Bluetooth.Rfcomm;
var sockets = Windows.Networking.Sockets;
var streams = Windows.Storage.Streams;

var socket;
var writer;
var reader;
var delimiter;
var subscribeCallback, subscribeRawCallback, disconnectCallback;

var receivedBytes = [];

var bytesToString = function(bytes) {
	// based on http://ciaranj.blogspot.fr/2007/11/utf8-characters-encoding-in-javascript.html

	var result = "";
	var i, c, c1, c2, c3;
	i = c = c1 = c2 = c3 = 0;

	// Perform byte-order check.
	if( bytes.length >= 3 ) {
		if( (bytes[0] & 0xef) == 0xef && (bytes[1] & 0xbb) == 0xbb && (bytes[2] & 0xbf) == 0xbf ) {
			// stream has a BOM at the start, skip over
			i = 3;
		}
	}

	while ( i < bytes.length ) {
		c = bytes[i] & 0xff;

		if ( c < 128 ) {

			result += String.fromCharCode(c);
			i++;

		} else if ( (c > 191) && (c < 224) ) {

			if ( i + 1 >= bytes.length ) {
				//throw "Un-expected encoding error, UTF-8 stream truncated, or incorrect";
				// assume reading the next byte will fix this, ignore
				break;
			}
			c2 = bytes[i + 1] & 0xff;
			result += String.fromCharCode( ((c & 31) << 6) | (c2 & 63) );
			i += 2;

		} else {

			if ( i + 2 >= bytes.length  || i + 1 >= bytes.length ) {
				//throw "Un-expected encoding error, UTF-8 stream truncated, or incorrect";
				// assume reading the next bytes will fix this, ignore
				break;
			}
			c2 = bytes[i + 1] & 0xff;
			c3 = bytes[i + 2] & 0xff;
			result += String.fromCharCode( ((c & 15) << 12) | ((c2 & 63) << 6) | (c3 & 63) );
			i += 3;

		}
	}
	return result;
}

var stringToBytes = function(string) {
	// based on http://ciaranj.blogspot.fr/2007/11/utf8-characters-encoding-in-javascript.html

	var bytes = [];

	for (var n = 0; n < string.length; n++) {

		var c = string.charCodeAt(n);

		if (c < 128) {

			bytes[bytes.length]= c;

		} else if((c > 127) && (c < 2048)) {

			bytes[bytes.length] = (c >> 6) | 192;
			bytes[bytes.length] = (c & 63) | 128;

		} else {

			bytes[bytes.length] = (c >> 12) | 224;
			bytes[bytes.length] = ((c >> 6) & 63) | 128;
			bytes[bytes.length] = (c & 63) | 128;

		}

	}

	return bytes;
}

// read received data up until the chars that define the delimiter
var readUntil = function(chars) { 
	var dataAsString = bytesToString(receivedBytes);
	var index = dataAsString.indexOf(chars);
	var data = "";
	
	if (index > -1) {
		data = dataAsString.substring(0, index + chars.length);

		// truncate receivedBytes, removing data. data might contain unicode, so convert to bytes to get the length
		var removeBytes = stringToBytes(data);
		receivedBytes = receivedBytes.slice(removeBytes.length);
	}
	
	return data;
}

// This sends data if we've hit the delimiter
var	sendDataToSubscriber = function() {
	var data = readUntil(delimiter);
	
	if (data && data.length > 0) {
		subscribeCallback(data, { keepCallback: true });
		
		// in case there is more data to send
		sendDataToSubscriber();
	}
}

var receiveStringLoop = function (reader) {
	// read one byte at a time
	reader.loadAsync(1).done(function (size) {
		if (size != 1) {
			bluetoothSerial.disconnect();
			console.log('The underlying socket was closed before we were able to read the whole data. Client disconnected.');
			disconnectCallback("Socket closed"); // TODO determine why this isn't working
			return;
		}

		var byte = reader.readByte();
		receivedBytes.push(byte);

		if (subscribeRawCallback && typeof (subscribeRawCallback) !== "undefined") {
			subscribeRawCallback(new Uint8Array([byte]), { keepCallback: true });
		}

		if (subscribeCallback && typeof (subscribeCallback) !== "undefined") {
			sendDataToSubscriber();
		}

		WinJS.Promise.timeout().done(function () { return receiveStringLoop(reader); });
	}, function (error) {
		console.log('Failed to read the data, with error: ' + error);
		WinJS.Promise.timeout(1000).done(function () { return receiveStringLoop(reader); });
	});
}

module.exports = {

	list: function (success, failure, args) {

		deviceInfo.findAllAsync(
			Windows.Devices.Bluetooth.Rfcomm.RfcommDeviceService.getDeviceSelector(
				Windows.Devices.Bluetooth.Rfcomm.RfcommServiceId.serialPort			
			),
			null
		).then(function(devices) {
			if (devices.length > 0) {
				var results = [];

				for (var i = 0; i < devices.length; i++) {
                    // TODO parse MAC address out of the id
					// TODO see if there's a way to get the correct device name
					// The windows permission dialog has the correct name  					
					results.push({ name: devices[i].name, id: devices[i].id });
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
		disconnectCallback = failure;

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
							
							receiveStringLoop(reader);
							
							success("Connected.");
						},
						function(e){
							failure(e.toString());
						});
					} else {
						failure("Impossible to determine the HostName or the ServiceName.");
					}
				}
			},
			function(e){
				failure(e.toString());
			}
		);
	},
	
	connectInsecure: function(success, failure, args) {
		failure("connectInsecure is only available on Android.");
	},
	
	disconnect: function(success, failure, args) {			
		if (writer) {
			writer.close();
			writer = null;
		}		

    	if (reader) {
      		reader.close();
      		reader = null
    	}

		if (socket) {
			socket.close();
			socket = null;
			
		}
		
		success("Device disconnected.");		
	},
	
	// TODO find a better way to do this
	// If there are no RFCOMM devices paired, this reports Bluetooth is disabled
	isEnabled: function(success, failure, args) {
		deviceInfo.findAllAsync(
			Windows.Devices.Bluetooth.Rfcomm.RfcommDeviceService.getDeviceSelector(
				Windows.Devices.Bluetooth.Rfcomm.RfcommServiceId.serialPort			
			),
			null
		).then(function(devices) {
			if (devices.length > 0) {
				success(); // enabled
			} else {
				failure(); // not enabled
			}
		});
	},
	
	available: function(success, failure, args) {
		success(buffer.length);
	},
	
	read: function(success, failure, args) {
		var ret = bytesToString(receivedBytes);
		receivedBytes = [];
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
		subscribeCallback = success;
	},
	
	unsubscribe: function(success, failure, args) {
		delimiter = "";
		subscribeCallback = null;
		success("Unsubscribed.");
	},
	
	subscribeRaw: function(success, failure, args) {
		subscribeRawCallback = success;
	},
	
	unsubscribeRaw: function(success, failure, args) {
		subscribeRawCallback = null;
		success("Unsubscribed from raw data.");
	},
	
	clear: function(success, failure, args) {
		receivedBytes = [];
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

