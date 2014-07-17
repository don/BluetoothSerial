// Bluetooth Serial LED Example for Bluefruit LE
// (c) 2014 Don Coleman
// 
// BluetoothSerial https://github.com/don/BluetoothSerial
// LED Example https://github.com/don/BluetoothSerial/tree/master/examples/LED
// Bluefruit LE http://adafru.it/1697
// Bluefruit LE Driver https://github.com/adafruit/Adafruit_nRF8001

#include <SPI.h>
#include "Adafruit_BLE_UART.h"
#include <Adafruit_NeoPixel.h>

#define NEO_PIXEL_PIN 5

// Connect CLK/MISO/MOSI to hardware SPI
// e.g. On UNO & compatible: CLK=13, MISO = 12, MOSI = 11
#define ADAFRUITBLE_REQ 10
#define ADAFRUITBLE_RDY 2 // interrupt pin 2 or 3 on UNO
#define ADAFRUITBLE_RST 9

// Parameter 1 = number of pixels in strip
// Parameter 2 = pin number (most are valid)
// Parameter 3 = pixel type flags
Adafruit_NeoPixel pixels = Adafruit_NeoPixel(16, NEO_PIXEL_PIN, NEO_GRB + NEO_KHZ800);
uint16_t color;

// Status from the Bluefruit LE driver
int lastStatus = ACI_EVT_DISCONNECTED;

Adafruit_BLE_UART BTLEserial = Adafruit_BLE_UART(ADAFRUITBLE_REQ, ADAFRUITBLE_RDY, ADAFRUITBLE_RST);

void setup() {
  Serial.begin(9600);
  Serial.println(F("Bluetooth Serial - Adafruit Bluefruit Low Energy Edition"));

  pixels.begin();
  pixels.show(); // Initialize all pixels to 'off'.

  BTLEserial.begin();
}

void loop() {

  // Tell the nRF8001 to do whatever it should be working on
  BTLEserial.pollACI();

  int status = BTLEserial.getState();
      
  if (status != lastStatus) {
    if (status == ACI_EVT_DEVICE_STARTED) {
      Serial.println(F("* Advertising Started"));
    } 
    else if (status == ACI_EVT_CONNECTED) {
      Serial.println(F("* Connected!"));
    }     
    else if (status == ACI_EVT_DISCONNECTED) {
      Serial.println(F("* Disconnected or advertising timed out."));
    } 
    // save for next loop
    lastStatus = status;
  }
    
  if (status == ACI_EVT_CONNECTED) {
    
    // see if there's any data from bluetooth
    if (BTLEserial.available()) {
      Serial.print("* ");
      Serial.print(BTLEserial.available());
      Serial.println(F(" bytes available from BTLE"));
    }

     // Assumes a string in from the serial port like so:
     // c red, green, blue \n
     // for example: "c255,0,0\n" shows red
     // for example: "c0,0,255\n" shows blue
    if (BTLEserial.find("c")) {
      int red = BTLEserial.parseInt();     // parses numeric characters before the comma
      int green = BTLEserial.parseInt();   // parses numeric characters after the comma
      int blue = BTLEserial.parseInt();    // parses numeric characters after the comma
             
      Serial.print("Setting color to: " ); // print to console for debugging
      Serial.print(red);Serial.print(", ");
      Serial.print(green);Serial.print(", ");
      Serial.println(blue);
      
      showColor(red, green, blue);
    }
    
  }
  
}

void showColor(int red, int green, int blue) {
  uint32_t c = pixels.Color(red, green, blue);
  for(uint16_t i=0; i<pixels.numPixels(); i++) {
      pixels.setPixelColor(i, c);
  }  
  pixels.show();
}

