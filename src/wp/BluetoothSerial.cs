using System;
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

        PairedDeviceList pairedDeviceList = new PairedDeviceList(pairedDevices);

        if (pairedDevices.Count == 0)
        {
            Debug.WriteLine("No paired devices were found.");
        }

        // send the list back in the callback
        //DispatchCommandResult(new PluginResult(PluginResult.Status.OK, pairedDeviceList));
        DispatchCommandResult(new PluginResult(PluginResult.Status.OK, pairedDeviceList.devices));

    }

    // TODO eliminate this and just use a list
    // TODO map over PeerInformation list applying contructor to each element
    [DataContract]
    public class PairedDeviceList
    {
        public PairedDeviceList(IReadOnlyList<PeerInformation> peerInformationList)
        {
            var list = new List<PairedDeviceInfo>();

            foreach (var peerInfo in peerInformationList)
            {
                list.Add(new PairedDeviceInfo(peerInfo));
            }

            this.devices = list;
        }

        [DataMember]
        public List<PairedDeviceInfo> devices { get; set; }
    }

    [DataContract]
    public class PairedDeviceInfo
    {
        public PairedDeviceInfo()
        {

        }

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
