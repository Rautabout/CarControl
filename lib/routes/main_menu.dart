import 'package:car_control/routes/door_remote.dart';
import 'package:car_control/routes/geo_location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({Key? key}) : super(key: key);

  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  final firestoreInstance = FirebaseFirestore.instance;
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        centerTitle: true,
        title: const Text("Car Control"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SizedBox(
              width: 150,
              child: ElevatedButton(
                onPressed: () {
                  firestoreInstance.collection('coordinates').doc('coords').get().then((value) {
                    print(value.data());
                  });
                },
                child: const Text('Connect bluetooth'),
                style: ElevatedButton.styleFrom(elevation: 5),
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
}
