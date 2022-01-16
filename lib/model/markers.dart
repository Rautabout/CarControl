class GeoMarker {
  String coordinates;
  double latitude;
  double longitude;

  GeoMarker({this.coordinates, this.latitude, this.longitude});

  GeoMarker.fromJson(this.coordinates, Map data) {
    latitude = data['latitude'];
    longitude = data['longitude'];
  }
}
