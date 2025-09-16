import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:latlong2/latlong.dart';

class HeatmapPage extends StatefulWidget {
  const HeatmapPage({super.key});
  @override
  State<HeatmapPage> createState() => _HeatmapPageState();
}

class _HeatmapPageState extends State<HeatmapPage> {
  final Random _random = Random();

  List<WeightedLatLng> _generateRandomPoints() {
    return List.generate(1000, (index) {
      // Random locations all over the world
      final lat = -90.0 + _random.nextDouble() * 180.0; // -90 to 90
      final lng = -180.0 + _random.nextDouble() * 360.0; // -180 to 180

      // Random intensity for full gradient visibility
      final intensity = 0.1 + _random.nextDouble() * 0.9;

      return WeightedLatLng(LatLng(lat, lng), intensity);
    });
  }

  @override
  Widget build(BuildContext context) {
    final heatmapPoints = _generateRandomPoints();
    final radius = 50.0 + _random.nextDouble() * 100.0;
    final blurFactor = 15.0 + _random.nextDouble() * 25.0;

    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(0, 0), // Center on equator for global view
          initialZoom: 2.0, // Zoom out to see worldwide patches
        ),
        children: [
          TileLayer(
            urlTemplate:
                "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
            subdomains: const ['a', 'b', 'c', 'd'],
            userAgentPackageName: 'com.example.app',
          ),
          HeatMapLayer(
            heatMapDataSource: InMemoryHeatMapDataSource(data: heatmapPoints),
            heatMapOptions: HeatMapOptions(
              radius: radius,
              blurFactor: blurFactor,
              layerOpacity: 0.7,
              gradient: {
                0.0: Colors.blue,
                0.2: Colors.green,
                0.4: Colors.yellow,
                0.7: Colors.orange,
                1.0: Colors.red,
              },
              minOpacity: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
