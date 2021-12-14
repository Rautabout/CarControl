import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothDiscovery extends StatefulWidget {
  const BluetoothDiscovery({Key? key}) : super(key: key);

  @override
  _BluetoothDiscoveryState createState() => _BluetoothDiscoveryState();
}

class _BluetoothDiscoveryState extends State<BluetoothDiscovery> {
  StreamSubscription<BluetoothDiscoveryResult>? _streamSubscription;
  List<BluetoothDiscoveryResult> results =
      List<BluetoothDiscoveryResult>.empty(growable: true);
  bool isDiscovering = false;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
