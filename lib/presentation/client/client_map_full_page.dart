import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/widgets/dynamic_map.dart';

class ClientMapFullPage extends StatelessWidget {
  const ClientMapFullPage({super.key});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).viewPadding.top;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: DynamicMap(
              initialPosition: LatLng(-6.200000, 106.816666),
              initialZoom: 13,
            ),
          ),
          Positioned(
            top: topInset + 12,
            left: 12,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


