package com.megster.cordova

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothServerSocket
import android.bluetooth.BluetoothSocket
import android.util.Log
import org.apache.cordova.BuildConfig
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.util.*

object BluetoothSerialService {

    private const val LOG_TAG = "BluetoothSerialService"
    // Name for the SDP record when creating server socket
    private const val NAME_INSECURE = "PhoneGapBluetoothSerialService"
    // Unique UUID for this application
    private val MY_UUID_INSECURE = UUID.fromString("77718142-B389-4772-93BD-52BDBB2C0777")
    // Constants that indicate the current connection state
    const val STATE_NONE = 0 // we're doing nothing
    const val STATE_LISTEN = 1 // now listening for incoming connections
    const val STATE_CONNECTING = 2 // now initiating an outgoing connection
    const val STATE_CONNECTED = 3 // now connected to a remote device

    private val bluetoothAdapter: BluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
    private var insecureAcceptThread: AcceptThread? = null
    private var connectThread: ConnectThread? = null
    private var connectedThread: ConnectedThread? = null
    private var mState: Int
    private var connectedCallback: ConnectedCallback? = null
    private var closedCallback: ClosedCallback? = null
    private var dataCallback: DataCallback? = null


    /**
     * Return the current connection state.  */// Give the new state to the Handler so the UI Activity can update
    /**
     * Set the current state of the chat connection
     * @param state  An integer defining the current connection state
     */
    @get:Synchronized
    @set:Synchronized
    var state: Int
        get() = mState
        private set(state) {
            if (BuildConfig.DEBUG) Log.d(LOG_TAG, "setState() $mState -> $state")
            mState = state

            if (mState == STATE_CONNECTED) {
                connectedCallback?.connected()
            }
        }

    /**
     * Constructor. Prepares a new BluetoothSerial session.
     */
    init {
        mState = STATE_NONE
    }

    /**
     * Start the chat service. Specifically start AcceptThread to begin a
     * session in listening (server) mode. Called by the Activity onResume()  */
    @Synchronized
    fun start() {
        if (BuildConfig.DEBUG) Log.d(LOG_TAG, "start")
        // Cancel any thread attempting to make a connection
        if (connectThread != null) {
            connectThread!!.cancel()
            connectThread = null
        }
        // Cancel any thread currently running a connection
        if (connectedThread != null) {
            connectedThread!!.cancel()
            connectedThread = null
        }
        state = STATE_LISTEN
        if (insecureAcceptThread == null) {
            insecureAcceptThread = AcceptThread(false)
            insecureAcceptThread!!.start()
        }
    }

    /**
     * Start the ConnectThread to initiate a connection to a remote device.
     * @param device  The BluetoothDevice to connect
     * @param secure Socket Security type - Secure (true) , Insecure (false)
     */
    @Synchronized
    fun connect(device: BluetoothDevice) {
        if (BuildConfig.DEBUG) Log.d(LOG_TAG, "connect to: $device")
        // Cancel any thread attempting to make a connection
        if (mState == STATE_CONNECTING) {
            if (connectThread != null) {
                connectThread!!.cancel()
                connectThread = null
            }
        }
        // Cancel any thread currently running a connection
        if (connectedThread != null) {
            connectedThread!!.cancel()
            connectedThread = null
        }
        // Start the thread to connect with the given device
        connectThread = ConnectThread(device)
        connectThread!!.start()
        state = STATE_CONNECTING
    }

    /**
     * Start the ConnectedThread to begin managing a Bluetooth connection
     * @param socket  The BluetoothSocket on which the connection was made
     * @param device  The BluetoothDevice that has been connected
     */
    @Synchronized
    fun connected(socket: BluetoothSocket?, socketType: String) {
        if (BuildConfig.DEBUG) Log.d(LOG_TAG, "connected, Socket Type:$socketType")
        // Cancel the thread that completed the connection
        if (connectThread != null) {
            connectThread!!.cancel()
            connectThread = null
        }
        // Cancel any thread currently running a connection
        if (connectedThread != null) {
            connectedThread!!.cancel()
            connectedThread = null
        }
        if (insecureAcceptThread != null) {
            insecureAcceptThread!!.cancel()
            insecureAcceptThread = null
        }
        // Start the thread to manage the connection and perform transmissions
        connectedThread = ConnectedThread(socket, socketType)
        connectedThread!!.start()
        state = STATE_CONNECTED
    }

