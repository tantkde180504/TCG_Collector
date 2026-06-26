import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// ─────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────
class ShopLocation {
  final String id;
  final String name;
  final String address;
  final String phone;
  final bool isOpen;
  final LatLng latLng;
  final String hours;

  // Computed at runtime
  double? distanceMeters;

  ShopLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.isOpen,
    required this.latLng,
    required this.hours,
  });

  String get distanceLabel {
    if (distanceMeters == null) return '—';
    if (distanceMeters! < 1000) {
      return '${distanceMeters!.toStringAsFixed(0)} m';
    }
    return '${(distanceMeters! / 1000).toStringAsFixed(1)} km';
  }
}

// ─────────────────────────────────────────────
// Store data (real coordinates in Vietnam)
// ─────────────────────────────────────────────
final List<ShopLocation> _defaultShops = [
  ShopLocation(
    id: 'shop-1',
    name: 'Kanto Pokémon Center HCMC',
    address: 'Tầng 3, 45 Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh',
    phone: '(028) 3822-2200',
    isOpen: true,
    latLng: const LatLng(10.7769, 106.7009),
    hours: '09:00 – 22:00',
  ),
  ShopLocation(
    id: 'shop-2',
    name: 'Vermilion Deck Vault Hà Nội',
    address: '12 Cầu Giấy, Quan Hoa, Cầu Giấy, Hà Nội',
    phone: '(024) 7300-6000',
    isOpen: true,
    latLng: const LatLng(21.0285, 105.8542),
    hours: '10:00 – 21:30',
  ),
  ShopLocation(
    id: 'shop-3',
    name: 'Pallet Town TCG Boutique',
    address: 'Shop B2, 98 Trần Hưng Đạo, Phạm Ngũ Lão, Quận 1, HCMC',
    phone: '(028) 3911-3000',
    isOpen: false,
    latLng: const LatLng(10.7694, 106.6905),
    hours: '10:00 – 20:00 (Đóng hôm nay)',
  ),
  ShopLocation(
    id: 'shop-4',
    name: 'Magikarp Card Shop Đà Nẵng',
    address: '55 Nguyễn Văn Linh, Hải Châu, Đà Nẵng',
    phone: '(0236) 3822-100',
    isOpen: true,
    latLng: const LatLng(16.0544, 108.2022),
    hours: '09:00 – 21:00',
  ),
];

