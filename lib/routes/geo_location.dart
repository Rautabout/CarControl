import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeoLocation extends StatefulWidget {
  const GeoLocation({Key? key}) : super(key: key);

  @override
  _GeoLocationState createState() => _GeoLocationState();
}

//50.2844313,18.731742,17z
class _GeoLocationState extends State<GeoLocation> {
  Completer<GoogleMapController> _controller = Completer();
  double lat = 50.2844313;
  double lng = 18.731742;

  static const CameraPosition _initialLocation = CameraPosition(
    target: LatLng(50.2844313, 18.731742),
    zoom: 18,
  );

  static const CameraPosition _kLake = CameraPosition(
      target: LatLng(50.2844313, 18.731742),
      zoom: 18);



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Geo Map Screen'),
        actions: [
          IconButton(onPressed: _goToTheLake, icon: Icon(Icons.refresh))
        ],
      ),
      body: Center(
        child: GoogleMap(
          //markers: ,
          mapType: MapType.hybrid,
          initialCameraPosition: _initialLocation,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
        ),
      ),

    );
  }

  Future<void> _goToTheLake() async {

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }
}
