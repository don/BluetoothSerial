#include <Arduino.h>
#include <SoftwareSerial.h>

// http://redbearlab.com/blemini/
//BLE Mini is connected to pin 2 and 3.
SoftwareSerial BLEMini(2, 3);

void setup() {
  BLEMini.begin(57600);
  Serial.begin(57600);
  Serial.println("\nChat BLEMini Version\n");
}

unsigned char buf[16] = {0};
unsigned char len = 0;

void loop() {
  
  if (BLEMini.available()) {
    Serial.write("Them: ");
    while (BLEMini.available()) {
      Serial.write(BLEMini.read());
    }
  }
  
  while (Serial.available()) {
    unsigned char c = Serial.read();
    if (c == 0xA || c == 0xD) { // \n or \r
      sendData();
    } else {
      bufferData(c);
    }
  }
}

void bufferData(char c) {
  if (len < 16) {
    buf[len++] = c;
  } // TODO warn, or send data
}

void sendData() {
  Serial.write("Us: ");
  for (int i = 0; i < len; i++) {
    BLEMini.write(buf[i]);
    Serial.write(buf[i]);
  }
  BLEMini.write(0xA);
  Serial.write(0xA); // TODO test on windows
  len = 0;  
}