    /**
     * Stop all threads
     */
    @Synchronized
    fun stop() {
        if (BuildConfig.DEBUG) Log.d(LOG_TAG, "stop")
        if (connectThread != null) {
            connectThread!!.cancel()
            connectThread = null
        }
        if (connectedThread != null) {
            connectedThread!!.cancel()
            connectedThread = null
        }
        if (insecureAcceptThread != null) {
            insecureAcceptThread!!.cancel()
            insecureAcceptThread = null
        }
        state = STATE_NONE
    }

    /**
     * Write to the ConnectedThread in an unsynchronized manner
     * @param out The bytes to write
     * @see ConnectedThread.write
     */
    fun write(out: ByteArray?) { // Create temporary object
        var r: ConnectedThread? = null
        // Synchronize a copy of the ConnectedThread
        synchronized(BluetoothSerialService) {
            if (mState != STATE_CONNECTED) return
            r = connectedThread
        }
        // Perform the write unsynchronized
        r?.write(out)
    }

    private fun connectionLost() {
        closedCallback?.closed()
    }

    /**
     * This thread runs while listening for incoming connections. It behaves
     * like a server-side client. It runs until a connection is accepted
     * (or until cancelled).
     */
    private class AcceptThread(secure: Boolean) : Thread() {
        // The local server socket
        private val mmServerSocket: BluetoothServerSocket?
        private val mSocketType: String
        override fun run() {
            if (BuildConfig.DEBUG) Log.d(LOG_TAG, "Socket Type: " + mSocketType + "BEGIN mAcceptThread" + this)
            name = "AcceptThread$mSocketType"
            var socket: BluetoothSocket?
            // Listen to the server socket if we're not connected
            while (mState != STATE_CONNECTED) {
                socket = try { // This is a blocking call and will only return on a
// successful connection or an exception
                    mmServerSocket?.accept()
                } catch (e: IOException) {
                    Log.e(LOG_TAG, "Socket Type: " + mSocketType + "accept() failed", e)
                    break
                }
                // If a connection was accepted
                if (socket != null) {
                    synchronized(this) {
                        when (mState) {
                            STATE_LISTEN, STATE_CONNECTING ->  // Situation normal. Start the connected thread.
                                connected(socket, mSocketType)
                            STATE_NONE, STATE_CONNECTED ->  // Either not ready or already connected. Terminate new socket.
                                try {
                                    socket.close()
                                } catch (e: IOException) {
                                    Log.e(LOG_TAG, "Could not close unwanted socket", e)
                                }
                            else ->
                                Log.v(LOG_TAG, "State is: $mState")
                        }
                    }
                }
            }
            if (BuildConfig.DEBUG) Log.i(LOG_TAG, "END mAcceptThread, socket Type: $mSocketType")
        }

        fun cancel() {
            if (BuildConfig.DEBUG) Log.d(LOG_TAG, "Socket Type" + mSocketType + "cancel " + this)
            try {
                mmServerSocket!!.close()
            } catch (e: IOException) {
                Log.e(LOG_TAG, "Socket Type" + mSocketType + "close() of server failed", e)
            }
        }

        init {
            var tmp: BluetoothServerSocket? = null
            mSocketType = if (secure) "Secure" else "Insecure"
            // Create a new listening server socket
            try {
                tmp = bluetoothAdapter.listenUsingInsecureRfcommWithServiceRecord(NAME_INSECURE, MY_UUID_INSECURE)
            } catch (e: IOException) {
                Log.e(LOG_TAG, "Socket Type: " + mSocketType + "listen() failed", e)
            }
            mmServerSocket = tmp
        }
    }

