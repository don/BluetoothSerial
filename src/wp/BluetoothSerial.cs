using System;
using System.Linq;
using System.Collections.Generic;
using System.Diagnostics;
using System.Runtime.Serialization;
using Windows.Networking.Proximity;
using WPCordovaClassLib.Cordova;
using WPCordovaClassLib.Cordova.Commands;
using WPCordovaClassLib.Cordova.JSON;
using Microsoft.Phone.Tasks;

using BluetoothConnectionManager;
using Windows.Networking;
using System.Text;
using System.Threading;

public class BluetoothSerial : BaseCommand
{
    private ConnectionManager connectionManager;
    private string token; // normally a char like \n  TODO rename to delimiter
    private string connectionCallbackId;
    private string rawDataCallbackId;
    private string subscribeCallbackId;

    // TODO maybe use one buffer if delimiter is a char and not a string
    private StringBuilder buffer = new StringBuilder("");
    private List<byte> byteBuffer = new List<byte>();
    private Timer timer;
    private int MIN_RAW_DATA_COUNT = 6; // queue data until it reaches this count
    private int RAW_DATA_FLUSH_TIMER_MILLIS = 200;

    private Boolean connected = false;

    public async void list(string args)
    {
        Debug.WriteLine("Listing Paired Bluetooth Devices");

        PeerFinder.AlternateIdentities["Bluetooth:Paired"] = "";
        try
        {
            var pairedDevices = await PeerFinder.FindAllPeersAsync();

            if (pairedDevices.Count == 0)
            {
                Debug.WriteLine("No paired devices were found.");
            }

            // return serializable device info
            var pairedDeviceList = new List<PairedDeviceInfo>(pairedDevices.Select(x => new PairedDeviceInfo(x)));
            DispatchCommandResult(new PluginResult(PluginResult.Status.OK, pairedDeviceList));
        }
        catch (Exception ex)
        {
            if ((uint)ex.HResult == 0x8007048F)
            {
                DispatchCommandResult(new PluginResult(PluginResult.Status.ERROR, "Bluetooth is disabled"));
            }
            else
            {
                DispatchCommandResult(new PluginResult(PluginResult.Status.ERROR, ex.Message));
            }
        }

    }

    public void connect(string args)
    {
        string[] javascriptArgs = JsonHelper.Deserialize<string[]>(args);
        string macAddress = javascriptArgs[0];
        connectionCallbackId = javascriptArgs[1];

        connectionManager = new ConnectionManager();
        connectionManager.Initialize(); // TODO can't we put this in the constructor?
        connectionManager.ByteReceived += connectionManager_ByteReceived;

        connectionManager.ConnectionSuccess += connectionManager_ConnectionSuccess;
        connectionManager.ConnectionFailure += connectionManager_ConnectionFailure;

        try
        {
            HostName deviceHostName = new HostName(macAddress);
            connectionManager.Connect(deviceHostName);
        }
        catch (Exception ex)
        {
            Debug.WriteLine(ex);
            connectionManager_ConnectionFailure("Invalid Hostname");
        }

    }

    public void disconnect(string args)
    {
        if (connectionManager != null)
        {
            connectionCallbackId = null;
            connectionManager.Terminate();
        }

        DispatchCommandResult(new PluginResult(PluginResult.Status.OK));
    }

    public void subscribe(string args)
    {
        var arguments = JsonHelper.Deserialize<string[]>(args);
        token = arguments[0];
        subscribeCallbackId = arguments[1];
    }

    public void unsubscribe(string args)
    {
        token = null;
        subscribeCallbackId = null;

        DispatchCommandResult(new PluginResult(PluginResult.Status.OK));
    }

    // TODO rename subscribeRawData (across all platforms)
    public void subscribeRaw(string args)
    {
        rawDataCallbackId = JsonHelper.Deserialize<string[]>(args)[0];
        timer = new Timer(new TimerCallback(FlushByteBuffer));
    }

    // TODO rename unsubscribeRawData
    public void unsubscribeRaw(string args)
    {
        rawDataCallbackId = null;
        if (timer != null)
        {
            timer.Dispose();
        }
        DispatchCommandResult(new PluginResult(PluginResult.Status.OK));
    }

    public async void write(string args)
    {
        string[] javascriptArgs = JsonHelper.Deserialize<string[]>(args);
        string encodedMessageBytes = javascriptArgs[0];
        string writeCallbackId = javascriptArgs[1];

        byte[] data = Convert.FromBase64String(encodedMessageBytes);
        var success = await connectionManager.WriteData(data);

        if (success)
        {
            DispatchCommandResult(new PluginResult(PluginResult.Status.OK), writeCallbackId);
        }
        else
        {
            DispatchCommandResult(new PluginResult(PluginResult.Status.ERROR), writeCallbackId);
        }
    }

    public void available(string args) {
        string callbackId = JsonHelper.Deserialize<string[]>(args)[0];
        DispatchCommandResult(new PluginResult(PluginResult.Status.OK, buffer.Length), callbackId);
    }

    public void read(string args) {
        int length = buffer.Length; // can the size of the buffer change in this method?
        string message = buffer.ToString(0, length);
        buffer.Remove(0, length);
        DispatchCommandResult(new PluginResult(PluginResult.Status.OK, message));
    }

