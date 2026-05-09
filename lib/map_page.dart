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

  Future<void> _onTap(LatLng latlng) async {
    try {
      final placemarks = await placemarkFromCoordinates(latlng.latitude, latlng.longitude);
      if (placemarks.isEmpty) return;

      final p = placemarks.first;
      
      if (!mounted) return;

      setState(() {
        _pickedMarker = Marker(
            markerId: const MarkerId("picked"),
            position: latlng,
            infoWindow: InfoWindow(
              title: p.name?.isNotEmpty == true ? p.name : "Lokasi Dipilih",
              snippet: "${p.street}, ${p.locality}",
            ));
        _pickedAddress = "${p.name}, ${p.street}, ${p.locality}, ${p.country}, ${p.postalCode}";
      });

      final ctrl = await _ctrl.future;
      await ctrl.animateCamera(CameraUpdate.newLatLng(latlng));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mengambil detail alamat untuk lokasi ini."))
      );
    }
  }

  void _confirmSelection() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Konfirmasi Alamat"),
        content: Text(_pickedAddress ?? "Tidak ada alamat dipilih"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, _pickedAddress);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text("Pilih"),
          )
        ],
      ),
    );
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
        actions: [
          if (_pickedAddress != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _confirmSelection,
            )
        ],
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
        onTap: _onTap,
      ),
    );
  }
}