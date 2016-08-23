package nz.co.soltius.cordova;

import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Handler;
import android.os.Message;
import android.provider.Settings;
import android.util.Base64;
import android.util.Log;
import org.apache.cordova.CordovaArgs;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.PluginResult;
import org.apache.cordova.LOG;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.HashMap;

/**
 * PhoneGap Plugin for Serial Communication over Bluetooth
 */
public class BluetoothClassicSerial extends CordovaPlugin {

    // actions
    private static final String LIST = "list";
    private static final String CONNECT = "connect";
    private static final String CONNECT_INSECURE = "connectInsecure";
    private static final String DISCONNECT = "disconnect";
    private static final String WRITE = "write";
    private static final String AVAILABLE = "available";
    private static final String READ = "read";
    private static final String READ_UNTIL = "readUntil";
    private static final String SUBSCRIBE = "subscribe";
    private static final String UNSUBSCRIBE = "unsubscribe";
    private static final String SUBSCRIBE_RAW = "subscribeRaw";
    private static final String UNSUBSCRIBE_RAW = "unsubscribeRaw";
    private static final String IS_ENABLED = "isEnabled";
    private static final String IS_CONNECTED = "isConnected";
    private static final String CLEAR = "clear";
    private static final String SETTINGS = "showBluetoothSettings";
    private static final String ENABLE = "enable";
    private static final String DISCOVER_UNPAIRED = "discoverUnpaired";
    private static final String SET_DEVICE_DISCOVERED_LISTENER = "setDeviceDiscoveredListener";
    private static final String CLEAR_DEVICE_DISCOVERED_LISTENER = "clearDeviceDiscoveredListener";

    // callbacks
    private CallbackContext connectCallback;
    // private CallbackContext dataAvailableCallback;
    // private CallbackContext rawDataAvailableCallback;
    private CallbackContext enableBluetoothCallback;
    private CallbackContext deviceDiscoveredCallback;

    private BluetoothAdapter bluetoothAdapter;
    // private BluetoothClassicSerialService bluetoothClassicSerialService;

    // Debugging
    private static final String TAG = "BluetoothClassicSerial";
    private static final boolean D = true;

    // Message types sent from the BluetoothClassicSerialService Handler
    public static final int MESSAGE_STATE_CHANGE = 1;
    public static final int MESSAGE_READ = 2;
    public static final int MESSAGE_WRITE = 3;
    public static final int MESSAGE_DEVICE_NAME = 4;
    public static final int MESSAGE_TOAST = 5;
    public static final int MESSAGE_READ_RAW = 6;

    // Key names received from the BluetoothChatService Handler
    public static final String DEVICE_NAME = "device_name";
    public static final String TOAST = "toast";

    //StringBuffer buffer = new StringBuffer();
    //private String delimiter;
    private static final int REQUEST_ENABLE_BLUETOOTH = 1;

    //Container for interfaces (Index = interfaceID)
    private HashMap<String, InterfaceContext> connections = new HashMap<String, InterfaceContext>();
    private String mDeviceId;
    private boolean mConnected = false;

