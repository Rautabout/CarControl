import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class GeoLocation extends StatefulWidget {
  @override
  _GeoLocationState createState() => _GeoLocationState();
}

class _GeoLocationState extends State<GeoLocation> {
  final _database = FirebaseDatabase.instance.reference();
  final _firebaseDatabase =
      FirebaseFirestore.instance.collection('coordinates');

  @override
  void initState() {
    super.initState();
    _activateListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _activateListeners() {
    _database.child('coordinates/latitude').onValue.listen((event) {
      final double tempLat = event.snapshot.value;
      setState(() {
        _firebaseDatabase.doc('coords').update({'lat': tempLat});
      });
    });
    _database.child('coordinates/longitude').onValue.listen((event) {
      final double tempLng = event.snapshot.value;
      setState(() {
        _firebaseDatabase.doc('coords').update({'lng': tempLng});
      });
    });
  }

  GoogleMapController _controller;
  bool _added = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Geo Map Screen'),
          //title: (Text(latitude + longitude)),
        ),
        body: StreamBuilder(
          stream:
              FirebaseFirestore.instance.collection('coordinates').snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (_added) {
              updateMap(snapshot);
            }
            if (!snapshot.hasData) {
              return Center(
                child: Column(
                  children: const [
                    Text('Loading...'),
                    CircularProgressIndicator()
                  ],
                ),
              );
            }
            return GoogleMap(
              mapType: MapType.terrain,
              markers: {
                Marker(
                    position: LatLng(
                        snapshot.data.docs.singleWhere(
                            (element) => element.id == 'coords')['lat'],
                        snapshot.data.docs.singleWhere(
                            (element) => element.id == 'coords')['lng']),
                    markerId: const MarkerId('Car Location'))
              },
              initialCameraPosition: CameraPosition(
                  target: LatLng(
                      snapshot.data.docs.singleWhere(
                          (element) => element.id == 'coords')['lat'],
                      snapshot.data.docs.singleWhere(
                          (element) => element.id == 'coords')['lng']),
                  zoom: 18),
              onMapCreated: (GoogleMapController controller) async {
                setState(() {
                  _controller = controller;
                  _added = true;
                });
              },
            );
          },
        ));
  }

  Future<void> updateMap(AsyncSnapshot<QuerySnapshot> snapshot) async {
    await _controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
            target: LatLng(
                snapshot.data.docs
                    .singleWhere((element) => element.id == 'coords')['lat'],
                snapshot.data.docs
                    .singleWhere((element) => element.id == 'coords')['lng']),
            zoom: 18)));
  }
}
