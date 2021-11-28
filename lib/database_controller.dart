import 'package:car_control/model/coordinates.dart';
import 'package:car_control/router.dart';
import 'package:car_control/services/database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DatabaseController extends StatefulWidget {
  const DatabaseController({Key? key}) : super(key: key);

  @override
  _DatabaseControllerState createState() => _DatabaseControllerState();
}

class _DatabaseControllerState extends State<DatabaseController> {
  final DatabaseService _database = DatabaseService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamProvider<List<Coordinates>>.value(
        value: _database.getCoordinates,initialData: [],
        child: NavRouter(),
      )
      // StreamProvider<List<Coordinates>>.value(
      //
      // ),
    );
  }
}
