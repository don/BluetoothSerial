#include <SoftwareSerial.h>

// http://www.seeedstudio.com/depot/bluetooth-shield-p-866.html
#define RxD 6
#define TxD 7
#define BUFFER_SIZE 64
 
SoftwareSerial bluetooth(RxD,TxD);
 
void setup() 
{ 
  Serial.begin(9600);
  setupBluetooth();
  Serial.println("\nChat Seeed Version\n");
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




