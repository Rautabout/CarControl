import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class DoorRemote extends StatefulWidget {
  const DoorRemote({Key key}) : super(key: key);

  @override
  _DoorRemoteState createState() => _DoorRemoteState();
}

class _DoorRemoteState extends State<DoorRemote> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection connection;
  bool isOpen = false;

  int _deviceState;
  String bluetoothPassword = "";
  bool passwordCorrection = false;

  bool isDisconnecting = false;

  bool get isConnected => connection != null && connection.isConnected;

  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice _device;
  bool _connected = false;
  bool _isButtonUnavailable = false;

  @override
  void initState() {
    super.initState();

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

  Future<void> enableBluetooth() async {
    _bluetoothState = await FlutterBluetoothSerial.instance.state;

    if (_bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
      await getPairedDevices();
      return true;
    } else {
      await getPairedDevices();
    }
    return false;
  }

  Future<void> getPairedDevices() async {
    List<BluetoothDevice> devices = [];

    try {
      devices = await _bluetooth.getBondedDevices();
    } on PlatformException {
      show("Couldn't get the devices");
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _devicesList = devices;
    });
  }

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
                              onPressed: () {
                                if (_isButtonUnavailable) {
                                } else {
                                  if (_connected) {
                                    _disconnect();
                                  } else {
                                    _connect();
                                  }
                                }
                              },
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
                              const SizedBox(
                                width: 600,
                                height: 10,
                              ),
                              const Text('Doors',
                                  style: TextStyle(
                                    fontSize: 32,
                                  )),
                              const SizedBox(
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
                                            255, 35, 191, 0);
                                      } else {
                                        return const Color.fromARGB(
                                            255, 52, 99, 52);
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
                              const SizedBox(
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

  Future<void> _displayPasswordInputDialog(BuildContext context) async {
    TextEditingController passwordController = TextEditingController();
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return AlertDialog(
            actionsAlignment: MainAxisAlignment.center,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Text("Enter bluetooth password:"),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                )
              ],
            ),
            actions: <Widget>[
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      bluetoothPassword = passwordController.text;
                    });
                    _sendPasswordToBluetooth();
                    _getResponseFromBluetooth();
                    Navigator.pop(context);
                  },
                  child: const Text('Check'))
            ],
          );
        });
  }

  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devicesList.isEmpty) {
      items.add(const DropdownMenuItem(
        child: Text('NONE'),
      ));
    } else {
      for (var device in _devicesList) {
        items.add(DropdownMenuItem(
          child: Text(device.name),
          value: device,
        ));
      }
    }
    return items;
  }

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
            show("Connected to the device");
            connection = _connection;
            setState(() {
              _connected = true;
            });
            _displayPasswordInputDialog(context).then((value) {
              connection.input.listen(null).onDone(() {
                if (isDisconnecting) {
                  show('Device disconnected locally');
                  _connected = false;
                } else {
                  show('Device disconnected remotely');
                  _connected = false;
                }
                if (mounted) {
                  setState(() {});
                }
              });
            });
          } else {
            show("Wrong device selected!");
          }
        }).catchError((error) {
          show("Cannot connect to the device");
        });

        setState(() => _isButtonUnavailable = false);
      }
    }
  }

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

  void _getResponseFromBluetooth() {
    connection.input.listen((Uint8List data) {
      if (utf8.decode(data) == '0') {
        show("Wrong password entered, disconnecting!");
        _disconnect();
        return;
      } else {
        show("Correct password entered");
        return;
      }
    });
  }

  void _sendPasswordToBluetooth() async {
    connection.output.add(utf8.encode(bluetoothPassword + "#\n"));
    await connection.output.allSent;
  }

  void _sendOnMessageToBluetooth() async {
    connection.output.add(utf8.encode("1\n"));
    await connection.output.allSent;
    show('Device Turned On');
    setState(() {
      _deviceState = 1; // device on
    });
  }

  void _sendOffMessageToBluetooth() async {
    connection.output.add(utf8.encode("0\n"));
    await connection.output.allSent;
    show('Device Turned Off');
    setState(() {
      _deviceState = -1; // device off
    });
  }

  Future show(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
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
