import 'package:car_control/router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await Firebase.initializeApp(  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final Future<FirebaseApp> _firebaseApp = Firebase.initializeApp();
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.blueGrey,
        ),
        home: NavRouter(),
        // home: FutureBuilder(
        //   future: _firebaseApp,
        //   builder: (context, snapshot) {
        //     if (snapshot.hasError) {
        //       print("error");
        //     } else if (snapshot.hasData) {
        //       return NavRouter();
        //     } else {
        //       return Center(child: CircularProgressIndicator());
        //     }
        //   },
        // )
        //NavRouter(),

        );
  }
}