    public void readUntil(string args) {
        string delimiter = JsonHelper.Deserialize<string[]>(args)[0];

        int index = buffer.ToString().IndexOf(delimiter);
        string message = buffer.ToString(0, index + delimiter.Length);
        buffer.Remove(0, index + delimiter.Length);

        DispatchCommandResult(new PluginResult(PluginResult.Status.OK, message));
    }

    public void clear(string args) {
        buffer.Clear();
        DispatchCommandResult(new PluginResult(PluginResult.Status.OK));
    }

    public void isConnected(string args)
    {
        if (connected)
        {
            DispatchCommandResult(new PluginResult(PluginResult.Status.OK));
        }
        else
        {
            DispatchCommandResult(new PluginResult(PluginResult.Status.ERROR));
        }
    }

    public async void isEnabled(string args)
    {
        string callbackId = JsonHelper.Deserialize<string[]>(args)[0];

        // This is a bad way to do this, improve later
        // See if we can determine in the Connection Manager
        // https://msdn.microsoft.com/library/windows/apps/jj207007(v=vs.105).aspx
        PeerFinder.AlternateIdentities["Bluetooth:Paired"] = "";

        try
        {
            var peers = await PeerFinder.FindAllPeersAsync();

            // Handle the result of the FindAllPeersAsync call
        }
        catch (Exception ex)
        {
            if ((uint)ex.HResult == 0x8007048F)
            {
                DispatchCommandResult(new PluginResult(PluginResult.Status.ERROR), callbackId);
            }
            else
            {
                DispatchCommandResult(new PluginResult(PluginResult.Status.ERROR, ex.Message), callbackId);
            }
        }

        DispatchCommandResult(new PluginResult(PluginResult.Status.OK), callbackId);
    }

    public void showBluetoothSettings(string args)
    {
        ConnectionSettingsTask connectionSettingsTask = new ConnectionSettingsTask();
        connectionSettingsTask.ConnectionSettingsType = ConnectionSettingsType.Bluetooth;
        connectionSettingsTask.Show();
        DispatchCommandResult(new PluginResult(PluginResult.Status.OK));
    }

    private void connectionManager_ConnectionSuccess()
    {
        if (connectionCallbackId != null)
        {
            PluginResult result = new PluginResult(PluginResult.Status.OK);
            result.KeepCallback = true;
            DispatchCommandResult(result, connectionCallbackId);
        }
        connected = true;
    }

    private void connectionManager_ConnectionFailure(string reason)
    {
        if (connectionCallbackId != null)
        {
            PluginResult result = new PluginResult(PluginResult.Status.ERROR, reason);
            result.KeepCallback = true;
            DispatchCommandResult(result, connectionCallbackId);
        }
        connected = false;
    }

    private void connectionManager_ByteReceived(byte data)
    {
        char dataAsChar = Convert.ToChar(data);
        buffer.Append(dataAsChar);
        byteBuffer.Add(data);

        Debug.WriteLine(data + " " + dataAsChar);

        if (rawDataCallbackId != null)
        {
            MaybeSendRawData();
        }

        if (subscribeCallbackId != null)
        {
            sendDataToSubscriber();
        }

    }

    // This method is called by the timer delegate.
    private void FlushByteBuffer(Object stateInfo)
    {
        SendRawDataToSubscriber();
    }

    private void SendRawDataToSubscriber()
    {
        if (byteBuffer.Count > 0)
        {
            // NOTE an array of 1 gets flattened to an int, we fix in JavaScript
            PluginResult result = new PluginResult(PluginResult.Status.OK, byteBuffer);
            result.KeepCallback = true;
            DispatchCommandResult(result, rawDataCallbackId);
            byteBuffer.Clear();
        }
    }

    private void MaybeSendRawData() // TODO rename "fill raw data buffer and maybe send to subscribers"
    {
        if (byteBuffer.Count >= MIN_RAW_DATA_COUNT)
        {
            SendRawDataToSubscriber();
        }
        else if (byteBuffer.Count == 0)
        {
            Debug.WriteLine("Empty");
        }
        else
        {
            Debug.WriteLine("Not enough data");
            timer.Change(RAW_DATA_FLUSH_TIMER_MILLIS, Timeout.Infinite);  // reset the timer
        }
    }

    private void sendDataToSubscriber()
    {
        string delimiter = token;
        int index = buffer.ToString().IndexOf(delimiter);
        if (index > -1)
        {
            string message = buffer.ToString(0, index + delimiter.Length);
            buffer.Remove(0, index + delimiter.Length);

            PluginResult result = new PluginResult(PluginResult.Status.OK, message);
            result.KeepCallback = true;
            DispatchCommandResult(result, subscribeCallbackId);

            // call again in case the delimiter occurs multiple times
            sendDataToSubscriber();
        }

    }

    [DataContract]
    public class PairedDeviceInfo
    {
        public PairedDeviceInfo(PeerInformation peerInformation)
        {
            id = peerInformation.HostName.ToString();
            name = peerInformation.DisplayName;
        }

        [DataMember]
        public String id { get; set; }
        [DataMember]
        public String name { get; set; }
    }


}
