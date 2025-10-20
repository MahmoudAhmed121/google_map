import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const MapSample());
  }
}

class MapSample extends StatefulWidget {
  const MapSample({super.key});

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  Set<Marker> markers = {};
  CameraPosition? myLocation;
  Position? positionStream;

  static const CameraPosition _kLake = CameraPosition(
    target: LatLng(37.43296265331129, -122.08832357078792),
    zoom: 19.151926040649414,
  );

  @override
  void initState() {
    super.initState();
    getCurrentPosition();
    getpositionStream();

    addMarkers();
  }

  void getCurrentPosition() async {
    final position = await _determinePosition();
    CameraPosition myLocation = CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 14,
    );

    setState(() {
      this.myLocation = myLocation;
    });
  }

  void getpositionStream() {
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
    );
    StreamSubscription<Position> positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position? position) {
            this.positionStream = position;
            if(position != null){
              mylocationFromAddress();
              // calculateDistance(
              //   LatLng(position.latitude, position.longitude),
              //   LatLng(30.598516, 30.890420),
              // );
            }
          },
        );
  }

  void calculateDistance(LatLng from, LatLng to) {
    double distance = Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
    log('distanceInMeters: $distance');
  }

  void mylocationFromAddress() async {
    List<Placemark> locations = await placemarkFromCoordinates(
     positionStream?.latitude ?? 0,
     positionStream?.longitude ?? 0,
    );
    log('locations: $locations');

    log('locationJson: ${locations.first.toJson()}');
  }

  void addMarkers() async {
    final marker = Marker(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Cairo'),
            content: Text('Cairo is a city in Egypt'),
            actions: [TextButton(onPressed: () {}, child: Text('Close'))],
          ),
        );
      },
      icon: BitmapDescriptor.bytes(
        await getBytesFromAsset('assets/pngs/car.png', 50),
      ),
      infoWindow: InfoWindow(title: 'Cairo', snippet: 'Marker 1'),
      markerId: MarkerId('1'),
      onDragEnd: (LatLng position) {
        print('Marker 1 dragged to: $position');
        // call end point
      },
      position: LatLng(30.0441007, 31.2792385),
    );

    final marker2 = Marker(
      infoWindow: InfoWindow(title: 'mahmoud', snippet: 'Marker 2'),
      markerId: MarkerId('2'),
      position: LatLng(30.592940606817415, 30.90579276008728),
    );

    markers.add(marker);
    markers.add(marker2);

    setState(() {});
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return Future.error('Location permissions are denied');
        }
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Location permissions are permanently denied, we cannot request permissions.',
          ),
        ),
      );
    }
    return await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(distanceFilter: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('myLocation: $myLocation');
    return Scaffold(
      body: myLocation == null
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
              mapType: MapType.normal,
              myLocationEnabled: true,
              initialCameraPosition: myLocation ?? _kLake,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              markers: markers,
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToTheLake,
        label: const Text('go to my location'),
        icon: const Icon(Icons.location_on),
      ),
    );
  }

  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            positionStream?.latitude ?? 0,
            positionStream?.longitude ?? 0,
          ),
          zoom: 25,
        ),
      ),
    );
  }
}
