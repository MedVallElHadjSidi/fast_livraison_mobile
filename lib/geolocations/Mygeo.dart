import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class MyGeo extends StatefulWidget {
  const MyGeo({super.key});

  @override
  State<MyGeo> createState() => _MyGeoState();
}

class _MyGeoState extends State<MyGeo> {
  StreamSubscription<Position>? positionStream;
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  GoogleMapController? gmc;

  CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(18.0718016, -15.9557083),
    zoom: 40,
  );
  List<Marker> _markers = [];
  getCurrentLocationApp() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      print("Location services are disabled.");
      // return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
          if (permission == LocationPermission.whileInUse) {
      //Ce code configure comment le GPS va fonctionner dans ton application.
      // final LocationSettings locationSettings = LocationSettings(
      //   accuracy: LocationAccuracy.high,
      //   distanceFilter: 100,
      // );

      // Position position = await Geolocator.getCurrentPosition(
      //   locationSettings: locationSettings,
      // );
      Position position = await Geolocator.getCurrentPosition();
      print("------debut--------");
      // print(position.altitude);
      print(position.latitude);
      print(position.longitude);
      print("--------fin------");

      print(permission);

      _kGooglePlex = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 40.4746,
      );
      setState(() {});

      positionStream = Geolocator.getPositionStream().listen((
        Position? position,
      ) {
        print("------debut--------");
        print(position!.latitude);
        print(position.longitude);
        print("--------fin------");

        print("---------------------");
        double distanceInMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          36.8065,
          10.1815,
        );
        print("Distance in meters: $distanceInMeters");
        _markers.add(
          Marker(
            markerId: MarkerId("1"),
            position: LatLng(position.latitude, position.longitude),
          ),
        );
        gmc!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 40.4746,
            ),
          ),
        );
        setState(() {});
      });
    }

      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever, handle appropriately.
        return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.',
        );
      }
    }


  }

  initState() {
    super.initState();
    getCurrentLocationApp();
  }

  ondispose() {
    if (positionStream != null) {
      positionStream!.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Expanded(
            child: GoogleMap(
              mapType: MapType.normal,
              markers: _markers.toSet(),
              onTap: (LatLng latlng) => {
                print(latlng.latitude),
                print(latlng.longitude),
                // _markers.add(Marker(markerId: MarkerId("2"), position: argument)),
                // _markers.add(Marker(markerId: MarkerId("1"), position: LatLng(latlng.latitude, latlng.longitude))),
                // setState(() {})
              },
              initialCameraPosition: _kGooglePlex,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            ),
          ),
        ],
      ),
    );
  }
}
