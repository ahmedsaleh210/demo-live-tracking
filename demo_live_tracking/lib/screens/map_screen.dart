import 'dart:async';
import 'dart:developer';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:flutter/material.dart';
import 'package:real_time_tracking/services/location_service.dart';
import 'package:real_time_tracking/services/socket_service.dart';

import '../constants.dart';
import '../utils.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  final SocketService _socketService = SocketService();

  final Set<Marker> _markers = {};

  final Set<Polyline> locationPoints = {};

  LatLng _destinationLocation =
      const LatLng(31.059654023681095, 31.40516091138124);
  late LatLng _sourceLocation;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  late BitmapDescriptor customMarker;

  void _initLocation() async {
    final GoogleMapController controller = await _controller.future;
    customMarker = await getCustomMarker();
    _setMarkerLocation(
        _destinationLocation, LocationConstants.destinationLocationMarkerId);
    final position = await LocationService.getCurrentLocation();
    _sourceLocation = LatLng(position.latitude, position.longitude);
    _trackMyLocation(controller);
    await _drawPolyline();
  }

  void _trackMyLocation(GoogleMapController controller) {
    LocationService.onLocationChanged().listen((location) {
      setState(() {
        _sourceLocation = LatLng(location.latitude, location.longitude);
        _setMarkerLocation(
            _sourceLocation, LocationConstants.myLocationMarkerId);
        _animateToUserLocation(controller, _sourceLocation);
        _notifySocketWithNewLocation(_sourceLocation);
      });
    });
  }

  void _handleOnLocationChangedFromSocket() {
    _socketService.socket.on(
      SocketConstants.socketDestinationEventLocationChanged,
      (data) {
        _destinationLocation = LatLng(data['latitude'], data['longitude']);
        _setMarkerLocation(_destinationLocation,
            LocationConstants.destinationLocationMarkerId);
        setState(() {
          log("Destination Location Changed: $_destinationLocation");
        });
      },
    );
  }

  void _notifySocketWithNewLocation(LatLng location) {
    _socketService.socket
        .emit(SocketConstants.socketSourceEventLocationChanged, {
      'latitude': location.latitude,
      'longitude': location.longitude,
    });
  }

  void _getCurrentLocation() async {
    if (await LocationService.handlePermsission()) {
      final Position position = await LocationService.getCurrentLocation();
      _sourceLocation = LatLng(position.latitude, position.longitude);
      final GoogleMapController controller = await _controller.future;
      setState(() {
        _setMarkerLocation(
            _sourceLocation, LocationConstants.myLocationMarkerId);
        _animateToUserLocation(controller, _sourceLocation);
      });
    }
  }

  Future<void> _drawPolyline() async {
    final List<LatLng> route = await requestRoute(
        source: _sourceLocation, destination: _destinationLocation);
    log("Route: $route");
    setState(() {
      locationPoints.add(Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.deepPurple,
          width: 11,
          endCap: Cap.roundCap,
          startCap: Cap.roundCap,
          points: route));
    });
  }

  void _animateToUserLocation(GoogleMapController controller, LatLng location) {
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: location,
        zoom: 19.4746,
      ),
    ));
  }

  Marker _myMarker(LatLng location, String markerId) {
    return Marker(
        markerId: MarkerId(markerId),
        position: location,
        infoWindow: const InfoWindow(title: 'Current Location'),
        icon: customMarker);
  }

  void _setMarkerLocation(LatLng location, String markerId) {
    _markers.add(_myMarker(location, markerId));
  }

  @override
  void initState() {
    _initLocation();
    _handleOnLocationChangedFromSocket();
    super.initState();
  }

  @override
  void dispose() {
    _controller.future.then((controller) {
      controller.dispose();
    });
    _socketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        myLocationButtonEnabled: false,
        mapToolbarEnabled: false,
        zoomControlsEnabled: false,
        mapType: MapType.normal,
        initialCameraPosition: _kGooglePlex,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: _markers,
        polylines: locationPoints,
        onTap: (location) {
          log(location.toString());
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _getCurrentLocation,
        label: const Text('To My Location!'),
        icon: const Icon(Icons.location_on),
      ),
    );
  }
}
