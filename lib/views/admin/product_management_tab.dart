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
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                color: const Color(0xFF1E1E1E),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      card.imageUrl, 
                      width: 40, 
                      errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 40),
                    ),
                  ),
                  title: Text(card.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Row(
                    children: [
                      Text('${card.type} - ${card.marketPrice} PG'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: card.stockQuantity > 5
                              ? Colors.green.withValues(alpha: 0.2)
                              : card.stockQuantity > 0
                                  ? Colors.orange.withValues(alpha: 0.2)
                                  : Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Kho: ${card.stockQuantity}',
                          style: TextStyle(
                            fontSize: 10,
                            color: card.stockQuantity > 5
                                ? Colors.greenAccent
                                : card.stockQuantity > 0
                                    ? Colors.orangeAccent
                                    : Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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

  static void showProductDialog(BuildContext context, [PokemonCard? card]) {
    final isEditing = card != null;
    final nameController = TextEditingController(text: card?.name);
    final priceController = TextEditingController(text: card?.marketPrice.toString());
    final typeController = TextEditingController(text: card?.type ?? 'Colorless');
    final rarityController = TextEditingController(text: card?.rarity ?? 'Common');
    final imageController = TextEditingController(text: card?.imageUrl);
    final hpController = TextEditingController(text: (card?.hp ?? 100).toString());
    final descController = TextEditingController(text: card?.description);
    final stockController = TextEditingController(text: (card?.stockQuantity ?? 0).toString());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEditing ? 'Sửa thẻ bài' : 'Thêm thẻ bài mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên thẻ')),
              TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Giá (PokeGold)'), keyboardType: TextInputType.number),
              TextField(controller: typeController, decoration: const InputDecoration(labelText: 'Hệ (Type)')),
              TextField(controller: rarityController, decoration: const InputDecoration(labelText: 'Độ hiếm (Rarity)')),
              TextField(controller: hpController, decoration: const InputDecoration(labelText: 'HP'), keyboardType: TextInputType.number),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(
                  labelText: 'Số lượng trong kho',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(controller: imageController, decoration: const InputDecoration(labelText: 'URL Ảnh')),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Mô tả'), maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
          ElevatedButton(
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
                stockQuantity: int.tryParse(stockController.text) ?? 0,
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

  void _confirmDelete(BuildContext context, PokemonCard card) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa thẻ "${card.name}" không? Thao tác này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Xóa ngay', style: TextStyle(color: Colors.red))
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
