var macAddress = "00:06:66:4D:AA:AA";
var bluetoothSerial = cordova.require('bluetoothSerial');

var app = {
    initialize: function() {
        this.bind();
    },
    bind: function() {
        document.addEventListener('deviceready', this.deviceready, false);
    },
    deviceready: function() {
        
        var throttledOnColorChange = _.throttle(app.onColorChange, 200);

        //$('input').on('change', app.onColorChange);
        $('input').on('change', throttledOnColorChange);

        connectLabel.addEventListener('touchstart', function(evt) { 
            console.log("touchstart");
            app.connect();
        });

        statusLabel.addEventListener('touchstart', function(evt) { 
            console.log("status.check");
            app.status();
        });
    },
    connect: function () {  
        console.log("connect");      
        bluetoothSerial.isConnected(function (connected) {
            console.log("connected is " + connected);
            if (!connected) {
                console.log("connecting");                                      
                bluetoothSerial.connect(
                    macAddress, 
                    function() { output.innerHTML = "Connected"; }, 
                    function (error) { output.innerHTML = error; }
                );        
            } else {
                console.log("already connected");
            }            
        });
    },
    status: function () {
        bluetoothSerial.isConnected(function (connected) {
            if (connected) {
                output.innerHTML = "Connected!";
            } else {
                output.innerHTML = "Not Connected";                
            }
        });
    },
    onColorChange: function (evt) { 
        var c = app.getColor();
        output.innerHTML = c;
        previewColor.style.backgroundColor = "rgb(" + c + ")";
        app.sendToArduino(c);                    
    },
    getColor: function () {
        var color = [];
        color.push(red.value);
        color.push(green.value);
        color.push(blue.value);
        return color.join(',');
    },    
    sendToArduino: function(c) {
        bluetoothSerial.write("c" + c + "\n");
    }
};