import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/app_widgets.dart';
import '../screens/salon_detail_screen.dart';

class SalonsMapScreen extends StatefulWidget {
  final List<dynamic> salons;
  final double? userLat;
  final double? userLng;
  final int userId;

  const SalonsMapScreen({
    super.key,
    required this.salons,
    this.userLat,
    this.userLng,
    required this.userId,
  });

  @override
  State<SalonsMapScreen> createState() => _SalonsMapScreenState();
}

class _SalonsMapScreenState extends State<SalonsMapScreen> {
  GoogleMapController? _mapController;
  Map<String, dynamic>? _selectedSalon;
  Set<Marker> _markers = {};
  bool _mapError = false;
  bool _mapReady = false;

  static const LatLng _defaultCenter = LatLng(41.0082, 28.9784);

  @override
  void initState() {
    super.initState();
    _buildMarkers();
  }

  void _buildMarkers() {
    final markers = <Marker>{};

    if (widget.userLat != null && widget.userLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(widget.userLat!, widget.userLng!),
          infoWindow: const InfoWindow(title: 'Konumunuz'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure),
        ),
      );
    }

    for (final salon in widget.salons) {
      final lat = salon['latitude'];
      final lng = salon['longitude'];
      if (lat == null || lng == null) continue;

      final latVal = (lat as num).toDouble();
      final lngVal = (lng as num).toDouble();
      final salonId = salon['id'].toString();

      markers.add(
        Marker(
          markerId: MarkerId(salonId),
          position: LatLng(latVal, lngVal),
          infoWindow: InfoWindow(title: salon['name'] ?? 'Salon'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange),
          onTap: () {
            setState(
                () => _selectedSalon = Map<String, dynamic>.from(salon));
          },
        ),
      );
    }

    setState(() => _markers = markers);
  }

  LatLng get _initialCenter {
    if (widget.userLat != null && widget.userLng != null) {
      return LatLng(widget.userLat!, widget.userLng!);
    }
    for (final salon in widget.salons) {
      final lat = salon['latitude'];
      final lng = salon['longitude'];
      if (lat != null && lng != null) {
        return LatLng((lat as num).toDouble(), (lng as num).toDouble());
      }
    }
    return _defaultCenter;
  }

  void _goToMyLocation() {
    if (_mapController == null) return;
    if (widget.userLat != null && widget.userLng != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(widget.userLat!, widget.userLng!),
          14,
        ),
      );
    }
  }

  int get _salonsWithCoords => widget.salons.where((s) {
        return s['latitude'] != null && s['longitude'] != null;
      }).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: Text(
          '$_salonsWithCoords salon bulundu',
          style: const TextStyle(fontSize: 16),
        ),
        elevation: 0,
      ),
      body: _mapError ? _buildErrorView() : _buildMapView(),
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.map_outlined, size: 80, color: AppColors.muted),
          const SizedBox(height: 16),
          const Text(
            'Harita yüklenemedi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Google Maps bu ortamda desteklenmiyor. '
            'Gerçek bir Android/iOS cihazda deneyin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: widget.salons.length,
              itemBuilder: (_, i) =>
                  _buildSalonListTile(widget.salons[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        _buildGoogleMap(),
        if (!_mapReady)
          const Center(
            child:
                CircularProgressIndicator(color: AppColors.accent),
          ),
        if (_mapReady &&
            widget.userLat != null &&
            widget.userLng != null)
          Positioned(
            bottom: _selectedSalon != null ? 200 : 24,
            right: 16,
            child: FloatingActionButton.small(
              backgroundColor: AppColors.primary,
              onPressed: _goToMyLocation,
              child:
                  const Icon(Icons.my_location, color: AppColors.white),
            ),
          ),
        if (_selectedSalon != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildSalonCard(_selectedSalon!),
          ),
      ],
    );
  }

  Widget _buildGoogleMap() {
    try {
      return GoogleMap(
        onMapCreated: (controller) {
          setState(() {
            _mapController = controller;
            _mapReady = true;
          });
        },
        initialCameraPosition: CameraPosition(
          target: _initialCenter,
          zoom: 13,
        ),
        markers: _markers,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
        onTap: (_) {
          if (_selectedSalon != null) {
            setState(() => _selectedSalon = null);
          }
        },
      );
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _mapError = true);
      });
      return const SizedBox.shrink();
    }
  }

  Widget _buildSalonCard(Map<String, dynamic> salon) {
    final name = salon['name'] ?? 'Salon';
    final address = salon['address'] ?? '';
    final distanceKm = salon['distanceKm'];
    final salonId = salon['id'] ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SalonDetailScreen(
              salonId: salonId,
              userId: widget.userId,
              salonName: name,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.content_cut,
                  color: AppColors.accent, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  if (address.isNotEmpty)
                    Text(address,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.muted)),
                  if (distanceKm != null)
                    Text(
                      '📍 ${(distanceKm as double).toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Detay',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalonListTile(Map<String, dynamic> salon) {
    return ListTile(
      leading:
          const Icon(Icons.content_cut, color: AppColors.accent),
      title: Text(salon['name'] ?? ''),
      subtitle: Text(salon['address'] ?? ''),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SalonDetailScreen(
              salonId: salon['id'] ?? 0,
              userId: widget.userId,
              salonName: salon['name'] ?? '',
            ),
          ),
        );
      },
    );
  }
}