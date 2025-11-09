import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialPosition;
  const LocationPickerScreen({super.key, this.initialPosition});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const LatLng _defaultCenter = LatLng(39.925533, 32.866287); // Ankara

  GoogleMapController? _controller;
  LatLng? _selectedPosition;

  LatLng get _initialCameraTarget => widget.initialPosition ?? _defaultCenter;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedPosition = position;
    });
  }

  void _confirmSelection() {
    if (_selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen haritada bir konum seçin.')),
      );
      return;
    }
    Navigator.of(context).pop(_selectedPosition);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final marker = _selectedPosition == null
        ? <Marker>{}
        : {
            Marker(
              markerId: const MarkerId('selected'),
              position: _selectedPosition!,
            ),
          };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konum Seç'),
        actions: [
          TextButton(
            onPressed: _confirmSelection,
            child: const Text('Kaydet'),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialCameraTarget,
              zoom: widget.initialPosition != null ? 14 : 10,
            ),
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            markers: marker,
            onTap: _onMapTap,
            onMapCreated: (controller) {
              _controller = controller;
              if (_selectedPosition != null) {
                controller.moveCamera(
                  CameraUpdate.newLatLng(_selectedPosition!),
                );
              }
            },
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: theme.colorScheme.surface.withOpacity(0.92),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedPosition != null
                            ? 'Seçilen Konum: '
                                '${_selectedPosition!.latitude.toStringAsFixed(5)}, '
                                '${_selectedPosition!.longitude.toStringAsFixed(5)}'
                            : 'Haritaya dokunarak ilan konumunu seçin.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _confirmSelection,
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Onayla'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
