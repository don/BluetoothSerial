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

public class BluetoothSerial : BaseCommand
{

    /*
    - (void)connect:(CDVInvokedUrlCommand *)command;
    - (void)disconnect:(CDVInvokedUrlCommand *)command;

    - (void)subscribe:(CDVInvokedUrlCommand *)command;
    - (void)unsubscribe:(CDVInvokedUrlCommand *)command;
    - (void)subscribeRaw:(CDVInvokedUrlCommand *)command;
    - (void)unsubscribeRaw:(CDVInvokedUrlCommand *)command;
    - (void)write:(CDVInvokedUrlCommand *)command;

    - (void)list:(CDVInvokedUrlCommand *)command;
    - (void)isEnabled:(CDVInvokedUrlCommand *)command;
    - (void)isConnected:(CDVInvokedUrlCommand *)command;

    - (void)available:(CDVInvokedUrlCommand *)command;
    - (void)read:(CDVInvokedUrlCommand *)command;
    - (void)readUntil:(CDVInvokedUrlCommand *)command;
    - (void)clear:(CDVInvokedUrlCommand *)command;

    - (void)readRSSI:(CDVInvokedUrlCommand *)command;
    */

    private ConnectionManager connectionManager;
    private string token; // normally a char like \n
    private string rawDataCallbackId;
    private string subscribeCallbackId;

    private StringBuilder buffer = new StringBuilder("This is a test\nThis is fake data\nFin.");

    // no args
    public async void list(string args)
    {
        Debug.WriteLine("Listing Paired Bluetooth Devices");

        PeerFinder.AlternateIdentities["Bluetooth:Paired"] = "";
        var pairedDevices = await PeerFinder.FindAllPeersAsync();

        if (pairedDevices.Count == 0)
        {
            Debug.WriteLine("No paired devices were found.");
        }

        // convert to serializable format
        var pairedDeviceList = new List<PairedDeviceInfo>(pairedDevices.Select(x => new PairedDeviceInfo(x)));
        DispatchCommandResult(new PluginResult(PluginResult.Status.OK, pairedDeviceList));
    }

    public void connect(string args)
    {
        string macAddress = JsonHelper.Deserialize<string[]>(args)[0];

        connectionManager = new ConnectionManager();
        connectionManager.Initialize(); // TODO can't we put this in the constructor?
        connectionManager.MessageReceived += connectionManager_MessageReceived;

        // TODO handle invalud hostname
        HostName deviceHostName = new HostName(macAddress);

        connectionManager.Connect(deviceHostName);

        // TODO we need a callback here for when the connection really happens, otherwise if connection timeout randomly get error later
        // TODO keep callback for and handle unexpected disconnection
        DispatchCommandResult(new PluginResult(PluginResult.Status.OK)); 
    }

    // TODO this needs to change and give us RAW data
    private void connectionManager_MessageReceived(string message)
    {
        Debug.WriteLine(message);

        // store the data in the buffer as a string

        // if there's a rawDataCallbackId, send the data right away
        if (rawDataCallbackId != null)
        {
            byte[] messageBytes = Encoding.UTF8.GetBytes(message);
            DispatchCommandResult(new PluginResult(PluginResult.Status.OK, messageBytes), rawDataCallbackId);
        }
  
        // TODO see other implementations
        if (subscribeCallbackId != null)
        {
            // TODO really only send to the delimiter
            // TODO need to handle the case with multiple delimiters
            //DispatchCommandResult(new PluginResult(PluginResult.Status.OK, message), subscribeCallbackId);

            var pluginResult = new PluginResult(PluginResult.Status.OK, message);
            pluginResult.KeepCallback = true;
            DispatchCommandResult(pluginResult, subscribeCallbackId);
        }

    }

    public void disconnect(string args)
    {
        if (connectionManager != null)
        {
            connectionManager.Terminate();
        }
        
        DispatchCommandResult(new PluginResult(PluginResult.Status.OK));
    }

    public void subscribe(string args)
    {
        var arguments = JsonHelper.Deserialize<string[]>(args);
        token = arguments[0];
        subscribeCallbackId = arguments[1];

        // success is called when data arrives 
        // BOGUS TESTING
        //DispatchCommandResult(new PluginResult(PluginResult.Status.OK, "remove this"));
        //DispatchCommandResult(new PluginResult(PluginResult.Status.NO_RESULT));

        /*
        TODO is this required? I hope not.
        var pr = new PluginResult(PluginResult.Status.NO_RESULT);
        pr.KeepCallback = true;
        DispatchCommandResult(pr);
         */ 
    }

    public void unsubscribe(string args)
    {
        token = null;
        subscribeCallbackId = null;

        DispatchCommandResult(new PluginResult(PluginResult.Status.OK));
    }

    public void subscribeRaw(string args)
    {
        rawDataCallbackId = JsonHelper.Deserialize<string[]>(args)[0];

        // success is called when data arrives 
        DispatchCommandResult(new PluginResult(PluginResult.Status.NO_RESULT)); // TODO keep callback?
    }

    public void unsubscribeRaw(string args)
    {
        rawDataCallbackId = null;

        DispatchCommandResult(new PluginResult(PluginResult.Status.OK));
    }

    public async void write(string args)
    {
        // TODO need to handle bytes
        string encodedMessageBytes = JsonHelper.Deserialize<string[]>(args)[0];
        byte[] data = Convert.FromBase64String(encodedMessageBytes);

        // Using a string for now until I fix the underlying class
        var message = Encoding.UTF8.GetString(data, 0, data.Length);

        var result = await connectionManager.SendCommand(message);

        // TODO handle bad cases
        DispatchCommandResult(new PluginResult(PluginResult.Status.OK));
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

    // TODO new API, need to add JavaScript
    public void showBluetoothConnectionSettings(string args)
    {
        ConnectionSettingsTask connectionSettingsTask = new ConnectionSettingsTask();
        connectionSettingsTask.ConnectionSettingsType = ConnectionSettingsType.Bluetooth;
        connectionSettingsTask.Show();
        DispatchCommandResult(new PluginResult(PluginResult.Status.OK));
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