    /**
     * This thread runs while attempting to make an outgoing connection
     * with a device. It runs straight through; the connection either
     * succeeds or fails.
     */
    private class ConnectThread(private val mmDevice: BluetoothDevice) : Thread() {
        private /*final*/  var mmSocket: BluetoothSocket?
        private val mSocketType: String
        override fun run() {
            Log.i(LOG_TAG, "BEGIN mConnectThread SocketType:$mSocketType")
            name = "ConnectThread$mSocketType"
            // Make a connection to the BluetoothSocket
            try { // This is a blocking call and will only return on a successful connection or an exception
                Log.i(LOG_TAG, "Connecting to socket...")
                mmSocket!!.connect()
                Log.i(LOG_TAG, "Connected")
            } catch (e: IOException) {
                Log.e(LOG_TAG, e.toString())
                // Some 4.1 devices have problems, try an alternative way to connect
// See https://github.com/don/BluetoothSerial/issues/89
                try {
                    Log.i(LOG_TAG, "Trying fallback...")
                    mmSocket = mmDevice.javaClass.getMethod("createInsecureRfcommSocket", *arrayOf<Class<*>?>(Int::class.javaPrimitiveType)).invoke(mmDevice, 1) as BluetoothSocket
                    mmSocket!!.connect()
                    Log.i(LOG_TAG, "Connected")
                } catch (e2: Exception) {
                    Log.e(LOG_TAG, "Couldn't establish a Bluetooth connection.")
                    try {
                        mmSocket!!.close()
                    } catch (e3: IOException) {
                        Log.e(LOG_TAG, "unable to close() $mSocketType socket during connection failure", e3)
                    }
                    connectionLost()
                    return
                }
            }
            // Reset the ConnectThread because we're done
            synchronized(BluetoothSerialService) { connectThread = null }
            // Start the connected thread
            connected(mmSocket, mSocketType)
        }

        fun cancel() {
            try {
                mmSocket!!.close()
            } catch (e: IOException) {
                Log.e(LOG_TAG, "close() of connect $mSocketType socket failed", e)
            }
        }

        init {
            var tmp: BluetoothSocket? = null
            mSocketType = "Insecure"
            // Get a BluetoothSocket for a connection with the given BluetoothDevice
            try {
                tmp = mmDevice.createInsecureRfcommSocketToServiceRecord(MY_UUID_INSECURE)
            } catch (e: IOException) {
                Log.e(LOG_TAG, "Socket Type: " + mSocketType + "create() failed", e)
            }
            mmSocket = tmp
        }
    }

    /**
     * This thread runs during a connection with a remote device.
     * It handles all incoming and outgoing transmissions.
     */
    private class ConnectedThread(socket: BluetoothSocket?, socketType: String) : Thread() {
        private val mmSocket: BluetoothSocket?
        private val mmInStream: InputStream?
        private val mmOutStream: OutputStream?
        override fun run() {
            Log.i(LOG_TAG, "BEGIN mConnectedThread")
            val buffer = ByteArray(1024)
            var bytes: Int
            // Keep listening to the InputStream while connected
            while (true) {
                try { // Read from the InputStream
                    bytes = mmInStream!!.read(buffer)
                    // Send the raw bytestream to the dataCallback if it exists.
// We make a copy because the full array can have extra data at the end
// when / if we read less than its size.
                    if (bytes > 0) {
                        val rawData = Arrays.copyOf(buffer, bytes)
                        dataCallback?.onData(rawData)
                    }
                } catch (e: IOException) {
                    Log.e(LOG_TAG, "disconnected", e)
                    connectionLost()
                    // Start the service over to restart listening mode
                    BluetoothSerialService.start()
                    break
                }
            }
        }

        /**
         * Write to the connected OutStream.
         * @param buffer  The bytes to write
         */
        fun write(buffer: ByteArray?) {
            try {
                mmOutStream!!.write(buffer)
            } catch (e: IOException) {
                Log.e(LOG_TAG, "Exception during write", e)
            }
        }

        fun cancel() {
            try {
                mmSocket!!.close()
            } catch (e: IOException) {
                Log.e(LOG_TAG, "close() of connect socket failed", e)
            }
        }

        init {
            Log.d(LOG_TAG, "create ConnectedThread: $socketType")
            mmSocket = socket
            var tmpIn: InputStream? = null
            var tmpOut: OutputStream? = null
            // Get the BluetoothSocket input and output streams
            try {
                tmpIn = socket!!.inputStream
                tmpOut = socket.outputStream
            } catch (e: IOException) {
                Log.e(LOG_TAG, "temp sockets not created", e)
            }
            mmInStream = tmpIn
            mmOutStream = tmpOut
        }
    }

    interface ConnectedCallback {
        fun connected()
    }

    interface ClosedCallback {
        fun closed()
    }

    interface DataCallback {
        fun onData(data: ByteArray)
    }

    fun registerConnectedCallback(connectedCallback: ConnectedCallback) {
        this.connectedCallback = connectedCallback
    }

    fun registerClosedCallback(closedCallback: ClosedCallback) {
        this.closedCallback = closedCallback
    }

    fun registerDataCallback(dataCallback: DataCallback) {
        this.dataCallback = dataCallback;
    }
}