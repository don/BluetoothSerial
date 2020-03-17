package com.megster.cordova

import android.bluetooth.BluetoothAdapter
import android.os.Build
import android.util.Log
import com.megster.cordova.BluetoothSerialService.ClosedCallback
import com.megster.cordova.BluetoothSerialService.ConnectedCallback
import com.megster.cordova.BluetoothSerialService.DataCallback
import com.megster.cordova.BluetoothSerialService.STATE_CONNECTED
import org.apache.cordova.*
import org.json.JSONException
import java.lang.Exception
import java.lang.reflect.Field


/**
 * PhoneGap Plugin for Serial Communication over Bluetooth
 */
class BluetoothSerial : CordovaPlugin() {
    private var connectCallback: CallbackContext? = null
    private var closeCallback: CallbackContext? = null
    private var dataAvailableCallback: CallbackContext? = null
    private val bluetoothAdapter: BluetoothAdapter = BluetoothAdapter.getDefaultAdapter()

    @Throws(JSONException::class)
    override fun execute(action: String, args: CordovaArgs, callbackContext: CallbackContext): Boolean {
        LOG.d(TAG, "action = $action")
        var validAction = true

        when (action) {
            IS_ENABLED -> {
                isEnabled(callbackContext)
            }
            ENABLE -> {
                enable(callbackContext)
            }
            CONNECT -> {
                connect(args, callbackContext)
            }
            DISCONNECT -> {
                disconnect(callbackContext)
            }
            SEND -> {
                send(args, callbackContext)
            }
            LISTEN -> {
                listen(callbackContext)
            }
            GET_ADDRESS -> {
                val macAddress = getBluetoothMacAddress()

                macAddress?.run {
                    callbackContext.success(this)
                } ?: callbackContext.error("Unable to determine Bluetooth MAC address")
            }
            REGISTER_DATA_CALLBACK -> {
                dataAvailableCallback = callbackContext
                BluetoothSerialService.registerDataCallback(object : DataCallback {
                    override fun onData(data: ByteArray) {
                        sendRawDataToSubscriber(data)
                    }
                })
                keepCallbackAndSendNoResult(callbackContext)
            }
            REGISTER_CONNECT_CALLBACK -> {
                connectCallback = callbackContext
                BluetoothSerialService.registerConnectedCallback(object : ConnectedCallback {
                    override fun connected(remoteDeviceMacAddress: String?) {
                        notifyConnectionSuccess(remoteDeviceMacAddress)
                    }
                })
                keepCallbackAndSendNoResult(callbackContext)
            }
            REGISTER_CLOSE_CALLBACK -> {
                closeCallback = callbackContext
                BluetoothSerialService.registerClosedCallback(object : ClosedCallback {
                    override fun closed() {
                        notifyConnectionLost()
                    }
                })
                keepCallbackAndSendNoResult(callbackContext)
            }
            else -> {
                validAction = false
            }
        }

        return validAction
    }

    override fun onDestroy() {
        super.onDestroy()
        BluetoothSerialService.stop()
    }

    private fun isEnabled(callbackContext: CallbackContext) {
        try {
            callbackContext.success(bluetoothAdapter.isEnabled().toString())
        } catch (e: Exception) {
            Log.e(TAG, "Unable to check isEnabled: $e")
            callbackContext.error(e.toString())
        }
    }

    private fun enable(callbackContext: CallbackContext) {
        try {
            if (bluetoothAdapter.isEnabled()) {
                callbackContext.success(true.toString())
                return
            }

            // returns a boolean indicating whether it was able
            // to begin enabling the adapter, which is an
            // asynchronous process.
            // https://github.com/aosp-mirror/platform_frameworks_base/blob/nougat-release/core/java/android/bluetooth/BluetoothAdapter.java#L899
            callbackContext.success(bluetoothAdapter.enable().toString())
        } catch (e: Exception) {
            Log.e(TAG, "Unable to enable bluetooth: $e")
            callbackContext.error(e.toString())
        }
    }

