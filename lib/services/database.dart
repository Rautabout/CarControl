import 'package:car_control/model/coordinates.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService{
  final CollectionReference coordinatesCollection = FirebaseFirestore.instance.collection('coordinates');

  List<Coordinates> _coordinates(QuerySnapshot snapshot){
    return snapshot.docs.map((doc){
      return Coordinates(
        lng: doc.data()['lng']??0,
        lat: doc.data()['lat']??0
      );
    }).toList();
  }

  Stream<List<Coordinates>> get getCoordinates{
    return coordinatesCollection.snapshots().map(_coordinates);
  }

}