import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// A class responsible for drawing a circle on a Mapbox map.
///
/// This class provides functionality to draw a circular area on a Mapbox map
/// with specified properties such as center, radius, and color.
class MapCircleDrawer {
  /// Creates a new instance of [MapCircleDrawer].
  ///
  /// [mapboxMap]: The Mapbox map instance to draw on.
  /// [center]: The center point of the circle.
  /// [radiusInMeters]: The radius of the circle in meters.
  /// [circleColor]: The color of the circle.
  MapCircleDrawer({
    required this.mapboxMap,
    required this.center,
    required this.radiusInMeters,
    required this.circleColor,
    this.strokeColor = Colors.black,
  });

  /// The Mapbox map instance to draw on.
  final MapboxMap? mapboxMap;

  /// The center point of the circle.
  Point center;

  /// The radius of the circle in meters.
  double radiusInMeters;

  /// The color of the circle.
  Color circleColor;

  /// The color of the circle's stroke.
  Color strokeColor = Colors.black;

  /// Draws the circle on the map.
  ///
  /// This method creates a GeoJSON source and a circle layer to represent
  /// the circular area on the map. It also sets up the circle's appearance
  /// and size based on the zoom level.
  Future<void> drawCircle() async {
    try {
      final String geoJsonData = jsonEncode(<String, Object>{
        'type': 'Feature',
        'geometry': <String, Object>{
          'type': 'Point',
          'coordinates': <double>[
            center.coordinates.lng as double,
            center.coordinates.lat as double
          ],
        },
        'properties': <String, Object>{},
      });

      final GeoJsonSource circleSource = GeoJsonSource(
        id: 'circle-source',
        data: geoJsonData,
      );
      await mapboxMap?.style.addSource(circleSource);

      final CircleLayer circleLayer = CircleLayer(
        id: 'circle-layer',
        sourceId: 'circle-source',
        circleColor: circleColor.value,
        circleOpacity: 0.2,
        circleStrokeWidth: 1,
        circleStrokeColor: strokeColor.value,
      );
      await mapboxMap?.style.addLayer(circleLayer);

      await mapboxMap?.style
          .setStyleLayerProperty('circle-layer', 'circle-radius', <Object>[
        'interpolate',
        <Object>['exponential', 2],
        <String>['zoom'],
        0,
        0,
        20,
        _metersToPixels(center.coordinates.lat as double, radiusInMeters, 20)
      ]);
    } catch (e) {
      // Handle any errors that may occur during drawing
      print('Error drawing circle: $e');
    }
  }

  /// Removes the circle from the map.
  /// 
  /// This method removes the circle layer and source from the map's style.
  Future<void> removeCircle() async {
    try {
      await mapboxMap?.style.removeStyleLayer('circle-layer');
      await mapboxMap?.style.removeStyleSource('circle-source');
    } catch (e) {
      // Handle any errors that may occur during removal
      print('Error removing circle: $e');
    }
  }

  /// Converts meters to pixels at a given latitude and zoom level.
  ///
  /// This method is used to calculate the appropriate circle radius in pixels
  /// based on the map's zoom level and the circle's latitude.
  ///
  /// [latitude]: The latitude of the circle's center.
  /// [meters]: The radius in meters.
  /// [zoomLevel]: The current zoom level of the map.
  ///
  /// Returns the radius in pixels.
  double _metersToPixels(double latitude, double meters, double zoomLevel) {
    return meters /
        (78271.484 / pow(2, zoomLevel)) /
        cos((latitude * pi) / 180);
  }
}

double widthToZoomLevel(double width, num latitude) {
  const double earthCircumference = 40075016.686; // in meters
  const double tileSize = 512; // Mapbox uses 512px tiles by default

  // Convert latitude to radians
  double latRad = latitude * pi / 180;

  // Meters per pixel at zoom level 0 at this latitude
  double metersPerPixelAtZoom0 = earthCircumference * cos(latRad) / tileSize;

  // Calculate zoom level
  double zoom = log(metersPerPixelAtZoom0 / (width / tileSize)) / log(2);

  return zoom;
}