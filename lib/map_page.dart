import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _ctrl = Completer();
  Marker? _pickedMarker;
  String? _pickedAddress;
  String? _currentAddress;
  CameraPosition? _initialcamera;

  @override
  void initState() {
    super.initState();
    _setupLocation();
  }

  Future<void> _setupLocation() async {
    try {
      final pos = await getPermission();
      _initialcamera = CameraPosition(
        target: LatLng(pos.latitude, pos.longitude),
        zoom: 16,
      );

      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);

      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        _currentAddress = "${p.name}, ${p.locality}, ${p.country}";
      }

      setState(() {});
    } catch (e) {
      if (!mounted) return;
      _initialcamera = const CameraPosition(target: LatLng(0, 0), zoom: 2);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<Position> getPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw "Layanan lokasi tidak aktif. Silakan aktifkan GPS Anda.";
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw "Izin lokasi ditolak.";
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw "Izin lokasi ditolak secara permanen. Silakan aktifkan di pengaturan.";
    }

    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    if (_initialcamera == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Mendapatkan Lokasi..."),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Alamat"),
      ),
      body: GoogleMap(
        initialCameraPosition: _initialcamera!,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        mapType: MapType.normal,
        compassEnabled: true,
        onMapCreated: (GoogleMapController ctrl) {
          if (!_ctrl.isCompleted) {
            _ctrl.complete(ctrl);
          }
        },
        markers: _pickedMarker != null ? {_pickedMarker!} : {},
      ),
    );
  }
}