import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_api_availability/google_api_availability.dart';
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
  bool _isCheckingPlayServices = false;
  bool _isPlayServicesAvailable = true;
  String? _playServicesMessage;

  LatLng get _initialCameraTarget => widget.initialPosition ?? _defaultCenter;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
    _checkGooglePlayServices();
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

  Future<void> _checkGooglePlayServices() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    setState(() {
      _isCheckingPlayServices = true;
    });

    try {
      final availability = await GoogleApiAvailability.instance
          .checkGooglePlayServicesAvailability();
      final available = availability == GooglePlayServicesAvailability.success ||
          availability == GooglePlayServicesAvailability.serviceUpdating;

      if (!mounted) return;
      setState(() {
        _isCheckingPlayServices = false;
        _isPlayServicesAvailable = available;
        _playServicesMessage = available
            ? null
            : _availabilityMessage(availability);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isCheckingPlayServices = false;
        _isPlayServicesAvailable = false;
        _playServicesMessage =
            'Google Play Hizmetleri kontrol edilirken bir hata oluştu. Lütfen daha sonra tekrar deneyin.';
      });
    }
  }

  String _availabilityMessage(GooglePlayServicesAvailability availability) {
    switch (availability) {
      case GooglePlayServicesAvailability.serviceMissing:
      case GooglePlayServicesAvailability.serviceMissingPermission:
        return 'Google Play Hizmetleri bu cihazda mevcut değil. Haritayı kullanmak için Play Hizmetleri yükleyin veya güncelleyin.';
      case GooglePlayServicesAvailability.serviceVersionUpdateRequired:
        return 'Harita özelliğini kullanmak için Google Play Hizmetleri uygulamasını güncellemeniz gerekiyor.';
      case GooglePlayServicesAvailability.serviceDisabled:
        return 'Google Play Hizmetleri devre dışı bırakılmış. Lütfen etkinleştirdikten sonra tekrar deneyin.';
      case GooglePlayServicesAvailability.serviceInvalid:
        return 'Google Play Hizmetleri bu cihazda desteklenmiyor. Lütfen uyumlu bir cihaz veya emülatör kullanın.';
      default:
        return 'Harita hizmetine şu anda erişilemiyor. Lütfen Google Play Hizmetleri bulunan bir cihazda tekrar deneyin.';
    }
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
            onPressed:
                _isPlayServicesAvailable ? _confirmSelection : null,
            child: const Text('Kaydet'),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _isCheckingPlayServices
                ? const Center(child: CircularProgressIndicator())
                : _isPlayServicesAvailable
                    ? GoogleMap(
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
                      )
                    : _UnavailableMapInfo(message: _playServicesMessage),
          ),
          if (_isPlayServicesAvailable && !_isCheckingPlayServices)
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

class _UnavailableMapInfo extends StatelessWidget {
  final String? message;

  const _UnavailableMapInfo({this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.map_off_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Harita yüklenemedi',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message ??
                  'Bu cihazda Google Play Hizmetleri bulunmadığı için harita gösterilemiyor. Lütfen Play Hizmetleri içeren bir cihaz veya emülatör kullanın.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Geri dön'),
            ),
          ],
        ),
      ),
    );
  }
}
