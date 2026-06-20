import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/catalog_viewmodel.dart';
import '../viewmodels/cart_viewmodel.dart';
import '../viewmodels/notification_viewmodel.dart';
import '../widgets/pokemon_card_widget.dart';
import 'cart_screen.dart';
import 'map_screen.dart';
import 'chat_screen.dart';
import 'notification_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Search input state
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Active pages list
  final List<Widget> _pages = [
    const ShopCatalogView(),
    const MapScreen(),
    const ChatScreen(),
    const CartScreen(),
    const NotificationScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cartVM = context.watch<CartViewModel>();
    final notifVM = context.watch<NotificationViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.catching_pokemon, color: Colors.amber, size: 28),
            const SizedBox(width: 8),
            Text(
              _currentIndex == 0
                  ? 'PokeTCG Shop'
                  : _currentIndex == 1
                      ? 'TCG Radar'
                      : _currentIndex == 2
                          ? 'Trainer Support'
                          : _currentIndex == 3
                              ? 'My Cart'
                              : 'Notifications',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          // Quick logout button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () {
              context.read<AuthViewModel>().logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.white60,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Shop',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Support',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                if (cartVM.items.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '${cartVM.items.fold(0, (sum, i) => sum + i.quantity)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (notifVM.unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '${notifVM.unreadCount}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }
}

class ShopCatalogView extends StatefulWidget {
  const ShopCatalogView({super.key});

  @override
  State<ShopCatalogView> createState() => _ShopCatalogViewState();
}

class _ShopCatalogViewState extends State<ShopCatalogView> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _types = [
    'All',
    'Fire',
    'Water',
    'Grass',
    'Lightning',
    'Psychic',
    'Dark',
    'Colorless'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogVM = context.watch<CatalogViewModel>();
    final authVM = context.watch<AuthViewModel>();

    return Column(
      children: [
        // Welcome Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${authVM.displayName}!',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Text(
                'Explore and collect genuine rare cards today.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              
              // Search Input Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E2E2E),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        onChanged: (val) {
                          catalogVM.setSearchQuery(val);
                        },
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search, color: Colors.white54, size: 18),
                          hintText: 'Search cards, attacks, specs...',
                          hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Sorting selection
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E2E2E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButton<String>(
                      value: catalogVM.sortBy,
                      dropdownColor: const Color(0xFF1E1E1E),
                      underline: const SizedBox(),
                      icon: const Icon(Icons.sort, color: Colors.amber, size: 18),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      items: const [
                        DropdownMenuItem(value: 'Name', child: Text('Sort: A-Z')),
                        DropdownMenuItem(value: 'PriceAsc', child: Text('Price: Low-High')),
                        DropdownMenuItem(value: 'PriceDesc', child: Text('Price: High-Low')),
                        DropdownMenuItem(value: 'HP', child: Text('Sort: HP')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          catalogVM.setSortOption(val);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Horizontal Type filters
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _types.length,
            itemBuilder: (context, index) {
              final type = _types[index];
              final isSelected = catalogVM.selectedType.toLowerCase() == type.toLowerCase();
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  selectedColor: Colors.amber,
                  backgroundColor: const Color(0xFF1E1E1E),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) {
                      catalogVM.setTypeFilter(type);
                    }
                  },
                ),
              );
            },
          ),
        ),
        
        // Grid cards loader
        Expanded(
          child: catalogVM.isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.amber))
              : catalogVM.cards.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.white30),
                          SizedBox(height: 8),
                          Text('No trainer cards found matching criteria.', style: TextStyle(color: Colors.white30)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.64,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: catalogVM.cards.length,
                      itemBuilder: (context, index) {
                        return PokemonCardWidget(card: catalogVM.cards[index]);
                      },
                    ),
        ),
      ],
    );
  }
}
