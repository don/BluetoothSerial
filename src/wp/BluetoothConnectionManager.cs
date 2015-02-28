// originally based on http://developer.nokia.com/community/wiki/Windows_Phone_8_communicating_with_Arduino_using_Bluetooth

using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Windows.Networking;
using Windows.Networking.Sockets;
using Windows.Storage.Streams;

namespace BluetoothConnectionManager
{
    /// <summary>
    /// Class to control the bluetooth connection to the Arduino.
    /// </summary>
    public class ConnectionManager
    {
        /// <summary>
        /// Socket used to communicate with Arduino.
        /// </summary>
        private StreamSocket socket;

        /// <summary>
        /// DataWriter used to send commands easily.
        /// </summary>
        private DataWriter dataWriter;

        /// <summary>
        /// DataReader used to receive messages easily.
        /// </summary>
        private DataReader dataReader;

        /// <summary>
        /// Thread used to keep reading data from socket.
        /// </summary>
        private BackgroundWorker dataReadWorker;

        /// <summary>
        /// Delegate used by event handler.
        /// </summary>
        /// <param name="message">The message received.</param>
        public delegate void ByteReceivedHandler(byte data);

        /// <summary>
        /// Event fired when a new byte is received from Arduino.
        /// </summary>
        public event ByteReceivedHandler ByteReceived;

        // TODO this event stuff is probably overkill
        public delegate void ConnectionSuccessHandler();
        public delegate void ConnectionFailureHandler(string reason);

        public event ConnectionSuccessHandler ConnectionSuccess;
        public event ConnectionFailureHandler ConnectionFailure;

        /// <summary>
        /// Initialize the manager, should be called in OnNavigatedTo of main page.
        /// </summary>
        public void Initialize()
        {
            socket = new StreamSocket();
            dataReadWorker = new BackgroundWorker();
            dataReadWorker.WorkerSupportsCancellation = true;
            dataReadWorker.DoWork += new DoWorkEventHandler(ReceiveMessages);
        }

        /// <summary>
        /// Finalize the connection manager, should be called in OnNavigatedFrom of main page.
        /// </summary>
        public void Terminate()
        {
            if (socket != null)
            {
                socket.Dispose();
            }
            if (dataReadWorker != null)
            {
                dataReadWorker.CancelAsync();
            }
        }

        /// <summary>
        /// Connect to the given host device.
        /// </summary>
        /// <param name="deviceHostName">The host device name.</param>
        public async void Connect(HostName deviceHostName)
        {
            if (socket != null) 
            {
                try
                {
                    await socket.ConnectAsync(deviceHostName, "1");
                    dataReader = new DataReader(socket.InputStream);
                    dataReadWorker.RunWorkerAsync();
                    dataWriter = new DataWriter(socket.OutputStream);
                }
                catch (Exception ex)
                {
                    Debug.WriteLine(ex);
                    ConnectionFailure(ex.Message);
                }
            }
            else
            {
                ConnectionFailure("Socket is null");
            }
        }

        /// <summary>
        /// Receive messages from the Arduino through bluetooth.
        /// </summary>
        private async void ReceiveMessages(object sender, DoWorkEventArgs e)
        {
            Debug.WriteLine("Received Message Worker");
            ConnectionSuccess();
            try
            {
                while (true)
                {
                    // TODO see if there's a better way to do this
                    uint sizeFieldCount = await dataReader.LoadAsync(1);
                    if (sizeFieldCount != 1)
                    {
                        // The underlying socket was closed before we were able to read the whole data.
                        ConnectionFailure("Socket closed");
                        return;
                    }
                    uint bite = dataReader.ReadByte();
                    Debug.WriteLine(bite);
                    ByteReceived((byte)bite);
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine(ex.Message);
                ConnectionFailure(ex.Message);
            }

        }

        public async Task<bool> WriteData(byte[] data)
        {
            if (dataWriter != null)
            {
                dataWriter.WriteBytes(data);
                await dataWriter.StoreAsync();
                return true;
            }
            else
            {
                return false;
            }
        }
    }
}

