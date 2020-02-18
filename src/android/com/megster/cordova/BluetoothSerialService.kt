package com.megster.cordova

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothServerSocket
import android.bluetooth.BluetoothSocket
import android.os.Bundle
import android.os.Handler
import android.util.Log
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.util.*

/**
 * This class does all the work for setting up and managing Bluetooth
 * connections with other devices. It has a thread that listens for
 * incoming connections, a thread for connecting with a device, and a
 * thread for performing data transmissions when connected.
 *
 * This code was based on the Android SDK BluetoothChat Sample
 * $ANDROID_SDK/samples/android-17/BluetoothChat
 */
class BluetoothSerialService(handler: Handler) {
    // Member fields
    private val mAdapter: BluetoothAdapter
    private val mHandler: Handler
    private var mInsecureAcceptThread: AcceptThread? = null
    private var mConnectThread: ConnectThread? = null
    private var mConnectedThread: ConnectedThread? = null
    private var mState: Int

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
            if (D) Log.d(TAG, "setState() $mState -> $state")
            mState = state
            // Give the new state to the Handler so the UI Activity can update
            mHandler.obtainMessage(BluetoothSerial.MESSAGE_STATE_CHANGE, state, -1).sendToTarget()
        }

    /**
     * Start the chat service. Specifically start AcceptThread to begin a
     * session in listening (server) mode. Called by the Activity onResume()  */
    @Synchronized
    fun start() {
        if (D) Log.d(TAG, "start")
        // Cancel any thread attempting to make a connection
        if (mConnectThread != null) {
            mConnectThread!!.cancel()
            mConnectThread = null
        }
        // Cancel any thread currently running a connection
        if (mConnectedThread != null) {
            mConnectedThread!!.cancel()
            mConnectedThread = null
        }
        state = STATE_LISTEN
        if (mInsecureAcceptThread == null) {
            mInsecureAcceptThread = AcceptThread(false)
            mInsecureAcceptThread!!.start()
        }
    }

    /**
     * Start the ConnectThread to initiate a connection to a remote device.
     * @param device  The BluetoothDevice to connect
     * @param secure Socket Security type - Secure (true) , Insecure (false)
     */
    @Synchronized
    fun connect(device: BluetoothDevice, secure: Boolean) {
        if (D) Log.d(TAG, "connect to: $device")
        // Cancel any thread attempting to make a connection
        if (mState == STATE_CONNECTING) {
            if (mConnectThread != null) {
                mConnectThread!!.cancel()
                mConnectThread = null
            }
        }
        // Cancel any thread currently running a connection
        if (mConnectedThread != null) {
            mConnectedThread!!.cancel()
            mConnectedThread = null
        }
        // Start the thread to connect with the given device
        mConnectThread = ConnectThread(device)
        mConnectThread!!.start()
        state = STATE_CONNECTING
    }

    /**
     * Start the ConnectedThread to begin managing a Bluetooth connection
     * @param socket  The BluetoothSocket on which the connection was made
     * @param device  The BluetoothDevice that has been connected
     */
    @Synchronized
    fun connected(socket: BluetoothSocket?, device: BluetoothDevice, socketType: String) {
        if (D) Log.d(TAG, "connected, Socket Type:$socketType")
        // Cancel the thread that completed the connection
        if (mConnectThread != null) {
            mConnectThread!!.cancel()
            mConnectThread = null
        }
        // Cancel any thread currently running a connection
        if (mConnectedThread != null) {
            mConnectedThread!!.cancel()
            mConnectedThread = null
        }
        if (mInsecureAcceptThread != null) {
            mInsecureAcceptThread!!.cancel()
            mInsecureAcceptThread = null
        }
        // Start the thread to manage the connection and perform transmissions
        mConnectedThread = ConnectedThread(socket, socketType)
        mConnectedThread!!.start()
        // Send the name of the connected device back to the UI Activity
        val msg = mHandler.obtainMessage(BluetoothSerial.MESSAGE_DEVICE_NAME)
        val bundle = Bundle()
        bundle.putString(BluetoothSerial.DEVICE_NAME, device.name)
        msg.data = bundle
        mHandler.sendMessage(msg)
        state = STATE_CONNECTED
    }

    /**
     * Stop all threads
     */
    @Synchronized
    fun stop() {
        if (D) Log.d(TAG, "stop")
        if (mConnectThread != null) {
            mConnectThread!!.cancel()
            mConnectThread = null
        }
        if (mConnectedThread != null) {
            mConnectedThread!!.cancel()
            mConnectedThread = null
        }
        if (mInsecureAcceptThread != null) {
            mInsecureAcceptThread!!.cancel()
            mInsecureAcceptThread = null
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
        synchronized(this) {
            if (mState != STATE_CONNECTED) return
            r = mConnectedThread
        }
        // Perform the write unsynchronized
        r?.write(out)
    }

    /**
     * Indicate that the connection attempt failed and notify the UI Activity.
     */
    private fun connectionFailed() { // Send a failure message back to the Activity
        val msg = mHandler.obtainMessage(BluetoothSerial.MESSAGE_TOAST)
        val bundle = Bundle()
        bundle.putString(BluetoothSerial.TOAST, "Unable to connect to device")
        msg.data = bundle
        mHandler.sendMessage(msg)
        // Start the service over to restart listening mode
        start()
    }

    /**
     * Indicate that the connection was lost and notify the UI Activity.
     */
    private fun connectionLost() { // Send a failure message back to the Activity
        val msg = mHandler.obtainMessage(BluetoothSerial.MESSAGE_TOAST)
        val bundle = Bundle()
        bundle.putString(BluetoothSerial.TOAST, "Device connection was lost")
        msg.data = bundle
        mHandler.sendMessage(msg)
        // Start the service over to restart listening mode
        start()
    }

    /**
     * This thread runs while listening for incoming connections. It behaves
     * like a server-side client. It runs until a connection is accepted
     * (or until cancelled).
     */
    private inner class AcceptThread(secure: Boolean) : Thread() {
        // The local server socket
        private val mmServerSocket: BluetoothServerSocket?
        private val mSocketType: String
        override fun run() {
            if (D) Log.d(TAG, "Socket Type: " + mSocketType + "BEGIN mAcceptThread" + this)
            name = "AcceptThread$mSocketType"
            var socket: BluetoothSocket?
            // Listen to the server socket if we're not connected
            while (mState != STATE_CONNECTED) {
                socket = try { // This is a blocking call and will only return on a
// successful connection or an exception
                    mmServerSocket!!.accept()
                } catch (e: IOException) {
                    Log.e(TAG, "Socket Type: " + mSocketType + "accept() failed", e)
                    break
                }
                // If a connection was accepted
                if (socket != null) {
                    synchronized(this@BluetoothSerialService) {
                        when (mState) {
                            STATE_LISTEN, STATE_CONNECTING ->  // Situation normal. Start the connected thread.
                                connected(socket, socket.remoteDevice,
                                        mSocketType)
                            STATE_NONE, STATE_CONNECTED ->  // Either not ready or already connected. Terminate new socket.
                                try {
                                    socket.close()
                                } catch (e: IOException) {
                                    Log.e(TAG, "Could not close unwanted socket", e)
                                }
                            else ->
                                Log.v(TAG, "State is: $mState")
                        }
                    }
                }
            }
            if (D) Log.i(TAG, "END mAcceptThread, socket Type: $mSocketType")
        }

        fun cancel() {
            if (D) Log.d(TAG, "Socket Type" + mSocketType + "cancel " + this)
            try {
                mmServerSocket!!.close()
            } catch (e: IOException) {
                Log.e(TAG, "Socket Type" + mSocketType + "close() of server failed", e)
            }
        }

        init {
            var tmp: BluetoothServerSocket? = null
            mSocketType = if (secure) "Secure" else "Insecure"
            // Create a new listening server socket
            try {
                tmp = mAdapter.listenUsingInsecureRfcommWithServiceRecord(NAME_INSECURE, MY_UUID_INSECURE)
            } catch (e: IOException) {
                Log.e(TAG, "Socket Type: " + mSocketType + "listen() failed", e)
            }
            mmServerSocket = tmp
        }
    }

    /**
     * This thread runs while attempting to make an outgoing connection
     * with a device. It runs straight through; the connection either
     * succeeds or fails.
     */
    private inner class ConnectThread(private val mmDevice: BluetoothDevice) : Thread() {
        private /*final*/  var mmSocket: BluetoothSocket?
        private val mSocketType: String
        override fun run() {
            Log.i(TAG, "BEGIN mConnectThread SocketType:$mSocketType")
            name = "ConnectThread$mSocketType"
            // Always cancel discovery because it will slow down a connection
            mAdapter.cancelDiscovery()
            // Make a connection to the BluetoothSocket
            try { // This is a blocking call and will only return on a successful connection or an exception
                Log.i(TAG, "Connecting to socket...")
                mmSocket!!.connect()
                Log.i(TAG, "Connected")
            } catch (e: IOException) {
                Log.e(TAG, e.toString())
                // Some 4.1 devices have problems, try an alternative way to connect
// See https://github.com/don/BluetoothSerial/issues/89
                try {
                    Log.i(TAG, "Trying fallback...")
                    mmSocket = mmDevice.javaClass.getMethod("createInsecureRfcommSocket", *arrayOf<Class<*>?>(Int::class.javaPrimitiveType)).invoke(mmDevice, 1) as BluetoothSocket
                    mmSocket!!.connect()
                    Log.i(TAG, "Connected")
                } catch (e2: Exception) {
                    Log.e(TAG, "Couldn't establish a Bluetooth connection.")
                    try {
                        mmSocket!!.close()
                    } catch (e3: IOException) {
                        Log.e(TAG, "unable to close() $mSocketType socket during connection failure", e3)
                    }
                    connectionFailed()
                    return
                }
            }
            // Reset the ConnectThread because we're done
            synchronized(this@BluetoothSerialService) { mConnectThread = null }
            // Start the connected thread
            connected(mmSocket, mmDevice, mSocketType)
        }

        fun cancel() {
            try {
                mmSocket!!.close()
            } catch (e: IOException) {
                Log.e(TAG, "close() of connect $mSocketType socket failed", e)
            }
        }

        init {
            var tmp: BluetoothSocket? = null
            mSocketType = "Insecure"
            // Get a BluetoothSocket for a connection with the given BluetoothDevice
            try {
                tmp = mmDevice.createInsecureRfcommSocketToServiceRecord(MY_UUID_INSECURE)
            } catch (e: IOException) {
                Log.e(TAG, "Socket Type: " + mSocketType + "create() failed", e)
            }
            mmSocket = tmp
        }
    }

    /**
     * This thread runs during a connection with a remote device.
     * It handles all incoming and outgoing transmissions.
     */
    private inner class ConnectedThread(socket: BluetoothSocket?, socketType: String) : Thread() {
        private val mmSocket: BluetoothSocket?
        private val mmInStream: InputStream?
        private val mmOutStream: OutputStream?
        override fun run() {
            Log.i(TAG, "BEGIN mConnectedThread")
            val buffer = ByteArray(1024)
            var bytes: Int
            // Keep listening to the InputStream while connected
            while (true) {
                try { // Read from the InputStream
                    bytes = mmInStream!!.read(buffer)
                    val data = String(buffer, 0, bytes)
                    // Send the new data String to the UI Activity
                    mHandler.obtainMessage(BluetoothSerial.MESSAGE_READ, data).sendToTarget()
                    // Send the raw bytestream to the UI Activity.
// We make a copy because the full array can have extra data at the end
// when / if we read less than its size.
                    if (bytes > 0) {
                        val rawdata = Arrays.copyOf(buffer, bytes)
                        mHandler.obtainMessage(BluetoothSerial.MESSAGE_READ_RAW, rawdata).sendToTarget()
                    }
                } catch (e: IOException) {
                    Log.e(TAG, "disconnected", e)
                    connectionLost()
                    // Start the service over to restart listening mode
                    this@BluetoothSerialService.start()
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
                // Share the sent message back to the UI Activity
                mHandler.obtainMessage(BluetoothSerial.MESSAGE_WRITE, -1, -1, buffer).sendToTarget()
            } catch (e: IOException) {
                Log.e(TAG, "Exception during write", e)
            }
        }

        fun cancel() {
            try {
                mmSocket!!.close()
            } catch (e: IOException) {
                Log.e(TAG, "close() of connect socket failed", e)
            }
        }

        init {
            Log.d(TAG, "create ConnectedThread: $socketType")
            mmSocket = socket
            var tmpIn: InputStream? = null
            var tmpOut: OutputStream? = null
            // Get the BluetoothSocket input and output streams
            try {
                tmpIn = socket!!.inputStream
                tmpOut = socket.outputStream
            } catch (e: IOException) {
                Log.e(TAG, "temp sockets not created", e)
            }
            mmInStream = tmpIn
            mmOutStream = tmpOut
        }
    }

    companion object {
        // Debugging
        private const val TAG = "BluetoothSerialService"
        private const val D = true
        // Name for the SDP record when creating server socket
        private const val NAME_INSECURE = "PhoneGapBluetoothSerialServiceInSecure"
        // Unique UUID for this application
        private val MY_UUID_INSECURE = UUID.fromString("77718142-B389-4772-93BD-52BDBB2C0777")
        // Constants that indicate the current connection state
        const val STATE_NONE = 0 // we're doing nothing
        const val STATE_LISTEN = 1 // now listening for incoming connections
        const val STATE_CONNECTING = 2 // now initiating an outgoing connection
        const val STATE_CONNECTED = 3 // now connected to a remote device
    }

    /**
     * Constructor. Prepares a new BluetoothSerial session.
     * @param handler  A Handler to send messages back to the UI Activity
     */
    init {
        mAdapter = BluetoothAdapter.getDefaultAdapter()
        mState = STATE_NONE
        mHandler = handler
    }
}