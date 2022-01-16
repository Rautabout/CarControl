import 'package:vehicle_control/routes/door_remote.dart';
import 'package:vehicle_control/routes/geo_location.dart';
//import 'package:vehicle_control/routes/main_menu.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class NavRouter extends StatefulWidget {

  @override
  _NavRouterState createState() => _NavRouterState();
}

class _NavRouterState extends State<NavRouter> {
  int _currentIndex = 0;
  final List _children = [
    //const MainMenu(),
    DoorRemote(),
    GeoLocation()

  ];
  @override
  Widget build(BuildContext context) {

    return Scaffold(
        body: _children[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          onTap: onTabTapped,
          currentIndex: _currentIndex,
          items: const [
            // BottomNavigationBarItem(
            //   icon: Icon(Icons.home),
            //   label: "Home",
            // ),

            BottomNavigationBarItem(
              icon: Icon(Icons.settings_remote),
              label: "Door Remote",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: "Geo Map",
            ),
          ],
        ));
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
