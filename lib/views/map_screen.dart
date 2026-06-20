import 'dart:math';
import 'package:flutter/material.dart';

class ShopLocation {
  final String id;
  final String name;
  final String address;
  final String distance;
  final String phone;
  final bool isOpen;
  final Offset mapCoordinate; // Normalized coordinates (0.0 to 1.0)
  final List<String> directions;

  ShopLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    required this.phone,
    required this.isOpen,
    required this.mapCoordinate,
    required this.directions,
  });
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  ShopLocation? _selectedShop;

  final List<ShopLocation> _shops = [
    ShopLocation(
      id: 'shop-1',
      name: 'Kanto Pokémon Center HCMC',
      address: 'Floor 3, 45 Nguyen Hue St, District 1, Ho Chi Minh City',
      distance: '1.2 km',
      phone: '(028) 3822-2200',
      isOpen: true,
      mapCoordinate: const Offset(0.35, 0.42),
      directions: [
        'Start at your current position (Blue Dot).',
        'Head North on Poke Avenue for 400m.',
        'Turn right at Silph Co. intersection onto Trainer Boulevard.',
        'The Pokémon Center is on the right next to Gym 1.'
      ],
    ),
    ShopLocation(
      id: 'shop-2',
      name: 'Vermilion Deck Vault Hanoi',
      address: '12 Cau Giay Road, Quan Hoa, Cau Giay District, Hanoi',
      distance: '3.8 km',
      phone: '(024) 7300-6000',
      isOpen: true,
      mapCoordinate: const Offset(0.75, 0.28),
      directions: [
        'Head East towards Highway 1 for 1.2km.',
        'Take the exit toward Cau Giay district.',
        'Turn left after the electric charging station.',
        'Shop is located inside the Trainer Arcade, Level 1.'
      ],
    ),
    ShopLocation(
      id: 'shop-3',
      name: 'Pallet Town TCG Boutique',
      address: 'Shop B2, 98 Tran Hung Dao, Pham Ngu Lao Ward, District 1, HCMC',
      distance: '6.5 km',
      phone: '(028) 3911-3000',
      isOpen: false,
      mapCoordinate: const Offset(0.58, 0.75),
      directions: [
        'Head South towards Route 1.',
        'Follow Tran Hung Dao Street for 4.5km.',
        'Make a U-turn at the Pokéball landmark.',
        'Boutique is located directly opposite Professor Oak\'s Lab.'
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _selectedShop = _shops.first;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onMapTap(Offset tapOffset, Size mapSize) {
    // Determine closest shop to tap position
    ShopLocation? closestShop;
    double minDistance = double.infinity;

    for (var shop in _shops) {
      final shopPixelX = shop.mapCoordinate.dx * mapSize.width;
      final shopPixelY = shop.mapCoordinate.dy * mapSize.height;
      final dist = sqrt(pow(tapOffset.dx - shopPixelX, 2) + pow(tapOffset.dy - shopPixelY, 2));

      // Click tolerance radius of 35 logical pixels
      if (dist < 35 && dist < minDistance) {
        minDistance = dist;
        closestShop = shop;
      }
    }

    if (closestShop != null) {
      setState(() {
        _selectedShop = closestShop;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          // Sub-banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF1E1E1E),
            child: const Row(
              children: [
                Icon(Icons.gps_fixed, color: Colors.amber, size: 16),
                SizedBox(width: 8),
                Text(
                  'Physical TCG Store Locations Map & Radar',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // Custom Interactive Map Canvas
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mapSize = Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  onTapUp: (details) => _onMapTap(details.localPosition, mapSize),
                  child: Stack(
                    children: [
                      // Animated custom vector map drawing
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return CustomPaint(
                            size: mapSize,
                            painter: StylizedMapPainter(
                              pulseValue: _pulseController.value,
                              shops: _shops,
                              selectedShop: _selectedShop,
                            ),
                          );
                        },
                      ),
                      
                      // Hint overlay
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: const Text(
                            'TAP markers to navigate',
                            style: TextStyle(color: Colors.white60, fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Slider details card for the selected location
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedShop?.name ?? 'Select a Store Pin',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _selectedShop != null && _selectedShop!.isOpen
                            ? Colors.green.withOpacity(0.15)
                            : Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedShop != null && _selectedShop!.isOpen ? 'Open Now' : 'Closed',
                        style: TextStyle(
                          color: _selectedShop != null && _selectedShop!.isOpen ? Colors.greenAccent : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _selectedShop?.address ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedShop?.distance ?? '',
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Show Route directions
                if (_selectedShop != null) ...[
                  const Text('GPS Steps Navigation:', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    height: 80,
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: _selectedShop!.directions.length,
                      itemBuilder: (context, idx) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${idx + 1}. ', style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(
                                  _selectedShop!.directions[idx],
                                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                
                // Switch store slider
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _shops.length,
                    itemBuilder: (context, index) {
                      final shop = _shops[index];
                      final isSelected = _selectedShop?.id == shop.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(shop.name.split(' ')[0]), // Show short name (e.g. Kanto, Vermilion)
                          selected: isSelected,
                          selectedColor: Colors.amber,
                          backgroundColor: Colors.black26,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _selectedShop = shop;
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StylizedMapPainter extends CustomPainter {
  final double pulseValue;
  final List<ShopLocation> shops;
  final ShopLocation? selectedShop;

  StylizedMapPainter({
    required this.pulseValue,
    required this.shops,
    required this.selectedShop,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Map Background grid
    final bgPaint = Paint()..color = const Color(0xFF161C24);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1.0;
    
    // Draw vertical and horizontal grid lines
    const double gridSize = 30.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Draw mock city elements (e.g., Lake, Park green zone)
    final lakePaint = Paint()
      ..color = const Color(0xFF1D3557).withOpacity(0.4)
      ..style = PaintingStyle.fill;
    
    // Draw a lake at top-right
    final lakePath = Path()
      ..moveTo(size.width * 0.7, 0)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.15, size.width, size.height * 0.1)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(lakePath, lakePaint);

    final parkPaint = Paint()
      ..color = const Color(0xFF2A9D8F).withOpacity(0.2)
      ..style = PaintingStyle.fill;
    // Draw a park at bottom-left
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.65, size.width * 0.35, size.height * 0.35),
      parkPaint,
    );

    // 3. Draw Roads (Streets lines)
    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Major horizontal street
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), roadPaint);
    // Major vertical street
    canvas.drawLine(Offset(size.width * 0.5, 0), Offset(size.width * 0.5, size.height), roadPaint);
    // Diagonal bypass
    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), roadPaint);

    // 4. Draw User Current position pulsing dot (Blue dot in center)
    final Offset userPosition = Offset(size.width * 0.5, size.height * 0.5);
    final userPaintOuter = Paint()
      ..color = Colors.blue.withOpacity(0.2 * (1 - pulseValue))
      ..style = PaintingStyle.fill;
    final userPaintMiddle = Paint()
      ..color = Colors.blue.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    final userPaintInner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Pulse expanding radius up to 24
    canvas.drawCircle(userPosition, 8.0 + 16.0 * pulseValue, userPaintOuter);
    canvas.drawCircle(userPosition, 7.0, userPaintMiddle);
    canvas.drawCircle(userPosition, 3.0, userPaintInner);

    // 5. Draw Navigation Dotted Path to SELECTED store
    if (selectedShop != null) {
      final destX = selectedShop!.mapCoordinate.dx * size.width;
      final destY = selectedShop!.mapCoordinate.dy * size.height;
      final Offset destination = Offset(destX, destY);

      final routePaint = Paint()
        ..color = Colors.amber
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      // Draw dotted path from User center to Shop destination
      // We do a simple L-shaped grid routing to look like city street navigation!
      final path = Path();
      path.moveTo(userPosition.dx, userPosition.dy);
      // Route through center intersection: first horizontal, then vertical
      path.lineTo(destination.dx, userPosition.dy);
      path.lineTo(destination.dx, destination.dy);

      // Custom draw dashed lines on canvas
      final double dashWidth = 5.0;
      final double dashSpace = 4.0;
      double distance = 0.0;
      final pathMetrics = path.computeMetrics();
      for (final metric in pathMetrics) {
        while (distance < metric.length) {
          final double length = min(dashWidth, metric.length - distance);
          final extract = metric.extractPath(distance, distance + length);
          canvas.drawPath(extract, routePaint);
          distance += dashWidth + dashSpace;
        }
      }
    }

    // 6. Draw Shops Pin Markers
    for (var shop in shops) {
      final x = shop.mapCoordinate.dx * size.width;
      final y = shop.mapCoordinate.dy * size.height;
      final isSelected = selectedShop?.id == shop.id;

      final markerColor = isSelected ? Colors.amber : (shop.isOpen ? Colors.green : Colors.red);

      // Glow halo for selected marker
      if (isSelected) {
        final glowPaint = Paint()
          ..color = Colors.amber.withOpacity(0.25 * (1 + 0.3 * sin(pulseValue * 2 * pi)))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 16.0, glowPaint);
      }

      // Marker shape
      final markerPaint = Paint()
        ..color = markerColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 7.0, markerPaint);

      final innerPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 3.0, innerPaint);
      
      // Little pin top triangle/point decoration
      final pinPath = Path()
        ..moveTo(x - 5, y - 4)
        ..lineTo(x, y - 13)
        ..lineTo(x + 5, y - 4)
        ..close();
      canvas.drawPath(pinPath, markerPaint);

      // Label name overlay
      final textSpan = TextSpan(
        text: shop.name.split(' ')[0], // Show short name e.g., Kanto
        style: TextStyle(
          color: isSelected ? Colors.amber : Colors.white60,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 9,
          backgroundColor: Colors.black54,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y + 10));
    }
  }

  @override
  bool shouldRepaint(covariant StylizedMapPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.selectedShop != selectedShop ||
        oldDelegate.shops != shops;
  }
}