    private fun listen(callbackContext: CallbackContext) {
        try {
            BluetoothSerialService.start()
            callbackContext.success()
        } catch (e: Exception) {
            Log.e(TAG, "Unable to start listening: $e")
            callbackContext.error(e.toString())
        }
    }

    private fun connect(args: CordovaArgs, callbackContext: CallbackContext) {
        try {
            val macAddress: String = args.getString(0)
            val device = bluetoothAdapter.getRemoteDevice(macAddress)
            if (device != null) {
                BluetoothSerialService.connect(device)
                callbackContext.success()
            } else {
                Log.d(TAG, "Could not connect to $macAddress")
                callbackContext.error("Could not connect to $macAddress")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Unable to start connecting: $e")
            callbackContext.error(e.toString())
        }
    }

    private fun send(args: CordovaArgs, callbackContext: CallbackContext) {
        if (BluetoothSerialService.state != STATE_CONNECTED) {
            Log.d(TAG, "Attempted send but not connected")
            callbackContext.error("Not connected")
        } else {
            try {
                val data: ByteArray = args.getArrayBuffer(0)
                BluetoothSerialService.write(data)
                callbackContext.success()
            } catch (e: Exception) {
                Log.e(TAG, "Unable to send: $e")
                callbackContext.error(e.toString())
            }
        }
    }

    private fun disconnect(callbackContext: CallbackContext) {
        try {
            BluetoothSerialService.stop()
            callbackContext.success()
        } catch (e: Exception) {
            Log.e(TAG, "Unable to disconnect: $e")
            callbackContext.error(e.toString())
        }
    }

    private fun notifyConnectionLost() {
        val result = PluginResult(PluginResult.Status.OK)
        result.keepCallback = true
        closeCallback?.sendPluginResult(result)
    }

    private fun notifyConnectionSuccess(remoteDeviceMacAddress: String?) {
        val result = PluginResult(PluginResult.Status.OK, remoteDeviceMacAddress)
        result.keepCallback = true
        connectCallback?.sendPluginResult(result)
    }

    private fun keepCallbackAndSendNoResult(callbackContext: CallbackContext) {
        val result = PluginResult(PluginResult.Status.NO_RESULT)
        result.keepCallback = true
        callbackContext.sendPluginResult(result)
    }

    private fun sendRawDataToSubscriber(data: ByteArray?) {
        if (data != null && data.isNotEmpty()) {
            val result = PluginResult(PluginResult.Status.OK, data.toString(Charsets.UTF_8))
            result.keepCallback = true
            dataAvailableCallback?.sendPluginResult(result)
        }
    }

    private fun getBluetoothMacAddress(): String? {
        var bluetoothMacAddress: String? = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val serviceField: Field = bluetoothAdapter.javaClass.getDeclaredField("mService")
                serviceField.isAccessible = true
                val btManagerService: Any = serviceField.get(bluetoothAdapter)
                btManagerService.run {
                    bluetoothMacAddress =
                            javaClass.getMethod("getAddress").invoke(btManagerService) as String
                }
            } catch (e: Exception) {
                Log.e(TAG, "Unable to retrieve Bluetooth MAC Address: $e")
            }
        } else {
            bluetoothMacAddress = bluetoothAdapter.address
        }
        return bluetoothMacAddress
    }

    companion object {
        private const val IS_ENABLED = "isEnabled"
        private const val ENABLE = "enable"
        private const val CONNECT = "connect"
        private const val LISTEN = "listen"
        private const val DISCONNECT = "disconnect"
        private const val SEND = "send"
        private const val GET_ADDRESS = "getAddress"
        private const val REGISTER_DATA_CALLBACK = "registerDataCallback"
        private const val REGISTER_CONNECT_CALLBACK = "registerConnectCallback"
        private const val REGISTER_CLOSE_CALLBACK = "registerCloseCallback"

        // Debugging
        private const val TAG = "BluetoothSerial"
    }
}
