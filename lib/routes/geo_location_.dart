import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeoLocation extends StatefulWidget {
  @override
  _GeoLocationState createState() => _GeoLocationState();
}

class _GeoLocationState extends State<GeoLocation> {
  String latitude = 'ff';
  String longitude = '';
  final database = FirebaseDatabase.instance.reference();
  void initState() {
    super.initState();
    _activateListeners();
  }

  void _activateListeners() {
    database.child('latitude').onValue.listen((event) {
      {
        final String tempLatitude = event.snapshot.value;
        setState(() {
          latitude = tempLatitude;
          print(latitude);
        });
      }
    });
    database.child('longitude');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Geo Map Screen'),
        ),
        body: Container(
          child: Column(
            children: [
              Text('hello viewers'),
              //Text(latitude),
              TextButton(
                  onPressed: () {
                    print(latitude);
                    database.set({'hej': 'ty'});
                  },
                  child: Text("click me"))
            ],
          ),
        ));
  }
}
