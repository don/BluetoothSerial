#include <SoftwareSerial.h>

// https://www.sparkfun.com/products/10393
#define BUFFER_SIZE 64
 
int bluetoothTx = 2;  // TX-O pin of bluetooth mate, Arduino D2
int bluetoothRx = 3;  // RX-I pin of bluetooth mate, Arduino D3

SoftwareSerial bluetooth(bluetoothTx, bluetoothRx);
 
void setup() 
{ 
  Serial.begin(9600);
  setupBluetooth();
  Serial.println("\nChat Sparkfun Version\n");
} 

unsigned char buf[BUFFER_SIZE] = {0};
unsigned char len = 0;

void loop() {
  
  if (bluetooth.available()) {
    Serial.write("Them: ");
    while (bluetooth.available()) {
      Serial.write(bluetooth.read());
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
  if (len < BUFFER_SIZE) {
    buf[len++] = c;
  } // TODO warn, or send data
}

void sendData() {
  Serial.write("Us: ");
  for (int i = 0; i < len; i++) {
    bluetooth.write(buf[i]);
    Serial.write(buf[i]);
  }
  bluetooth.write(0xA);
  Serial.write(0xA); // TODO test on windows
  len = 0;
  bluetooth.flush();  
} 
 
void setupBluetooth() {
  bluetooth.begin(115200);  // The Bluetooth Mate defaults to 115200bps
  bluetooth.print("$$$");  // Enter command mode
  delay(100);  // Short delay, wait for the Mate to send back CMD
  bluetooth.println("U,9600,N");  // Temporarily Change the baudrate to 9600, no parity
  // 115200 can be too fast at times for NewSoftSerial to relay the data reliably
  bluetooth.begin(9600);  // Start bluetooth serial at 9600
}