    @Override
    public boolean execute(String action, CordovaArgs args, CallbackContext callbackContext) throws JSONException {

        LOG.d(TAG, "action = " + action);

        if (bluetoothAdapter == null) {
            bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        }

//        if (bluetoothClassicSerialService == null) {
//            bluetoothClassicSerialService = new BluetoothClassicSerialService(mHandler);
//        }

        boolean validAction = true;

        if (action.equals(LIST)) {

            listBondedDevices(callbackContext);

        } else if (action.equals(CONNECT)) {

            boolean secure = true;
            connect(args, secure, callbackContext);

        } else if (action.equals(CONNECT_INSECURE)) {

            // see Android docs about Insecure RFCOMM http://goo.gl/1mFjZY
            boolean secure = false;
            connect(args, secure, callbackContext);

        } else if (action.equals(DISCONNECT)) {

            disconnect(callbackContext);

//            connectCallback = null;
//            bluetoothClassicSerialService.stop();
//            callbackContext.success();

        } else {
            if (action.equals(WRITE)) {

                String interfaceId = args.getString(0);
                byte[] data = args.getArrayBuffer(1);

                InterfaceContext ic;

                ic = getInterfaceContext(interfaceId);

                if (ic != null) {
                    ic.bluetoothClassicSerialService.write(data);
                    callbackContext.success();
                } else {
                    callbackContext.error("No Interface");
                }

            } else if (action.equals(AVAILABLE)) {

                String interfaceId = args.getString(0);
                InterfaceContext ic = getInterfaceContext(interfaceId);
                int available = 0;

                if (ic != null) {
                    available = ic.available();
                }

                callbackContext.success(available);

            } else if (action.equals(READ)) {

                String interfaceId = args.getString(0);
                String delim = args.getString(1);
                InterfaceContext ic = getInterfaceContext(interfaceId);
                String data = "";

                if (ic != null) {
                    data = ic.read();
                }
                callbackContext.success(data);

            } else if (action.equals(READ_UNTIL)) {

                String interfaceId = args.getString(0);
                String delim = args.getString(1);
                String readText = "";
                InterfaceContext ic;

                ic = getInterfaceContext(interfaceId);

                if (ic != null) {
                    readText = ic.readUntil(delim);
                }

                callbackContext.success(readText);

            } else if (action.equals(SUBSCRIBE)) {

                String interfaceId = args.getString(0);
                String delim = args.getString(1);

                setContextSubscribe(interfaceId, callbackContext, delim);

                //dataAvailableCallback = callbackContext;

                PluginResult result = new PluginResult(PluginResult.Status.NO_RESULT);
                result.setKeepCallback(true);
                callbackContext.sendPluginResult(result);

            } else if (action.equals(UNSUBSCRIBE)) {

                String interfaceId = args.getString(0);

                setContextSubscribe(interfaceId, null, null);

                // send no result, so Cordova won't hold onto the data available callback anymore
//                PluginResult result = new PluginResult(PluginResult.Status.NO_RESULT);
//                callbackContext.sendPluginResult(result);
                callbackContext.success();

            } else if (action.equals(SUBSCRIBE_RAW)) {

                String interfaceId = args.getString(0);

                // rawDataAvailableCallback = callbackContext;
                setContextRawSubscribe(interfaceId, callbackContext);

                PluginResult result = new PluginResult(PluginResult.Status.NO_RESULT);
                result.setKeepCallback(true);
                callbackContext.sendPluginResult(result);

            } else if (action.equals(UNSUBSCRIBE_RAW)) {

                String interfaceId = args.getString(0);
                setContextRawSubscribe(interfaceId, null);

                // rawDataAvailableCallback = null;

                callbackContext.success();

            } else if (action.equals(IS_ENABLED)) {

                if (bluetoothAdapter.isEnabled()) {
                    callbackContext.success();
                } else {
                    callbackContext.error("Bluetooth is disabled.");
                }

            } else if (action.equals(IS_CONNECTED)) {

                isConnected(callbackContext);

            } else if (action.equals(CLEAR)) {

                String interfaceId = args.getString(0);
                InterfaceContext ic;

                ic = getInterfaceContext(interfaceId);
                if (ic != null) {
                    ic.clearBuffer();
                }

                callbackContext.success();

            } else if (action.equals(SETTINGS)) {

                Intent intent = new Intent(Settings.ACTION_BLUETOOTH_SETTINGS);
                cordova.getActivity().startActivity(intent);
                callbackContext.success();

            } else if (action.equals(ENABLE)) {

                enableBluetoothCallback = callbackContext;
                Intent intent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
                cordova.startActivityForResult(this, intent, REQUEST_ENABLE_BLUETOOTH);

            } else if (action.equals(DISCOVER_UNPAIRED)) {

                discoverUnpairedDevices(callbackContext);

            } else if (action.equals(SET_DEVICE_DISCOVERED_LISTENER)) {

                this.deviceDiscoveredCallback = callbackContext;

            } else if (action.equals(CLEAR_DEVICE_DISCOVERED_LISTENER)) {

                this.deviceDiscoveredCallback = null;

            } else {
                validAction = false;

            }
        }

        return validAction;
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {

        if (requestCode == REQUEST_ENABLE_BLUETOOTH) {

            if (resultCode == Activity.RESULT_OK) {
                Log.d(TAG, "User enabled Bluetooth");
                if (enableBluetoothCallback != null) {
                    enableBluetoothCallback.success();
                }
            } else {
                Log.d(TAG, "User did *NOT* enable Bluetooth");
                if (enableBluetoothCallback != null) {
                    enableBluetoothCallback.error("User did not enable Bluetooth");
                }
            }

            enableBluetoothCallback = null;
        }
    }

    @Override
    public void onDestroy() {
        super.onDestroy();

        destroy();

//        if (bluetoothClassicSerialService != null) {
//            bluetoothClassicSerialService.stop();
//        }
    }

    // Object to Hold Connected Interfaces
    private class InterfaceContext{

        public BluetoothClassicSerialService bluetoothClassicSerialService;
        public StringBuffer buffer;
        public String delimiter;
        public String deviceId;
        public String interfaceId;
        public CallbackContext dataAvailableCallback;
        public CallbackContext rawDataAvailableCallback;

        // The Handler that gets information back from the BluetoothClassicSerialService
        // Original code used handler for the because it was talking to the UI.
        // Consider replacing with normal callbacks
        private final Handler mHandler;

        public InterfaceContext(String interfaceId) {

            this.interfaceId = interfaceId;

            mHandler = new Handler() {

                public void handleMessage(Message msg) {

                    byte[] byteArray;
                    String stringData;

                    switch (msg.what) {
                        case MESSAGE_READ:

                            stringData =  (String)msg.obj;

                            if (buffer == null) {
                                buffer = new StringBuffer();
                            }

                            buffer.append(stringData);

                            if (dataAvailableCallback != null) {
                                sendDataToSubscriber();
                            }

                            break;

                        case MESSAGE_READ_RAW:

                            if (rawDataAvailableCallback != null) {
                                byteArray = (byte[])msg.obj;
                                sendRawDataToSubscriber(byteArray);
                            }

                            break;

                        case MESSAGE_STATE_CHANGE:

                            if(D) Log.i(TAG, "MESSAGE_STATE_CHANGE: " + msg.arg1);
                            switch (msg.arg1) {
                                case BluetoothClassicSerialService.STATE_CONNECTED:
                                    Log.i(TAG, "BluetoothClassicSerialService.STATE_CONNECTED");
                                    if (mConnected == false) {
                                        mConnected = true;
                                        notifyConnectionSuccess();
                                    }
                                    break;
                                case BluetoothClassicSerialService.STATE_CONNECTING:
                                    Log.i(TAG, "BluetoothClassicSerialService.STATE_CONNECTING");
                                    break;
                                case BluetoothClassicSerialService.STATE_LISTEN:
                                    Log.i(TAG, "BluetoothClassicSerialService.STATE_LISTEN");
                                    break;
                                case BluetoothClassicSerialService.STATE_NONE:
                                    Log.i(TAG, "BluetoothClassicSerialService.STATE_NONE");
                                    break;
                            }
                            break;

                        case MESSAGE_WRITE:
                            //  byte[] writeBuf = (byte[]) msg.obj;
                            //  String writeMessage = new String(writeBuf);
                            //  Log.i(TAG, "Wrote: " + writeMessage);
                            break;

                        case MESSAGE_DEVICE_NAME:
                            Log.i(TAG, msg.getData().getString(DEVICE_NAME));
                            break;

                        case MESSAGE_TOAST:
                            String message = msg.getData().getString(TOAST);
                            if (mConnected == true) {
                                mConnected = false;
                                notifyConnectionLost(message);
                            }
                            break;
                    }
                }
            };

            this.bluetoothClassicSerialService = new BluetoothClassicSerialService(this.mHandler);
            this.buffer = new StringBuffer();
            this.interfaceId = interfaceId;
            this.dataAvailableCallback = null;
            this.delimiter = null;
        }

        public int available() {
            return buffer.length();
        }

        public void clearBuffer() {
            this.buffer.setLength(0);
        }

        public String read() {
            int length = buffer.length();
            String data = buffer.substring(0, length);
            buffer.delete(0, length);
            return data;
        }

        public String readUntil(String delimiter) {

            String data = null;
            int index;

            index = buffer.indexOf(delimiter,0);

            if (index > -1) {
                data = buffer.substring(0, index + delimiter.length());
                buffer.delete(0, index + delimiter.length());
            }

            return data;

        }


        private void sendDataToSubscriber() {

            String data = readUntil(delimiter);

            if (data != null && data.length() > 0) {
                PluginResult result = new PluginResult(PluginResult.Status.OK, data);
                result.setKeepCallback(true);
                dataAvailableCallback.sendPluginResult(result);
                sendDataToSubscriber();
            }

        }

        private void sendRawDataToSubscriber(byte[] byteData) {

            PluginResult result;

            if (byteData.length > 0) {

                result = new PluginResult(PluginResult.Status.OK, byteData);
                result.setKeepCallback(true);
                rawDataAvailableCallback.sendPluginResult(result);

            }
        }

    }  //End of Interface Context Class


    private void listBondedDevices(CallbackContext callbackContext) throws JSONException {
        JSONArray deviceList = new JSONArray();
        Set<BluetoothDevice> bondedDevices = bluetoothAdapter.getBondedDevices();

        for (BluetoothDevice device : bondedDevices) {
            deviceList.put(deviceToJSON(device));
        }
        callbackContext.success(deviceList);
    }

    private void discoverUnpairedDevices(final CallbackContext callbackContext) throws JSONException {

        final CallbackContext ddc = deviceDiscoveredCallback;

        final BroadcastReceiver discoverReceiver = new BroadcastReceiver() {

            private JSONArray unpairedDevices = new JSONArray();

            public void onReceive(Context context, Intent intent) {
                String action = intent.getAction();
                if (BluetoothDevice.ACTION_FOUND.equals(action)) {
                    BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
                    try {
                        JSONObject o = deviceToJSON(device);
                        unpairedDevices.put(o);
                        if (ddc != null) {
                            PluginResult res = new PluginResult(PluginResult.Status.OK, o);
                            res.setKeepCallback(true);
                            ddc.sendPluginResult(res);
                        }
                    } catch (JSONException e) {
                        // This shouldn't happen, log and ignore
                        Log.e(TAG, "Problem converting device to JSON", e);
                    }
                } else if (BluetoothAdapter.ACTION_DISCOVERY_FINISHED.equals(action)) {
                    callbackContext.success(unpairedDevices);
                    cordova.getActivity().unregisterReceiver(this);
                }
            }
        };

        Activity activity = cordova.getActivity();
        activity.registerReceiver(discoverReceiver, new IntentFilter(BluetoothDevice.ACTION_FOUND));
        activity.registerReceiver(discoverReceiver, new IntentFilter(BluetoothAdapter.ACTION_DISCOVERY_FINISHED));
        bluetoothAdapter.startDiscovery();
    }

    private JSONObject deviceToJSON(BluetoothDevice device) throws JSONException {
        JSONObject json = new JSONObject();
        json.put("name", device.getName());
        json.put("address", device.getAddress());
        json.put("id", device.getAddress());
        if (device.getBluetoothClass() != null) {
            json.put("class", device.getBluetoothClass().getDeviceClass());
        }
        return json;
    }

    private void connect(CordovaArgs args, boolean secure, CallbackContext callbackContext) throws JSONException {
        String macAddress = args.getString(0);
        JSONArray uuidJSONArray = args.getJSONArray(1);

        String stringConnectUuid;
        UUID connectUuid;
        InterfaceContext interfaceContext;
        BluetoothClassicSerialService blueService;
        HashMap<String, InterfaceContext> deviceMap;

        if (mDeviceId == null) {
            mDeviceId = macAddress;
        }

        if (!mDeviceId.equalsIgnoreCase(macAddress)) {
            destroy();
            mDeviceId = macAddress;
        }

        BluetoothDevice device = bluetoothAdapter.getRemoteDevice(macAddress);

        if (device != null) {
                connectCallback = callbackContext;

            for (int i = 0; i < uuidJSONArray.length(); i++) {
                stringConnectUuid = uuidJSONArray.getString(i);
                connectUuid = UUID.fromString(stringConnectUuid);

                interfaceContext = connections.get(stringConnectUuid);

                if (interfaceContext == null){
                    interfaceContext = new InterfaceContext(stringConnectUuid);
                    connections.put(stringConnectUuid, interfaceContext);
                }

                if (interfaceContext != null) {
                    blueService = interfaceContext.bluetoothClassicSerialService;
                    blueService.connect(device, connectUuid, secure);
                }
            }

            PluginResult result = new PluginResult(PluginResult.Status.NO_RESULT);
            result.setKeepCallback(true);
            callbackContext.sendPluginResult(result);

        } else {
            callbackContext.error("Could not connect to " + macAddress);
        }
    }

    private void disconnect(CallbackContext callbackContext) {

        InterfaceContext ic;

        for(Map.Entry<String,InterfaceContext> entry: connections.entrySet()) {

            ic = entry.getValue();

            if (ic.bluetoothClassicSerialService != null) {
                ic.bluetoothClassicSerialService.stop();
            }

        }

        callbackContext.success();

    }

    private void destroy() {

        InterfaceContext ic;

        for(Map.Entry<String,InterfaceContext> entry: connections.entrySet()) {

            ic = entry.getValue();

            if (ic.bluetoothClassicSerialService != null) {
                ic.bluetoothClassicSerialService.stop();
            }

            connections.remove(entry.getKey());
        }
    }

    private void notifyConnectionLost(String error) {
        if (connectCallback != null) {
        connectCallback.error(error);
        connectCallback = null;
        }
    }

    private void notifyConnectionSuccess() {
            if (connectCallback != null) {
            PluginResult result = new PluginResult(PluginResult.Status.OK);
            result.setKeepCallback(true);
            connectCallback.sendPluginResult(result);
        }
    }

    private void setContextSubscribe(String interfaceId, CallbackContext cc, String delimiter) {

        InterfaceContext ic = null;

        ic = getInterfaceContext(interfaceId);

        if (ic == null) {
            ic = new InterfaceContext(interfaceId);
            setInterfaceContext(interfaceId, ic);
        }

        if (ic != null) {

            ic.dataAvailableCallback = cc;
            ic.delimiter = delimiter;

            setInterfaceContext(interfaceId, ic);
        }

    }

    private void setContextRawSubscribe(String interfaceId, CallbackContext cc) {

        InterfaceContext ic = null;

        ic = getInterfaceContext(interfaceId);

        if (ic == null) {
            ic = new InterfaceContext(interfaceId);
            setInterfaceContext(interfaceId, ic);
        }

        if (ic != null) {
            ic.rawDataAvailableCallback = cc;
            setInterfaceContext(interfaceId, ic);
        }

    }

    private InterfaceContext getInterfaceContext(String interfaceId) {
        return connections.get(interfaceId);
    }


    private void setInterfaceContext(String interfaceId, InterfaceContext ic) {

        if (interfaceId == null) {
            return;
        }

        if (ic == null) {
            ic = new InterfaceContext(interfaceId);
        }

        connections.put(interfaceId, ic);

    }

    private void clearInterfaceBuffer(String deviceId, String interfaceId) {
        InterfaceContext ic = null;

        ic = getInterfaceContext(interfaceId);

        if (ic != null) {
            ic.clearBuffer();
        }

    }

    private void isConnected(CallbackContext callbackContext) {

      InterfaceContext ic;
      boolean successful;

      successful = true;

      for(Map.Entry<String,InterfaceContext> entry: connections.entrySet()) {

          ic = entry.getValue();

          if (ic.bluetoothClassicSerialService.getState() != BluetoothClassicSerialService.STATE_CONNECTED) {
              successful = false;
          }

        }

        if (successful == true) {
          callbackContext.success();
        } else {
          callbackContext.error("Not connected.");
        }
    }
}