// ─────────────────────────────────────────────
// MapScreen Widget
// ─────────────────────────────────────────────
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final List<ShopLocation> _shops = List.from(_defaultShops);

  ShopLocation? _selectedShop;
  LatLng? _userPosition;
  List<LatLng> _routePoints = [];

  bool _isLocating = false;
  bool _isFetchingRoute = false;
  String? _locationError;

  // Pulse animation for user dot
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_pulseController);
    _selectedShop = _shops.first;
    _getUserLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── GPS ────────────────────────────────────
  Future<void> _getUserLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    try {
      // Check & request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError =
              'Quyền vị trí bị từ chối vĩnh viễn.\nVui lòng bật trong Cài đặt.';
          _isLocating = false;
        });
        return;
      }
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationError = 'Cần quyền vị trí để tìm cửa hàng gần nhất.';
          _isLocating = false;
        });
        return;
      }

      // Check service enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Dịch vụ vị trí chưa được bật.';
          _isLocating = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final userLatLng = LatLng(position.latitude, position.longitude);

      // Calculate real distances to all shops
      for (final shop in _shops) {
        shop.distanceMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          shop.latLng.latitude,
          shop.latLng.longitude,
        );
      }

      // Sort by distance
      _shops.sort((a, b) => (a.distanceMeters ?? double.infinity)
          .compareTo(b.distanceMeters ?? double.infinity));

      setState(() {
        _userPosition = userLatLng;
        _selectedShop = _shops.first; // nearest shop
        _isLocating = false;
      });

      // Fly camera to show both user and nearest shop
      _flyToFitBounds(userLatLng, _shops.first.latLng);

      // Fetch route to nearest shop
      await _fetchRoute(_shops.first);
    } catch (e) {
      setState(() {
        _locationError = 'Không thể lấy vị trí: $e';
        _isLocating = false;
      });
    }
  }

  // ── Camera ─────────────────────────────────
  void _flyToFitBounds(LatLng a, LatLng b) {
    final minLat = min(a.latitude, b.latitude);
    final maxLat = max(a.latitude, b.latitude);
    final minLng = min(a.longitude, b.longitude);
    final maxLng = max(a.longitude, b.longitude);

    final center = LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );

    // Simple zoom calculation based on span
    final latSpan = maxLat - minLat;
    final lngSpan = maxLng - minLng;
    final span = max(latSpan, lngSpan);

    double zoom;
    if (span > 5) {
      zoom = 5;
    } else if (span > 2) {
      zoom = 7;
    } else if (span > 1) {
      zoom = 9;
    } else if (span > 0.5) {
      zoom = 11;
    } else if (span > 0.1) {
      zoom = 12;
    } else {
      zoom = 14;
    }

    _mapController.move(center, zoom);
  }

  // ── OSRM Routing ───────────────────────────
  Future<void> _fetchRoute(ShopLocation shop) async {
    if (_userPosition == null) return;

    setState(() {
      _isFetchingRoute = true;
      _routePoints = [];
    });

    try {
      final origin =
          '${_userPosition!.longitude},${_userPosition!.latitude}';
      final dest = '${shop.latLng.longitude},${shop.latLng.latitude}';
      final url =
          'https://router.project-osrm.org/route/v1/driving/$origin;$dest'
          '?overview=full&geometries=geojson';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final coords =
            data['routes'][0]['geometry']['coordinates'] as List<dynamic>;
        final points = coords
            .map((c) => LatLng(c[1] as double, c[0] as double))
            .toList();

        setState(() {
          _routePoints = points;
          _isFetchingRoute = false;
        });
      } else {
        _setFallbackRoute(shop);
      }
    } catch (_) {
      _setFallbackRoute(shop);
    }
  }

  void _setFallbackRoute(ShopLocation shop) {
    setState(() {
      _routePoints = _userPosition != null
          ? [_userPosition!, shop.latLng]
          : [shop.latLng];
      _isFetchingRoute = false;
    });
  }

  // ── Select shop ────────────────────────────
  Future<void> _selectShop(ShopLocation shop) async {
    setState(() {
      _selectedShop = shop;
      _routePoints = [];
    });
    _mapController.move(shop.latLng, 15.0);
    await _fetchRoute(shop);
  }

  // ── Find Nearest ───────────────────────────
  Future<void> _findNearest() async {
    if (_userPosition == null) {
      await _getUserLocation();
      return;
    }
    final nearest = _shops.first; // Already sorted by distance
    await _selectShop(nearest);
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          _buildTopBanner(),
          Expanded(child: _buildMap()),
          _buildBottomPanel(),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'find_nearest',
            onPressed: _isLocating ? null : _findNearest,
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            icon: _isLocating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Icon(Icons.my_location),
            label: Text(
              _isLocating ? 'Đang định vị…' : 'Tìm gần nhất',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          if (_userPosition != null)
            FloatingActionButton.small(
              heroTag: 'center_me',
              onPressed: () => _mapController.move(_userPosition!, 14),
              backgroundColor: const Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              child: const Icon(Icons.person_pin_circle),
            ),
        ],
      ),
    );
  }

  // ── Top Banner ─────────────────────────────
  Widget _buildTopBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF1E1E1E),
      child: Row(
        children: [
          const Icon(Icons.gps_fixed, color: Colors.amber, size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Bản đồ Cửa hàng TCG – Định vị GPS Thực',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_isFetchingRoute)
            const Row(
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Colors.amber,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  'Đang tính đường…',
                  style: TextStyle(color: Colors.amber, fontSize: 10),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ── Map ────────────────────────────────────
  Widget _buildMap() {
    const defaultCenter = LatLng(10.7769, 106.7009);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _selectedShop?.latLng ?? defaultCenter,
            initialZoom: 13.0,
            minZoom: 3,
            maxZoom: 18,
          ),
          children: [
            // OSM tile layer
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.tcg',
              retinaMode: false,
            ),

            // Route polyline
            if (_routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 4.0,
                    color: Colors.amber.withValues(alpha: 0.85),
                    borderStrokeWidth: 6.0,
                    borderColor: Colors.orange.withValues(alpha: 0.3),
                  ),
                ],
              ),

            // Shop markers
            MarkerLayer(
              markers: _shops.map((shop) {
                final isSelected = _selectedShop?.id == shop.id;
                return Marker(
                  point: shop.latLng,
                  width: isSelected ? 48 : 36,
                  height: isSelected ? 56 : 44,
                  child: GestureDetector(
                    onTap: () => _selectShop(shop),
                    child: _buildShopMarker(shop, isSelected),
                  ),
                );
              }).toList(),
            ),

            // User location marker
            if (_userPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _userPosition!,
                    width: 56,
                    height: 56,
                    child: _buildUserMarker(),
                  ),
                ],
              ),
          ],
        ),

        // Location error banner
        if (_locationError != null)
          Positioned(
            top: 8,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _locationError!,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.white, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () =>
                        setState(() => _locationError = null),
                  ),
                ],
              ),
            ),
          ),

        // Map attribution
        Positioned(
          bottom: 4,
          right: 8,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '© OpenStreetMap contributors',
              style: TextStyle(color: Colors.white54, fontSize: 8),
            ),
          ),
        ),
      ],
    );
  }

  // ── Shop Pin Marker ─────────────────────────
  Widget _buildShopMarker(ShopLocation shop, bool isSelected) {
    final color = isSelected
        ? Colors.amber
        : (shop.isOpen ? const Color(0xFF4CAF50) : Colors.redAccent);

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulse ring for selected
            if (isSelected)
              Container(
                width: 48 * (0.85 + 0.15 * _pulseAnim.value),
                height: 48 * (0.85 + 0.15 * _pulseAnim.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber
                      .withValues(alpha: 0.3 * (1 - _pulseAnim.value)),
                ),
              ),
            // Pin icon
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isSelected ? 32 : 26,
                  height: isSelected ? 32 : 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: isSelected ? 12 : 6,
                        spreadRadius: isSelected ? 2 : 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.storefront,
                    color: isSelected ? Colors.black : Colors.white,
                    size: isSelected ? 18 : 14,
                  ),
                ),
                CustomPaint(
                  size: Size(isSelected ? 10 : 8, isSelected ? 8 : 6),
                  painter: TrianglePainter(color),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ── User GPS Marker ─────────────────────────
  Widget _buildUserMarker() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse
            Container(
              width: 56 * (0.5 + 0.5 * _pulseAnim.value),
              height: 56 * (0.5 + 0.5 * _pulseAnim.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue
                    .withValues(alpha: 0.2 * (1 - _pulseAnim.value)),
              ),
            ),
            // Inner accuracy ring
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withValues(alpha: 0.25),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
            ),
            // Dot
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.blue,
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Bottom Panel ───────────────────────────
  Widget _buildBottomPanel() {
    final shop = _selectedShop;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          if (shop == null)
            const Center(
              child: Text(
                'Chọn một cửa hàng trên bản đồ',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            )
          else ...[
            // Header row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: shop.isOpen
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.red.withValues(alpha: 0.15),
                    border: Border.all(
                      color: shop.isOpen
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.storefront,
                    color: shop.isOpen
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        shop.hours,
                        style: TextStyle(
                          color: shop.isOpen
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Distance badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.straighten,
                          color: Colors.black, size: 12),
                      Text(
                        shop.distanceLabel,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Address
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    shop.address,
                    style:
                        const TextStyle(color: Colors.white60, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Phone
            Row(
              children: [
                const Icon(Icons.phone_outlined,
                    color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Text(
                  shop.phone,
                  style:
                      const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Route info
            if (_routePoints.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car,
                        color: Colors.amber, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Đường đi theo phố thực tế đang hiển thị trên bản đồ',
                      style: TextStyle(
                        color: Colors.amber.shade200,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            if (_isFetchingRoute)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.amber,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Đang tải đường đi từ OSRM…',
                      style:
                          TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 10),

            // Shop chips
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _shops.length,
                separatorBuilder: (_, idx) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final s = _shops[index];
                  final sel = _selectedShop?.id == s.id;
                  return GestureDetector(
                    onTap: () => _selectShop(s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel
                            ? Colors.amber
                            : Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: sel ? Colors.amber : Colors.white12,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: s.isOpen
                                  ? (sel
                                      ? Colors.green.shade800
                                      : Colors.greenAccent)
                                  : (sel
                                      ? Colors.red.shade800
                                      : Colors.redAccent),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            s.name.split(' ')[0],
                            style: TextStyle(
                              color: sel ? Colors.black : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          if (s.distanceMeters != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              s.distanceLabel,
                              style: TextStyle(
                                color: sel
                                    ? Colors.black54
                                    : Colors.white38,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Helper: triangle CustomPainter for pin tip
// Uses dart:ui.Path explicitly to avoid conflict with latlong2.Path
// ─────────────────────────────────────────────
class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TrianglePainter old) => old.color != color;
}
