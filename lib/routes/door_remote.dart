import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:scoped_model/scoped_model.dart';

import 'bluetooth_discovery.dart';

class DoorRemote extends StatefulWidget {
  const DoorRemote({Key? key}) : super(key: key);

  @override
  _DoorRemoteState createState() => _DoorRemoteState();
}

class _DoorRemoteState extends State<DoorRemote> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  String _deviceConnected = "...";
  List<BluetoothDevice> _devicesList = [];

  String _address = "...";
  String _name = "...";

  Timer? _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;

  //BackgroundCollectingTask? _collectingTask;

  bool _autoAcceptPairingRequests = false;
  late BluetoothDevice _device;

  @override
  void initState() {
    super.initState();

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if ((await FlutterBluetoothSerial.instance.isEnabled) ?? false) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // Update the address field
      FlutterBluetoothSerial.instance.address.then((address) {
        setState(() {
          _address = address!;
        });
      });
    });

    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() {
        _name = name!;
      });
    });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // Discoverable mode is disabled when Bluetooth gets disabled
        _discoverableTimeoutTimer = null;
        _discoverableTimeoutSecondsLeft = 0;
      });
    });
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    // _collectingTask?.dispose();
    _discoverableTimeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> getPairedDevices() async {
    List<BluetoothDevice> devices = [];

    // To get the list of paired devices
    try {
      devices = await _bluetooth.getBondedDevices();
    } on PlatformException {
      print("Error");
    }

    // It is an error to call [setState] unless [mounted] is true.
    if (!mounted) {
      return;
    }

    // Store the [devices] list in the [_devicesList] for accessing
    // the list outside this class
    setState(() {
      _devicesList = devices;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Door Remote Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SwitchListTile(
                title: const Text('Enable Bluetooth'),
                value: _bluetoothState.isEnabled,
                onChanged: (bool value) {
                  future() async {
                    if (value) {
                      await FlutterBluetoothSerial.instance.requestEnable();
                      await getPairedDevices();
                    } else {
                      await FlutterBluetoothSerial.instance.requestDisable();
                    }
                  }

                  future().then((_) {
                    setState(() {});
                  });
                }),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    'Device:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  DropdownButton(
                    items: _getDeviceItems(),
                    onChanged: ( value)=>
                    setState(() =>
                      _device=value
                    ),
                    // onChanged: (value) =>
                    //     setState(() => _device = value),
                    //value: _devicesList.isNotEmpty ? _device : null,
                    value: _devicesList.isNotEmpty ? _device : null,
                  ),
                  const ElevatedButton(
                    // onPressed: _isButtonUnavailable
                    //     ? null
                    //     : _connected ? _disconnect : _connect,
                    onPressed: null,
                    child:
                      Text("connect")
                    //Text(_connected ? 'Disconnect' : 'Connect'),
                  ),
                ],
              ),
            ),
            // ListTile(
            //   title: ElevatedButton(
            //       child: const Text('Explore discovered devices'),
            //       onPressed: () async {
            //         final BluetoothDevice? selectedDevice =
            //             await Navigator.of(context).push(
            //           MaterialPageRoute(
            //             builder: (context) {
            //               return BluetoothDiscovery();
            //             },
            //           ),
            //         );
            //
            //         if (selectedDevice != null) {
            //           print('Discovery -> selected ' + selectedDevice.address);
            //           _deviceConnected = selectedDevice.address;
            //         } else {
            //           print('Discovery -> no device selected');
            //         }
            //       }),
            // ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  side: const BorderSide(
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                //elevation: _deviceState == 0 ? 4 : 0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: const <Widget>[
                      Expanded(
                        child: Text(
                          "DEVICE 1",
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                      ),
                      TextButton(
                        child: Text("ON"),
                        onPressed: null,
                      ),
                      TextButton(
                        onPressed: null,
                        child: Text("OFF"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 150,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  elevation: 5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devicesList.isEmpty) {
      items.add(DropdownMenuItem(
        child: Text('NONE'),
      ));
    } else {
      _devicesList.forEach((device) {
        items.add(DropdownMenuItem(
          child: Text(device.name??''),
          value: device,
        ));
      });
    }
    return items;
  }
}
