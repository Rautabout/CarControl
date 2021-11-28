import 'package:flutter/material.dart';

class DoorRemote extends StatefulWidget {
  const DoorRemote({Key? key}) : super(key: key);

  @override
  _DoorRemoteState createState() => _DoorRemoteState();
}

class _DoorRemoteState extends State<DoorRemote> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Door Remote Screen'),
      ),
      body: Center(
        child: ElevatedButton(
          // Within the SecondScreen widget
          onPressed: () {
            // Navigate back to the first screen by popping the current route
            // off the stack.
          },
          child: const Text('Go back!'),
        ),
      ),
    );
  }
}
