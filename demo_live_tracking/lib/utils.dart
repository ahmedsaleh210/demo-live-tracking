import 'package:flutter/services.dart';
import 'package:georouter/georouter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;

Future<BitmapDescriptor> getCustomMarker() async {
  return await getBytesFromAsset('assets/icons/car.png', 170)
      .then((value) => BitmapDescriptor.fromBytes(value));
}

Future<Uint8List> getBytesFromAsset(String path, int width) async {
  ByteData data = await rootBundle.load(path);
  ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
      targetWidth: width);
  ui.FrameInfo fi = await codec.getNextFrame();
  return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
      .buffer
      .asUint8List();
}

Future<List<LatLng>> requestRoute(
    {required source, required destination}) async {
  final GeoRouter geoRouter = GeoRouter(mode: TravelMode.driving);
  List<PolylinePoint> router = await geoRouter.getDirectionsBetweenPoints([
    PolylinePoint(latitude: source.latitude, longitude: source.longitude),
    PolylinePoint(
        latitude: destination.latitude, longitude: destination.longitude)
  ]);
  return router.map((e) => LatLng(e.latitude, e.longitude)).toList();
}
