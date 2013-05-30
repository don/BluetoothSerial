#include <SoftwareSerial.h>  

int bluetoothTx = 2;  // TX-O pin of bluetooth mate, Arduino D2
int bluetoothRx = 3;  // RX-I pin of bluetooth mate, Arduino D3

SoftwareSerial bluetooth(bluetoothTx, bluetoothRx);

#include <Adafruit_NeoPixel.h>

// Parameter 1 = number of pixels in strip
// Parameter 2 = pin number (most are valid)
// Parameter 3 = pixel type flags, add together as needed:
//   NEO_RGB     Pixels are wired for RGB bitstream
//   NEO_GRB     Pixels are wired for GRB bitstream
//   NEO_KHZ400  400 KHz bitstream (e.g. FLORA pixels)
//   NEO_KHZ800  800 KHz bitstream (e.g. High Density LED strip)
Adafruit_NeoPixel strip = Adafruit_NeoPixel(60, 6, NEO_GRB + NEO_KHZ800);
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

void setupBluetooth() {
  bluetooth.begin(115200);  // The Bluetooth Mate defaults to 115200bps
  bluetooth.print("$$$");  // Enter command mode
  delay(100);  // Short delay, wait for the Mate to send back CMD
  bluetooth.println("U,9600,N");  // Temporarily Change the baudrate to 9600, no parity
  // 115200 can be too fast at times for NewSoftSerial to relay the data reliably
  bluetooth.begin(9600);  // Start bluetooth serial at 9600
}
