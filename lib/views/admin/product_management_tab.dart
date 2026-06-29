import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/catalog_viewmodel.dart';
import '../../services/database_service.dart';
import '../../models/pokemon_card.dart';

class ProductManagementTab extends StatelessWidget {
  const ProductManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    final catalogVM = context.watch<CatalogViewModel>();
    final cards = catalogVM.cards;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm sản phẩm...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (value) => catalogVM.setSearchQuery(value),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              final isOutOfStock = card.stockQuantity == 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                color: const Color(0xFF1E1E1E),
                child: ListTile(
                  leading: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          card.imageUrl,
                          width: 40,
                          height: 55,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(Icons.image, size: 40),
                        ),
                      ),
                      if (isOutOfStock)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.red.shade900.withOpacity(0.85),
                            padding: const EdgeInsets.symmetric(vertical: 1),
                            child: const Text(
                              'HẾT',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    card.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isOutOfStock ? Colors.white54 : Colors.white,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${card.type} · ${card.rarity}', style: const TextStyle(fontSize: 11)),
                      Row(
                        children: [
                          Icon(
                            isOutOfStock ? Icons.inventory_2_outlined : Icons.inventory_2,
                            size: 12,
                            color: isOutOfStock ? Colors.redAccent : Colors.greenAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOutOfStock ? 'Hết hàng' : 'Còn hàng: ${card.stockQuantity}',
                            style: TextStyle(
                              color: isOutOfStock ? Colors.redAccent : Colors.greenAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Quick stock toggle button
                      IconButton(
                        icon: Icon(
                          isOutOfStock ? Icons.add_box_outlined : Icons.inventory_2_outlined,
                          color: isOutOfStock ? Colors.greenAccent : Colors.orangeAccent,
                        ),
                        tooltip: isOutOfStock ? 'Đặt lại còn hàng (50)' : 'Cập nhật số lượng',
                        onPressed: () => _showStockDialog(context, card),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => ProductManagementTab.showProductDialog(context, card),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, card),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Dialog chỉnh số lượng tồn kho nhanh
  void _showStockDialog(BuildContext context, PokemonCard card) {
    final controller = TextEditingController(text: card.stockQuantity.toString());

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Row(
          children: [
            const Icon(Icons.inventory_2, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cập nhật tồn kho',
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(card.name, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Số lượng tồn kho',
                labelStyle: const TextStyle(color: Colors.white54),
                helperText: 'Nhập 0 để đánh dấu hết hàng',
                helperStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.amber),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Quick-set buttons
            Wrap(
              spacing: 8,
              children: [0, 10, 25, 50, 100].map((qty) => ActionChip(
                label: Text(qty == 0 ? 'Hết hàng' : '$qty'),
                backgroundColor: qty == 0 ? Colors.red.shade900 : const Color(0xFF2C2C2C),
                labelStyle: TextStyle(
                  color: qty == 0 ? Colors.redAccent : Colors.white70,
                  fontSize: 11,
                ),
                onPressed: () => controller.text = qty.toString(),
              )).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final qty = int.tryParse(controller.text) ?? 0;
              await DatabaseService.instance.updateCardStock(card.id, qty);
              if (context.mounted) {
                // Update in-memory instantly without re-fetching from network
                context.read<CatalogViewModel>().updateCardStockInMemory(card.id, qty);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      qty == 0
                          ? '${card.name} đã được đánh dấu hết hàng.'
                          : 'Cập nhật tồn kho ${card.name}: $qty',
                    ),
                    backgroundColor: qty == 0 ? Colors.redAccent : Colors.green,
                  ),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  static void showProductDialog(BuildContext context, [PokemonCard? card]) {
    final isEditing = card != null;
    final nameController = TextEditingController(text: card?.name);
    final priceController = TextEditingController(text: card?.marketPrice.toString());
    final typeController = TextEditingController(text: card?.type ?? 'Colorless');
    final rarityController = TextEditingController(text: card?.rarity ?? 'Common');
    final imageController = TextEditingController(text: card?.imageUrl);
    final hpController = TextEditingController(text: (card?.hp ?? 100).toString());
    final descController = TextEditingController(text: card?.description);
    final stockController = TextEditingController(text: (card?.stockQuantity ?? 50).toString());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          isEditing ? 'Sửa thẻ bài' : 'Thêm thẻ bài mới',
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(nameController, 'Tên thẻ', Icons.catching_pokemon),
              _buildField(priceController, 'Giá (PokeGold)', Icons.monetization_on, isNumber: true),
              _buildField(typeController, 'Hệ (Type)', Icons.category),
              _buildField(rarityController, 'Độ hiếm (Rarity)', Icons.star),
              _buildField(hpController, 'HP', Icons.favorite, isNumber: true),
              _buildField(imageController, 'URL Ảnh', Icons.image),
              _buildField(descController, 'Mô tả', Icons.description, maxLines: 3),
              const Divider(color: Colors.white24, height: 24),
              // Stock field with label
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.inventory_2, color: Colors.amber),
                  labelText: 'Số lượng tồn kho',
                  labelStyle: const TextStyle(color: Colors.white54),
                  helperText: 'Đặt 0 = hết hàng, người dùng sẽ không thể đặt',
                  helperStyle: const TextStyle(color: Colors.orangeAccent, fontSize: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.amber),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.amber),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              if (nameController.text.isEmpty) return;

              final newCard = PokemonCard(
                id: isEditing ? card.id : 'custom_${DateTime.now().millisecondsSinceEpoch}',
                name: nameController.text,
                type: typeController.text,
                rarity: rarityController.text,
                marketPrice: double.tryParse(priceController.text) ?? 0.0,
                priceHistory: card?.priceHistory ?? [double.tryParse(priceController.text) ?? 0.0],
                description: descController.text,
                imageUrl: imageController.text,
                hp: int.tryParse(hpController.text) ?? 100,
                attackName: card?.attackName ?? 'Special Move',
                attackDamage: card?.attackDamage ?? 50,
                weakness: card?.weakness ?? 'None',
                retreatCost: card?.retreatCost ?? 1,
                stockQuantity: int.tryParse(stockController.text) ?? 50,
              );

              await DatabaseService.instance.cacheCards([newCard]);
              if (context.mounted) {
                context.read<CatalogViewModel>().loadCatalog();
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isEditing ? 'Cập nhật thành công!' : 'Thêm thành công!')),
                );
              }
            },
            child: Text(isEditing ? 'Cập nhật' : 'Thêm'),
          ),
        ],
      ),
    );
  }

  static Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white54, size: 18),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.amber),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, PokemonCard card) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
        content: Text(
          'Bạn có chắc muốn xóa thẻ "${card.name}" không? Thao tác này không thể hoàn tác.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa ngay', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await DatabaseService.instance.deleteCard(card.id);
      context.read<CatalogViewModel>().loadCatalog();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa sản phẩm.')));
    }
  }
}
