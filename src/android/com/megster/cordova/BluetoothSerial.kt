package com.megster.cordova

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Message
import android.provider.Settings
import android.util.Log
import org.apache.cordova.CallbackContext
import org.apache.cordova.CordovaArgs
import org.apache.cordova.CordovaPlugin
import org.apache.cordova.LOG
import org.apache.cordova.PluginResult
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

/**
 * PhoneGap Plugin for Serial Communication over Bluetooth
 */
class BluetoothSerial : CordovaPlugin() {
    // callbacks
    private var connectCallback: CallbackContext? = null
    private var dataAvailableCallback: CallbackContext? = null
    private var rawDataAvailableCallback: CallbackContext? = null
    private var enableBluetoothCallback: CallbackContext? = null
    private var deviceDiscoveredCallback: CallbackContext? = null
    private var bluetoothAdapter: BluetoothAdapter? = null
    // The Handler that gets information back from the BluetoothSerialService
// Original code used handler for the because it was talking to the UI.
// Consider replacing with normal callbacks
    private val mHandler: Handler = object : Handler() {
        override fun handleMessage(msg: Message) {
            when (msg.what) {
                MESSAGE_READ -> {
                    buffer.append(msg.obj as String)
                    if (dataAvailableCallback != null) {
                        sendDataToSubscriber()
                    }
                }
                MESSAGE_READ_RAW -> if (rawDataAvailableCallback != null) {
                    val bytes = msg.obj as ByteArray
                    sendRawDataToSubscriber(bytes)
                }
                MESSAGE_STATE_CHANGE -> {
                    if (D) Log.i(TAG, "MESSAGE_STATE_CHANGE: " + msg.arg1)
                    when (msg.arg1) {
                        BluetoothSerialService.STATE_CONNECTED -> {
                            Log.i(TAG, "BluetoothSerialService.STATE_CONNECTED")
                            notifyConnectionSuccess()
                        }
                        BluetoothSerialService.STATE_CONNECTING -> Log.i(TAG, "BluetoothSerialService.STATE_CONNECTING")
                        BluetoothSerialService.STATE_LISTEN -> Log.i(TAG, "BluetoothSerialService.STATE_LISTEN")
                        BluetoothSerialService.STATE_NONE -> Log.i(TAG, "BluetoothSerialService.STATE_NONE")
                    }
                }
                MESSAGE_WRITE -> {
                }
                MESSAGE_DEVICE_NAME -> Log.i(TAG, msg.data.getString(DEVICE_NAME))
                MESSAGE_TOAST -> {
                    val message = msg.data.getString(TOAST)
                    notifyConnectionLost(message)
                }
            }
        }
    }

