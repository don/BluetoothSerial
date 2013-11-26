#include <SoftwareSerial.h>

// http://www.seeedstudio.com/depot/bluetooth-shield-p-866.html
#define RxD 6
#define TxD 7
 
SoftwareSerial bluetooth(RxD,TxD);
 
int counter = 0;
 
void setup() 
{ 
  Serial.begin(9600);
  setupBluetooth();
  Serial.println("\nBluetooth Counter\n");
} 

void loop() {
  Serial.println(counter);
  bluetooth.println(counter);
  counter++;
  delay(1000);
}
 
// Seeed Studio Bluetooth Shield
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

// Use this version for Sparkfun radio (works for BLEmini too)
// void setupBluetooth() {
//   bluetooth.begin(115200);  // The Bluetooth Mate defaults to 115200bps
//   bluetooth.print("$$$");  // Enter command mode
//   delay(100);  // Short delay, wait for the Mate to send back CMD
//   bluetooth.println("U,9600,N");  // Temporarily Change the baudrate to 9600, no parity
//   // 115200 can be too fast at times for NewSoftSerial to relay the data reliably
//   bluetooth.begin(9600);  // Start bluetooth serial at 9600
// }





