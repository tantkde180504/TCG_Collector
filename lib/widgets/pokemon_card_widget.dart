import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pokemon_card.dart';
import '../viewmodels/cart_viewmodel.dart';
import '../views/detail_screen.dart';
import 'glowing_border.dart';

class PokemonCardWidget extends StatelessWidget {
  final PokemonCard card;

  const PokemonCardWidget({super.key, required this.card});

  Color _getTypeColor() {
    switch (card.type.toLowerCase()) {
      case 'fire':
        return Colors.red.shade900;
      case 'water':
        return Colors.blue.shade900;
      case 'grass':
        return Colors.green.shade900;
      case 'lightning':
        return Colors.amber.shade800;
      case 'psychic':
        return Colors.purple.shade900;
      case 'dark':
        return Colors.deepPurple.shade900;
      case 'colorless':
      default:
        return Colors.blueGrey.shade900;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor();

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DetailScreen(card: card),
          ),
        );
      },
      child: GlowingBorder(
        pokemonType: card.type,
        borderRadius: 12.0,
        borderWidth: 1.5,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card Image Header
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.2),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Image with clean fallback
                      Image.network(
                        card.imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          // Beautiful card fallback in case network image fails
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [typeColor.withOpacity(0.8), Colors.black87],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.withOpacity(0.5)),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.style, color: Colors.amber.withOpacity(0.8), size: 36),
                                  const SizedBox(height: 4),
                                  Text(
                                    card.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    card.type,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      // Rarity tag
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.amber.withOpacity(0.5), width: 0.5),
                          ),
                          child: Text(
                            card.rarity,
                            style: const TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Card details
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          card.type,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          'HP ${card.hp}',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${card.marketPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        // Quick Add button
                        Material(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(6),
                          child: InkWell(
                            onTap: () {
                              context.read<CartViewModel>().addToCart(card);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added ${card.name} to cart!'),
                                  duration: const Duration(seconds: 1),
                                  backgroundColor: Colors.indigo,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Icon(
                                Icons.add_shopping_cart,
                                size: 14,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
