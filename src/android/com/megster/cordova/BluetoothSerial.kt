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
            CONNECT -> {
                enableBluetoothIfNecessary()
                connect(args, callbackContext)
            }
            DISCONNECT -> {
                try {
                    BluetoothSerialService.stop()
                    callbackContext.success()
                } catch (e: Exception) {
                    callbackContext.error(e.toString())
                }
            }
            SEND -> {
                try {
                    val data: ByteArray = args.getArrayBuffer(0)
                    BluetoothSerialService.write(data)
                    callbackContext.success()
                } catch (e: Exception) {
                    callbackContext.error(e.toString())
                }
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
                    override fun connected() {
                        notifyConnectionSuccess()
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

    private fun listen(callbackContext: CallbackContext) {
        if (BluetoothSerialService.state == STATE_CONNECTED) {
            callbackContext.error("Already connected")
        } else {
            enableBluetoothIfNecessary()
            try {
                BluetoothSerialService.start()
                callbackContext.success()
            } catch (e: Exception) {
                callbackContext.error(e.toString())
            }
        }
    }

    private fun enableBluetoothIfNecessary() {
        if (!bluetoothAdapter.isEnabled) {
            bluetoothAdapter.enable()
        }
    }

    private fun keepCallbackAndSendNoResult(callbackContext: CallbackContext) {
        val result = PluginResult(PluginResult.Status.NO_RESULT)
        result.keepCallback = true
        callbackContext.sendPluginResult(result)
    }

    override fun onDestroy() {
        super.onDestroy()
        BluetoothSerialService.stop()
    }

    @Throws(JSONException::class)
    private fun connect(args: CordovaArgs, callbackContext: CallbackContext) {
        val macAddress: String = args.getString(0)
        val device = bluetoothAdapter?.getRemoteDevice(macAddress)
        if (device != null) {
            BluetoothSerialService.connect(device)
            callbackContext.success()
        } else {
            callbackContext.error("Could not connect to $macAddress")
        }
    }

    private fun notifyConnectionLost() {
        keepCallbackAndSendResult()
    }

    private fun notifyConnectionSuccess() {
        keepCallbackAndSendResult()
    }

    private fun keepCallbackAndSendResult() {
        val result = PluginResult(PluginResult.Status.OK)
        result.keepCallback = true
        connectCallback?.sendPluginResult(result)
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
                val serviceField: Field? = bluetoothAdapter?.javaClass?.getDeclaredField("mService")
                serviceField?.isAccessible = true
                val btManagerService: Any? = serviceField?.get(bluetoothAdapter)
                btManagerService?.run {
                    bluetoothMacAddress =
                            javaClass.getMethod("getAddress").invoke(btManagerService) as String
                }
            } catch (e: Exception) {
                Log.e(TAG, "Unable to retrieve Bluetooth MAC Address: $e")
            }
        } else {
            bluetoothMacAddress = bluetoothAdapter?.address
        }
        return bluetoothMacAddress
    }

    companion object {
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
