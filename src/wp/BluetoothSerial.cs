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
    private string rawDataCallbackId;
    private string subscribeCallbackId;

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

        HostName deviceHostName = new HostName(macAddress);

        connectionManager.Connect(deviceHostName);
        DispatchCommandResult(new PluginResult(PluginResult.Status.OK));
    }

    private void connectionManager_MessageReceived(string message)
    {
        Debug.WriteLine(message);
        if (subscribeCallbackId != null)
        {
            DispatchCommandResult(new PluginResult(PluginResult.Status.OK, message), subscribeCallbackId);
        }
    }

    public void disconnect(string args)
    {
        connectionManager.Terminate();

        DispatchCommandResult(new PluginResult(PluginResult.Status.OK));
    }

    public void subscribe(string args)
    {
        var arguments = JsonHelper.Deserialize<string[]>(args);
        var token = arguments[0];
        subscribeCallbackId = arguments[1];
    }

    public void unsubscribe(string args)
    {

    }

    public void subscribeRaw(string args)
    {
        rawDataCallbackId = JsonHelper.Deserialize<string[]>(args)[0];
    }

    public void unsubscribeRaw(string args)
    {
        rawDataCallbackId = null;
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

    // TODO new API, need to add JavaScript
    public void showBluetoothConnectionSettings(string args)
    {
        ConnectionSettingsTask connectionSettingsTask = new ConnectionSettingsTask();
        connectionSettingsTask.ConnectionSettingsType = ConnectionSettingsType.Bluetooth;
        connectionSettingsTask.Show();
    }

    [DataContract]
    public class PairedDeviceInfo
    {
        public PairedDeviceInfo(PeerInformation peerInformation)
        {
            id = peerInformation.HostName.ToString(); // TODO might need to remove () from MAC
            name = peerInformation.DisplayName;
        }

        [DataMember]
        public String id { get; set; }
        [DataMember]
        public String name { get; set; }
    }


}
