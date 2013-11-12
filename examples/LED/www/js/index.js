//var macAddress = "00:06:66:4D:65:22"; // Sparkfun
var macAddress = "00:13:EF:00:08:8B"; // Seeed Studio

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
        bluetoothSerial.isConnected(
            function() {
                console.log("already connected");
            },
            function () {
                console.log("connecting");
                bluetoothSerial.connect(
                    macAddress,
                    function() { output.innerHTML = "Connected"; },
                    function (error) { output.innerHTML = error; }
                );
            }
        );
    },
    status: function () {
        bluetoothSerial.isConnected(
            function() {
                output.innerHTML = "Connected!";
            },
            function() {
                output.innerHTML = "Not Connected";
            }
        );
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