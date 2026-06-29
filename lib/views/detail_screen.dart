import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pokemon_card.dart';
import '../viewmodels/cart_viewmodel.dart';
import '../widgets/price_chart.dart';
import '../widgets/three_d_card.dart';
import '../services/tcg_price_service.dart';
import '../services/database_service.dart';

class DetailScreen extends StatefulWidget {
  final PokemonCard card;

  const DetailScreen({super.key, required this.card});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  int _quantity = 1;
  PriceData? _priceData;
  bool _isPriceLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLivePrice();
  }

  Future<void> _fetchLivePrice() async {
    if (widget.card.imageUrl.isEmpty) return;
    setState(() => _isPriceLoading = true);
    try {
      final data = await TcgPriceService.instance.getAndUpdatePriceData(
        widget.card.imageUrl,
        fallbackPriceHistory: widget.card.priceHistory,
      );
      if (mounted) {
        setState(() {
          _priceData = data;
          _isPriceLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isPriceLoading = false);
    }
  }

  Color _getTypeColor() {
    switch (widget.card.type.toLowerCase()) {
      case 'fire':
        return Colors.redAccent.shade700;
      case 'water':
        return Colors.blueAccent.shade400;
      case 'grass':
        return Colors.greenAccent.shade400;
      case 'lightning':
        return Colors.amber;
      case 'psychic':
        return Colors.purpleAccent.shade400;
      case 'dark':
        return Colors.deepPurple;
      case 'colorless':
      default:
        return Colors.blueGrey;
    }
  }

  // Helper to draw a beautiful, offline-compatible Pokeball card back
  Widget _buildCardBack() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B29), // Dark Pokemon Blue
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2B13C), width: 10), // Classic yellow TCG border
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Circular vortex pattern
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.lightBlueAccent.withValues(alpha: 0.2), width: 2),
              ),
            ),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 1.5),
              ),
            ),
            // PokeBall Outer Circle
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.4),
                    blurRadius: 10,
                  )
                ],
              ),
            ),
            // Top Red Half
            ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: 0.5,
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE3350D), // PokeBall Red
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            // Bottom White Half
            ClipRect(
              child: Align(
                alignment: Alignment.bottomCenter,
                heightFactor: 0.5,
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            // PokeBall Center Line Divider
            Container(
              width: 66,
              height: 6,
              color: Colors.black,
            ),
            // Center Button ring
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            // Branding Text
            const Positioned(
              top: 15,
              child: Text(
                'POKÉMON',
                style: TextStyle(
                  color: Color(0xFFE2B13C),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
            ),
            const Positioned(
              bottom: 15,
              child: Text(
                'CARD BACK',
                style: TextStyle(
                  color: Color(0xFF4A90E2),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFront() {
    final typeColor = _getTypeColor();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: const Color(0xFF1E1E1E),
        child: Image.network(
          widget.card.imageUrl,
          fit: BoxFit.fill,
          errorBuilder: (context, error, stackTrace) {
            // Draw a high-fidelity mock front card
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [typeColor.withValues(alpha: 0.8), Colors.black],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.card.name,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'HP ${widget.card.hp}',
                        style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Icon(Icons.style, color: Colors.amber.withValues(alpha: 0.8), size: 100),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Attack: ${widget.card.attackName}',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Damage: ${widget.card.attackDamage}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.card.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white60, fontSize: 10, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = _getTypeColor();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(widget.card.name, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Refresh price',
            icon: _isPriceLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.amber, strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _isPriceLoading
                ? null
                : () {
                    TcgPriceService.instance.clearCache();
                    _fetchLivePrice();
                  },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            
            // 3D Card Interactive Flipping container
            Center(
              child: ThreeDCard(
                front: _buildCardFront(),
                back: _buildCardBack(),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'Double-tap or drag to FLIP card in 3D!',
                style: TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 20),

            // Card statistics & metadata card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.card.name,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: cardColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: cardColor, width: 1),
                          ),
                          child: Text(
                            widget.card.type,
                            style: TextStyle(color: cardColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.card.rarity,
                          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.card.stockQuantity > 0 ? Colors.green.shade900.withValues(alpha: 0.5) : Colors.red.shade900.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: widget.card.stockQuantity > 0 ? Colors.greenAccent : Colors.redAccent, width: 1),
                          ),
                          child: Text(
                            widget.card.stockQuantity > 0 ? 'In Stock' : 'Out of Stock',
                            style: TextStyle(
                              color: widget.card.stockQuantity > 0 ? Colors.greenAccent : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 8),
                    
                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatTile('HP', '${widget.card.hp}', Colors.redAccent),
                        _buildStatTile('Weakness', widget.card.weakness, Colors.lightBlue),
                        _buildStatTile('Retreat Cost', '${widget.card.retreatCost}★', Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Attacks details
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Attack: ${widget.card.attackName}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              const Text('Active moveset', style: TextStyle(color: Colors.white38, fontSize: 10)),
                            ],
                          ),
                          Text(
                            '${widget.card.attackDamage} DMG',
                            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Description
                    Text(
                      widget.card.description,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Price Chart widget
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: PriceChart(
                prices: widget.card.priceHistory,
                pokemonType: widget.card.type,
                priceData: _priceData,
                isLoading: _isPriceLoading,
              ),
            ),
            const SizedBox(height: 24),

            // Public Reviews Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildReviewsList(),
            ),
            
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomSheet: Container(
        color: const Color(0xFF1E1E1E),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Quantity buttons
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, color: Colors.white),
                    onPressed: () {
                      if (_quantity > 1) {
                        setState(() {
                          _quantity--;
                        });
                      }
                    },
                  ),
                  Text(
                    '$_quantity',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _quantity++;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // Add To Cart button
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.card.stockQuantity > 0 ? Colors.amber : Colors.grey.shade700,
                    foregroundColor: widget.card.stockQuantity > 0 ? Colors.black : Colors.white54,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: widget.card.stockQuantity > 0 ? () {
                    context.read<CartViewModel>().addToCart(widget.card, quantity: _quantity);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added ${_quantity}x ${widget.card.name} to cart!'),
                        backgroundColor: Colors.indigo,
                      ),
                    );
                    Navigator.of(context).pop();
                  } : null,
                  child: Text(
                    widget.card.stockQuantity > 0 ? 'ADD TO CART' : 'OUT OF STOCK',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildReviewsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trainer Reviews',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: DatabaseService.instance.getCardReviews(widget.card.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.amber));
            }

            final reviews = snapshot.data ?? [];

            if (reviews.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'No reviews yet for this card. Be the first to buy and review!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final review = reviews[index];
                final double rating = (review['rating'] as num?)?.toDouble() ?? 5.0;
                final String name = review['user_name'] ?? 'Anonymous Trainer';
                final String feedback = review['feedback'] ?? '';
                
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Row(
                            children: List.generate(5, (starIndex) {
                              return Icon(
                                starIndex < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: Colors.amber,
                                size: 14,
                              );
                            }),
                          ),
                        ],
                      ),
                      if (feedback.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          feedback,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
