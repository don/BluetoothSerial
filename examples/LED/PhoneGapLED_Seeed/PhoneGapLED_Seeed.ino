#include <SoftwareSerial.h>  

int neoPixelPin = 5;
int bluetoothTx = 6;
int bluetoothRx = 7;

SoftwareSerial bluetooth(bluetoothTx, bluetoothRx);

#include <Adafruit_NeoPixel.h>

// Parameter 1 = number of pixels in strip
// Parameter 2 = pin number (most are valid)
// Parameter 3 = pixel type flags
Adafruit_NeoPixel strip = Adafruit_NeoPixel(60, neoPixelPin, NEO_GRB + NEO_KHZ800);
uint16_t color;

void setup() {
  Serial.begin(9600);
  strip.begin();
  strip.show(); // Initialize all pixels to 'off'.
  setupBluetooth();
  Serial.println("Hello."); 
}

void loop() {
  // Assumes a string in from the serial port like so:
  // s ledNumber, brightness \n
  // for example: "c255,0,0\n":
  // for example: "c0,0,255\n":

  int red = 0;
  int green = 0;
  int blue = 0;

  if (bluetooth.find("c")) {
    red = bluetooth.parseInt(); // parses numeric characters before the comma
    green = bluetooth.parseInt();// parses numeric characters after the comma
    blue = bluetooth.parseInt(); // parses numeric characters before the comma
    
    // print the results back to the sender:
    Serial.print("Setting color to: " );
    Serial.print(red);
    Serial.print(", ");
    Serial.print(green);
    Serial.print(", ");
    Serial.println(blue);

    // set the LED:
    solid(red, green, blue);
  }
}

void solid(int red, int green, int blue) {
  uint32_t c = strip.Color(red, green, blue);
  for(uint16_t i=0; i<strip.numPixels(); i++) {
      strip.setPixelColor(i, c);
  }  
  strip.show();
}

// init for Sparkfun radio
void setupBluetoothSparkfun() {
  bluetooth.begin(115200);  // The Bluetooth Mate defaults to 115200bps
  bluetooth.print("$$$");  // Enter command mode
  delay(100);  // Short delay, wait for the Mate to send back CMD
  bluetooth.println("U,9600,N");  // Temporarily Change the baudrate to 9600, no parity
  // 115200 can be too fast at times for NewSoftSerial to relay the data reliably
  bluetooth.begin(9600);  // Start bluetooth serial at 9600
}

void setupBluetooth()
{
  bluetooth.begin(38400); //Set BluetoothBee BaudRate to default baud rate 38400
  bluetooth.print("\r\n+STWMOD=0\r\n"); //set the bluetooth work in slave mode
  bluetooth.print("\r\n+STNA=SeeedBTSlave\r\n"); //set the bluetooth name as "SeeedBTSlave"
  bluetooth.print("\r\n+STOAUT=1\r\n"); // Permit Paired device to connect me
  bluetooth.print("\r\n+STAUTO=0\r\n"); // Auto-connection should be forbidden here
  delay(2000); // This delay is required.
  bluetooth.print("\r\n+INQ=1\r\n"); //make the slave bluetooth inquirable 
//  Serial.println("The slave bluetooth is inquirable!");  // discoverable??
  delay(2000); // This delay is required.
  bluetooth.flush();
}
