#include <SoftwareSerial.h>  

int neoPixelPin = 5;
int bluetoothTx = 6;  // TX-O pin of bluetooth mate
int bluetoothRx = 7;  // RX-I pin of bluetooth mate

SoftwareSerial bluetooth(bluetoothTx, bluetoothRx);

#include <Adafruit_NeoPixel.h>

// Parameter 1 = number of pixels in strip
// Parameter 2 = pin number (most are valid)
// Parameter 3 = pixel type flags
Adafruit_NeoPixel pixels = Adafruit_NeoPixel(60, neoPixelPin, NEO_GRB + NEO_KHZ800);
uint16_t color;

void setup() {
  Serial.begin(9600);
  pixels.begin();
  pixels.show(); // Initialize all pixels to 'off'.
  setupBluetooth();
  Serial.println("Hello."); 
}

void loop() {
  // Assumes a string in from the serial port like so:
  // c red, green, blue \n
  // for example: "c255,0,0\n" shows red
  // for example: "c0,0,255\n" shows blue

  int red = 0;
  int green = 0;
  int blue = 0;

  if (bluetooth.find("c")) {
    red = bluetooth.parseInt();  // parses numeric characters before the comma
    green = bluetooth.parseInt();// parses numeric characters after the comma
    blue = bluetooth.parseInt(); // parses numeric characters after the comma
    
    Serial.print("Setting color to: " ); // print to console for debugging
    Serial.print(red);Serial.print(", ");
    Serial.print(green);Serial.print(", ");
    Serial.println(blue);
    
    showColor(red, green, blue);
  }
}

void showColor(int red, int green, int blue) {
  uint32_t c = pixels.Color(red, green, blue);
  for(uint16_t i=0; i<pixels.numPixels(); i++) {
      pixels.setPixelColor(i, c);
  }  
  pixels.show();
}

// init for Sparkfun radio (works for BLEmini too)
void setupBluetooth() {
  bluetooth.begin(115200);  // The Bluetooth Mate defaults to 115200bps
  bluetooth.print("$$$");  // Enter command mode
  delay(100);  // Short delay, wait for the Mate to send back CMD
  bluetooth.println("U,9600,N");  // Temporarily Change the baudrate to 9600, no parity
  // 115200 can be too fast at times for NewSoftSerial to relay the data reliably
  bluetooth.begin(9600);  // Start bluetooth serial at 9600
}
