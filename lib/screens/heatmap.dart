import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  List<WeightedLatLng> _heatmapPoints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHeatmapData();
  }

  Future<void> _loadHeatmapData() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/heatmap_data.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);

      setState(() {
        _heatmapPoints = jsonData.map((item) {
          return WeightedLatLng(
            LatLng(item['lat'], item['lng']),
            item['intensity'],
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading heatmap data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final radius = 50.0 + _random.nextDouble() * 100.0;
    final blurFactor = 15.0 + _random.nextDouble() * 25.0;

    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(0, 0), // Center on equator for global view
          initialZoom: 2.0,
        ),
        children: [
          TileLayer(
             urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName:
                    'net.tlserver6y.flutter_map_location_marker.example',
              
          ),
          HeatMapLayer(
            heatMapDataSource: InMemoryHeatMapDataSource(data: _heatmapPoints),
            heatMapOptions: HeatMapOptions(
              radius: radius,
              blurFactor: blurFactor,
              layerOpacity: 1,
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
