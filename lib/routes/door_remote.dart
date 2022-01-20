import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class DoorRemote extends StatefulWidget {
  @override
  _DoorRemoteState createState() => _DoorRemoteState();
}

class _DoorRemoteState extends State<DoorRemote> {
  // Initializing the Bluetooth connection state to be unknown
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  // Initializing a global key, as it would help us in showing a SnackBar later
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  // Get the instance of the Bluetooth
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  // Track the Bluetooth connection with the remote device
  BluetoothConnection connection;
  bool isOpen = false;

  int _deviceState;

  bool isDisconnecting = false;

  // To track whether the device is still connected to Bluetooth
  bool get isConnected => connection != null && connection.isConnected;

  // Define some variables, which will be required later
  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice _device;
  bool _connected = false;
  bool _isButtonUnavailable = false;

  @override
  void initState() {
    super.initState();

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    _deviceState = 0;

    enableBluetooth();

    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
        if (_bluetoothState == BluetoothState.STATE_OFF) {
          _isButtonUnavailable = true;
        }
        getPairedDevices();
      });
    });
  }

  @override
  void dispose() {
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }

    super.dispose();
  }

  // Request Bluetooth permission from the user
  Future<void> enableBluetooth() async {
    // Retrieving the current Bluetooth state
    _bluetoothState = await FlutterBluetoothSerial.instance.state;

    // If the bluetooth is off, then turn it on first
    // and then retrieve the devices that are paired.
    if (_bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
      await getPairedDevices();
      return true;
    } else {
      await getPairedDevices();
    }
    return false;
  }

  // For retrieving and storing the paired devices
  // in a list.
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

  // Now, its time to build the UI
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          centerTitle: true,
          title: const Text("Door Remote"),
          backgroundColor: Colors.blueGrey,
          actions: <Widget>[
            IconButton(
              icon: const Icon(
                Icons.refresh,
                color: Colors.white,
              ),
              onPressed: () async {
                // So, that when new devices are paired
                // while the app is running, user can refresh
                // the paired devices list.
                await getPairedDevices().then((_) {
                  show('Device list refreshed');
                });
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Visibility(
                visible: _isButtonUnavailable &&
                    _bluetoothState == BluetoothState.STATE_ON,
                child: const LinearProgressIndicator(
                  backgroundColor: Colors.yellow,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(
                      child: Text(
                        'Enable Bluetooth',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Padding(padding: EdgeInsets.fromLTRB(80, 0, 80, 0)),
                    Switch(
                      activeColor: Colors.blueGrey,
                      value: _bluetoothState.isEnabled,
                      onChanged: (bool value) {
                        future() async {
                          if (value) {
                            await FlutterBluetoothSerial.instance
                                .requestEnable();
                          } else {
                            await FlutterBluetoothSerial.instance
                                .requestDisable();
                          }

                          await getPairedDevices();
                          _isButtonUnavailable = false;

                          if (_connected) {
                            _disconnect();
                          }
                        }

                        future().then((_) {
                          setState(() {});
                        });
                      },
                    )
                  ],
                ),
              ),
              Stack(
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Text(
                          "PAIRED DEVICES",
                          style:
                              TextStyle(fontSize: 24, color: Colors.blueGrey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "NOTE: To succesfully set up the connection, select VehicleControl device",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
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
                              onChanged: (value) =>
                                  setState(() => _device = value),
                              value: _devicesList.isNotEmpty ? _device : null,
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  primary: Colors.blueGrey),
                              onPressed: _isButtonUnavailable
                                  ? null
                                  : _connected
                                      ? _disconnect
                                      : _connect,
                              child:
                                  Text(_connected ? 'Disconnect' : 'Connect'),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(2),
                        child: Card(
                          shape: RoundedRectangleBorder(
                              side: const BorderSide(width: 3),
                              borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            children: <Widget>[
                              Container(
                                width: 600,
                                height: 10,
                              ),
                              const Text('Doors',
                                  style: TextStyle(
                                    fontSize: 32,
                                  )),
                              Container(
                                width: 600,
                                height: 10,
                              ),
                              ElevatedButton(
                                style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.resolveWith<
                                            Color>((Set<MaterialState> states) {
                                      if (_connected == false) {
                                        return Colors.blueGrey;
                                      } else if (isOpen == false &&
                                          _connected == true) {
                                        return const Color.fromARGB(
                                            255, 34, 226, 0);
                                      } else {
                                        return const Color.fromARGB(
                                            255, 64, 125, 64);
                                      }
                                    }),
                                    fixedSize: MaterialStateProperty.all(
                                        const Size(300, 70)),
                                    shape: MaterialStateProperty.all(
                                        const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(15),
                                          topRight: Radius.circular(15),
                                          bottomLeft: Radius.circular(0),
                                          bottomRight: Radius.circular(0)),
                                    ))),
                                onPressed: () {
                                  if (isOpen == true && _connected == true) {
                                    show("Doors already open");
                                  } else if (isOpen == false &&
                                      _connected == true) {
                                    _sendOnMessageToBluetooth();
                                    isOpen = true;
                                  } else {
                                    show("Device not connected");
                                  }
                                },
                                child: const Text("Open",
                                    style: TextStyle(
                                      fontSize: 20,
                                    )),
                              ),
                              ElevatedButton(
                                style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.resolveWith<
                                            Color>((Set<MaterialState> states) {
                                      if (_connected == false) {
                                        return Colors.blueGrey;
                                      } else if (isOpen == true &&
                                          _connected == true) {
                                        return const Color.fromARGB(
                                            255, 241, 0, 0);
                                      } else {
                                        return const Color.fromARGB(
                                            255, 109, 0, 0);
                                      }
                                    }),
                                    fixedSize: MaterialStateProperty.all(
                                        const Size(300, 70)),
                                    shape: MaterialStateProperty.all(
                                        const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(0),
                                          topRight: Radius.circular(0),
                                          bottomLeft: Radius.circular(15),
                                          bottomRight: Radius.circular(15)),
                                    ))),
                                onPressed: () {
                                  if (isOpen == false && _connected == true) {
                                    show("Doors already closed");
                                  } else if (isOpen == true &&
                                      _connected == true) {
                                    _sendOffMessageToBluetooth();
                                    isOpen = false;
                                  } else {
                                    show("Device not connected");
                                  }
                                },
                                child: const Text("Close",
                                    style: TextStyle(
                                      fontSize: 20,
                                    )),
                              ),
                              Container(
                                width: 600,
                                height: 20,
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                  Container(
                    color: Colors.blue,
                  ),
                ],
              ),
              SizedBox(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Text(
                          "NOTE: If you cannot find the device in the list, please pair the device by going to the bluetooth settings",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              primary: Colors.blueGrey),
                          child: const Text("Bluetooth Settings"),
                          onPressed: () {
                            FlutterBluetoothSerial.instance.openSettings();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Create the List of devices to be shown in Dropdown Menu
  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devicesList.isEmpty) {
      items.add(const DropdownMenuItem(
        child: Text('NONE'),
      ));
    } else {
      _devicesList.forEach((device) {
        items.add(DropdownMenuItem(
          child: Text(device.name),
          value: device,
        ));
      });
    }
    return items;
  }

  // Method to connect to bluetooth
  void _connect() async {
    setState(() {
      _isButtonUnavailable = true;
    });
    if (_device == null) {
      show('No device selected');
      setState(() {
        _isButtonUnavailable = false;
      });
    } else {
      if (!isConnected) {
        await BluetoothConnection.toAddress(_device.address)
            .then((_connection) {
          if (_device.address == "7C:9E:BD:39:C9:12") {
            print(_device.address);
            print('Connected to the device');
            show("Connected to the device");
            connection = _connection;
            setState(() {
              _connected = true;
            });

            connection.input.listen(null).onDone(() {
              if (isDisconnecting) {
                show('Device disconnected locally');
                print('Disconnecting locally!');
                _connected = false;
              } else {
                show('Device disconnected remotely');
                print('Disconnected remotely!');
                _connected = false;
              }
              if (this.mounted) {
                setState(() {});
              }
            });
          } else {
            show("Wrong device selected!");
          }
        }).catchError((error) {
          show("Cannot connect to the device");
          print('Cannot connect, exception occurred');
          print(error);
        });
        //show('Device connected');

        setState(() => _isButtonUnavailable = false);
      }
    }
  }

  // Method to disconnect bluetooth
  void _disconnect() async {
    setState(() {
      _isButtonUnavailable = true;
      _deviceState = 0;
    });

    await connection.close();
    show('Device disconnected');
    if (!connection.isConnected) {
      setState(() {
        _connected = false;
        _isButtonUnavailable = false;
      });
    }
  }

  // Method to send message,
  // for turning the Bluetooth device on
  void _sendOnMessageToBluetooth() async {
    connection.output.add(utf8.encode("1"));
    await connection.output.allSent;
    show('Device Turned On');
    setState(() {
      _deviceState = 1; // device on
    });
  }

  // Method to send message,
  // for turning the Bluetooth device off
  void _sendOffMessageToBluetooth() async {
    connection.output.add(utf8.encode("0"));
    await connection.output.allSent;
    show('Device Turned Off');
    setState(() {
      _deviceState = -1; // device off
    });
  }

  // Method to show a Snackbar,
  // taking message as the text
  Future show(
    String message, {
    Duration duration: const Duration(seconds: 3),
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    //ScaffoldMessenger.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
        duration: duration,
      ),
    );
  }
}
