import 'package:car_control/database_controller.dart';
import 'package:car_control/routes/door_remote.dart';
import 'package:car_control/routes/geo_location.dart';
import 'package:car_control/router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
      home: const DatabaseController(),

    );
  }
}
