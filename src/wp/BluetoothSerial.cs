using System;
using System.Linq;
using System.Collections.Generic;
using System.Diagnostics;
using System.Runtime.Serialization;
using Windows.Networking.Proximity;
using WPCordovaClassLib.Cordova;
using WPCordovaClassLib.Cordova.Commands;
using WPCordovaClassLib.Cordova.JSON;

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
