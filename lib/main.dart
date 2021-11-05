import 'package:car_control/routes/door_remote.dart';
import 'package:car_control/routes/geo_location.dart';
import 'package:car_control/router.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(

        primarySwatch: Colors.blueGrey,
      ),
      home: const NavRouter(),

    );
  }
}