    private val bluetoothSerialService: BluetoothSerialService = BluetoothSerialService(mHandler)
    var buffer = StringBuffer()
    private var delimiter: String? = null
    private var permissionCallback: CallbackContext? = null
    @Throws(JSONException::class)
    override fun execute(action: String, args: CordovaArgs, callbackContext: CallbackContext): Boolean {
        LOG.d(TAG, "action = $action")
        if (bluetoothAdapter == null) {
            bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        }
        var validAction = true
        if (action == LIST) {
            listBondedDevices(callbackContext)
        } else if (action == CONNECT) {
            val secure = true
            connect(args, secure, callbackContext)
        } else if (action == CONNECT_INSECURE) { // see Android docs about Insecure RFCOMM http://goo.gl/1mFjZY
            val secure = false
            connect(args, secure, callbackContext)
        } else if (action == DISCONNECT) {
            connectCallback = null
            bluetoothSerialService.stop()
            callbackContext.success()
        } else if (action == WRITE) {
            val data: ByteArray = args.getArrayBuffer(0)
            bluetoothSerialService.write(data)
            callbackContext.success()
        } else if (action == AVAILABLE) {
            callbackContext.success(available())
        } else if (action == READ) {
            callbackContext.success(read())
        } else if (action == READ_UNTIL) {
            val interesting: String = args.getString(0)
            callbackContext.success(readUntil(interesting))
        } else if (action == SUBSCRIBE) {
            delimiter = args.getString(0)
            dataAvailableCallback = callbackContext
            //            Intent testIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE);
//            cordova.getActivity().startActivity(testIntent);
            bluetoothSerialService.start()
            val result = PluginResult(PluginResult.Status.NO_RESULT)
            result.setKeepCallback(true)
            callbackContext.sendPluginResult(result)
        } else if (action == UNSUBSCRIBE) {
            delimiter = null
            // send no result, so Cordova won't hold onto the data available callback anymore
            val result = PluginResult(PluginResult.Status.NO_RESULT)
            dataAvailableCallback?.sendPluginResult(result)
            dataAvailableCallback = null
            callbackContext.success()
        } else if (action == SUBSCRIBE_RAW) {
            rawDataAvailableCallback = callbackContext
            val result = PluginResult(PluginResult.Status.NO_RESULT)
            result.setKeepCallback(true)
            callbackContext.sendPluginResult(result)
        } else if (action == UNSUBSCRIBE_RAW) {
            rawDataAvailableCallback = null
            callbackContext.success()
        } else if (action == IS_ENABLED) {
            if (bluetoothAdapter!!.isEnabled) {
                callbackContext.success()
            } else {
                callbackContext.error("Bluetooth is disabled.")
            }
        } else if (action == IS_CONNECTED) {
            if (bluetoothSerialService.state === BluetoothSerialService.STATE_CONNECTED) {
                callbackContext.success()
            } else {
                callbackContext.error("Not connected.")
            }
        } else if (action == CLEAR) {
            buffer.setLength(0)
            callbackContext.success()
        } else if (action == SETTINGS) {
            val intent = Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
            cordova.getActivity().startActivity(intent)
            callbackContext.success()
        } else if (action == ENABLE) {
            enableBluetoothCallback = callbackContext
            val activity: Activity = cordova.getActivity()
            activity.registerReceiver(bluetoothStatusReceiver, bluetoothIntentFilter)
            bluetoothAdapter!!.enable()
        } else if (action == DISABLE) {
            bluetoothAdapter!!.disable()
            callbackContext.success()
        } else if (action == DISCOVER_UNPAIRED) {
            if (cordova.hasPermission(ACCESS_COARSE_LOCATION)) {
                discoverUnpairedDevices(callbackContext)
            } else {
                permissionCallback = callbackContext
                cordova.requestPermission(this, CHECK_PERMISSIONS_REQ_CODE, ACCESS_COARSE_LOCATION)
            }
        } else if (action == SET_DEVICE_DISCOVERED_LISTENER) {
            deviceDiscoveredCallback = callbackContext
        } else if (action == CLEAR_DEVICE_DISCOVERED_LISTENER) {
            deviceDiscoveredCallback = null
        } else if (action == SET_NAME) {
            val newName: String = args.getString(0)
            bluetoothAdapter!!.name = newName
            callbackContext.success()
        } else if (action == SET_DISCOVERABLE) {
            val discoverableDuration: Int = args.getInt(0)
            val discoverIntent = Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE)
            discoverIntent.putExtra(BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, discoverableDuration)
            cordova.getActivity().startActivity(discoverIntent)
        } else {
            validAction = false
        }
        return validAction
    }

    override fun onDestroy() {
        super.onDestroy()
        if (bluetoothSerialService != null) {
            bluetoothSerialService.stop()
        }
    }

    @Throws(JSONException::class)
    private fun listBondedDevices(callbackContext: CallbackContext) {
        val deviceList = JSONArray()
        val bondedDevices = bluetoothAdapter!!.bondedDevices
        for (device in bondedDevices) {
            deviceList.put(deviceToJSON(device))
        }
        callbackContext.success(deviceList)
    }

    @Throws(JSONException::class)
    private fun discoverUnpairedDevices(callbackContext: CallbackContext?) {
        val ddc: CallbackContext? = deviceDiscoveredCallback
        val discoverReceiver: BroadcastReceiver = object : BroadcastReceiver() {
            private val unpairedDevices = JSONArray()
            override fun onReceive(context: Context, intent: Intent) {
                val action = intent.action
                if (BluetoothDevice.ACTION_FOUND == action) {
                    val device = intent.getParcelableExtra<BluetoothDevice>(BluetoothDevice.EXTRA_DEVICE)
                    try {
                        val o = deviceToJSON(device)
                        unpairedDevices.put(o)
                        if (ddc != null) {
                            val res = PluginResult(PluginResult.Status.OK, o)
                            res.setKeepCallback(true)
                            ddc.sendPluginResult(res)
                        }
                    } catch (e: JSONException) { // This shouldn't happen, log and ignore
                        Log.e(TAG, "Problem converting device to JSON", e)
                    }
                } else if (BluetoothAdapter.ACTION_DISCOVERY_FINISHED == action) {
                    callbackContext?.success(unpairedDevices)
                    cordova.getActivity().unregisterReceiver(this)
                }
            }
        }
        val activity: Activity = cordova.getActivity()
        activity.registerReceiver(discoverReceiver, IntentFilter(BluetoothDevice.ACTION_FOUND))
        activity.registerReceiver(discoverReceiver, IntentFilter(BluetoothAdapter.ACTION_DISCOVERY_FINISHED))
        bluetoothAdapter!!.startDiscovery()
    }

    @Throws(JSONException::class)
    private fun deviceToJSON(device: BluetoothDevice): JSONObject {
        val json = JSONObject()
        json.put("name", device.name)
        json.put("address", device.address)
        json.put("id", device.address)
        if (device.bluetoothClass != null) {
            json.put("class", device.bluetoothClass.deviceClass)
        }
        return json
    }

    @Throws(JSONException::class)
    private fun connect(args: CordovaArgs, secure: Boolean, callbackContext: CallbackContext) {
        val macAddress: String = args.getString(0)
        val device = bluetoothAdapter!!.getRemoteDevice(macAddress)
        if (device != null) {
            connectCallback = callbackContext
            bluetoothSerialService.connect(device, secure)
            buffer.setLength(0)
            val result = PluginResult(PluginResult.Status.NO_RESULT)
            result.setKeepCallback(true)
            callbackContext.sendPluginResult(result)
        } else {
            callbackContext.error("Could not connect to $macAddress")
        }
    }


    private fun notifyConnectionLost(error: String?) {
        if (connectCallback != null) {
            connectCallback?.error(error)
            connectCallback = null
        }
    }

    private fun notifyConnectionSuccess() {
        if (connectCallback != null) {
            val result = PluginResult(PluginResult.Status.OK)
            result.setKeepCallback(true)
            connectCallback?.sendPluginResult(result)
        }
    }

    private fun sendRawDataToSubscriber(data: ByteArray?) {
        if (data != null && data.size > 0) {
            val result = PluginResult(PluginResult.Status.OK, data)
            result.setKeepCallback(true)
            rawDataAvailableCallback?.sendPluginResult(result)
        }
    }

    private fun sendDataToSubscriber() {
        val data = readUntil(delimiter)
        if (data != null && data.length > 0) {
            val result = PluginResult(PluginResult.Status.OK, data)
            result.setKeepCallback(true)
            dataAvailableCallback?.sendPluginResult(result)
            sendDataToSubscriber()
        }
    }

    private fun available(): Int {
        return buffer.length
    }

    private fun read(): String {
        val length = buffer.length
        val data = buffer.substring(0, length)
        buffer.delete(0, length)
        return data
    }

    private fun readUntil(c: String?): String {
        var data = ""
        val index = buffer.indexOf(c!!, 0)
        if (index > -1) {
            data = buffer.substring(0, index + c.length)
            buffer.delete(0, index + c.length)
        }
        return data
    }

    @Throws(JSONException::class)
    override fun onRequestPermissionResult(requestCode: Int, permissions: Array<String?>?,
                                           grantResults: IntArray) {
        for (result in grantResults) {
            if (result == PackageManager.PERMISSION_DENIED) {
                LOG.d(TAG, "User *rejected* location permission")
                permissionCallback?.sendPluginResult(PluginResult(
                        PluginResult.Status.ERROR,
                        "Location permission is required to discover unpaired devices.")
                )
                return
            }
        }
        when (requestCode) {
            CHECK_PERMISSIONS_REQ_CODE -> {
                LOG.d(TAG, "User granted location permission")
                discoverUnpairedDevices(permissionCallback)
            }
        }
    }

    private val bluetoothStatusReceiver: BroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val action = intent.action
            if (action == BluetoothAdapter.ACTION_STATE_CHANGED) {
                val state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE,
                        BluetoothAdapter.ERROR)
                when (state) {
                    BluetoothAdapter.STATE_OFF -> {
                    }
                    BluetoothAdapter.STATE_TURNING_OFF -> {
                    }
                    BluetoothAdapter.STATE_ON -> {
                        // Bluetooth has been on
                        Log.d(TAG, "User enabled Bluetooth")
                        if (enableBluetoothCallback != null) {
                            enableBluetoothCallback?.success()
                        }
                        cleanUpEnableBluetooth()
                    }
                    BluetoothAdapter.STATE_TURNING_ON -> {
                    }
                    else -> {
                        Log.d(TAG, "Error enabling bluetooth")
                        if (enableBluetoothCallback != null) {
                            enableBluetoothCallback?.error("Error enabling bluetooth")
                        }
                        cleanUpEnableBluetooth()
                    }
                }
            }
        }
    }

    private fun cleanUpEnableBluetooth() {
        enableBluetoothCallback = null
        val activity: Activity = cordova.getActivity()
        activity.unregisterReceiver(bluetoothStatusReceiver)
    }

    var bluetoothIntentFilter = IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED)

    companion object {
        // actions
        private const val LIST = "list"
        private const val CONNECT = "connect"
        private const val CONNECT_INSECURE = "connectInsecure"
        private const val DISCONNECT = "disconnect"
        private const val WRITE = "write"
        private const val AVAILABLE = "available"
        private const val READ = "read"
        private const val READ_UNTIL = "readUntil"
        private const val SUBSCRIBE = "subscribe"
        private const val UNSUBSCRIBE = "unsubscribe"
        private const val SUBSCRIBE_RAW = "subscribeRaw"
        private const val UNSUBSCRIBE_RAW = "unsubscribeRaw"
        private const val IS_ENABLED = "isEnabled"
        private const val IS_CONNECTED = "isConnected"
        private const val CLEAR = "clear"
        private const val SETTINGS = "showBluetoothSettings"
        private const val ENABLE = "enable"
        private const val DISABLE = "disable"
        private const val DISCOVER_UNPAIRED = "discoverUnpaired"
        private const val SET_DEVICE_DISCOVERED_LISTENER = "setDeviceDiscoveredListener"
        private const val CLEAR_DEVICE_DISCOVERED_LISTENER = "clearDeviceDiscoveredListener"
        private const val SET_NAME = "setName"
        private const val SET_DISCOVERABLE = "setDiscoverable"
        // Debugging
        private const val TAG = "BluetoothSerial"
        private const val D = true
        // Message types sent from the BluetoothSerialService Handler
        const val MESSAGE_STATE_CHANGE = 1
        const val MESSAGE_READ = 2
        const val MESSAGE_WRITE = 3
        const val MESSAGE_DEVICE_NAME = 4
        const val MESSAGE_TOAST = 5
        const val MESSAGE_READ_RAW = 6
        // Key names received from the BluetoothChatService Handler
        const val DEVICE_NAME = "device_name"
        const val TOAST = "toast"
        private const val REQUEST_ENABLE_BLUETOOTH = 1
        // Android 23 requires user to explicitly grant permission for location to discover unpaired
        private const val ACCESS_COARSE_LOCATION = Manifest.permission.ACCESS_COARSE_LOCATION
        private const val CHECK_PERMISSIONS_REQ_CODE = 2
    }
}