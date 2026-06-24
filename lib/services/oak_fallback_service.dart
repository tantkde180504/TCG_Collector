import 'dart:math';

import '../models/pokemon_card.dart';

/// Local keyword-based replies when Groq API is unavailable.
class OakFallbackService {
  static String reply(String userText, List<PokemonCard> catalog) {
    final text = userText.toLowerCase();

    final matchedCards = _findMatchingCards(text, catalog);
    if (matchedCards.isNotEmpty) {
      if (matchedCards.length == 1) {
        return _formatCardReply(matchedCards.first);
      }
      final names = matchedCards.map((c) => c.name).join(', ');
      return 'Shop hiện có ${matchedCards.length} thẻ phù hợp: $names. '
          'Bạn muốn biết chi tiết thẻ nào?';
    }

    if (_isPriceQuery(text)) {
      return _formatPriceSummary(catalog);
    }

    if (_isTypeQuery(text)) {
      return _formatTypeSummary(text, catalog);
    }

    if (text.contains('shipping') ||
        text.contains('giao hàng') ||
        text.contains('ship') ||
        text.contains('phí giao')) {
      return 'Giao hàng tiêu chuẩn mất 2-4 ngày làm việc. '
          'Đơn từ \$150.00 được miễn phí giao express, còn không thì phí \$7.99.';
    }

    if (text.contains('fake') ||
        text.contains('real') ||
        text.contains('uy tín') ||
        text.contains('thật') ||
        text.contains('chính hãng')) {
      return 'Yên tâm nhé Trainer! Mọi thẻ đều qua quy trình xác thực 3 bước — '
          'shop cam kết 100% thẻ thật.';
    }

    if (text.contains('discount') ||
        text.contains('giảm giá') ||
        text.contains('gỉam giá') ||
        text.contains('coupon') ||
        text.contains('mã')) {
      return 'Mã giảm giá đang có: "PIKACHU10" (giảm 10%) và "CHARIZARD20" (giảm 20% sản phẩm chọn lọc).';
    }

    if (_isCatalogQuery(text)) {
      return _formatCatalogOverview(catalog);
    }

    final responses = [
      'Câu hỏi hay đấy Trainer! Hãy xem tab Shop để khám phá bộ sưu tập thẻ hiện có nhé.',
      'Để xây bộ deck tốt, bạn nên cân nhắc cả rarity lẫn xu hướng giá thị trường.',
      'Thử mở tab Map để tìm cửa hàng TCG gần bạn và giao lưu với Trainer khác!',
      'Tôi đang ở chế độ offline vì Groq API tạm không khả dụng. '
          'Vẫn có thể hỏi về thẻ trong shop, giá, loại hệ, giao hàng hoặc mã giảm giá nhé!',
    ];
    return responses[Random().nextInt(responses.length)];
  }

  static List<PokemonCard> _findMatchingCards(
    String text,
    List<PokemonCard> catalog,
  ) {
    final matches = <PokemonCard>[];

    for (final card in catalog) {
      final name = card.name.toLowerCase();
      final firstWord = name.split(' ').first;

      if (text.contains(name) ||
          (firstWord.length >= 4 && text.contains(firstWord))) {
        matches.add(card);
      }
    }

    return matches;
  }

  static bool _isPriceQuery(String text) {
    return text.contains('giá') ||
        text.contains('price') ||
        text.contains('bao nhiêu') ||
        text.contains('đắt nhất') ||
        text.contains('rẻ nhất') ||
        text.contains('cheapest') ||
        text.contains('expensive');
  }

  static bool _isTypeQuery(String text) {
    const types = {
      'fire': 'Fire',
      'lửa': 'Fire',
      'water': 'Water',
      'nước': 'Water',
      'grass': 'Grass',
      'cỏ': 'Grass',
      'lightning': 'Lightning',
      'điện': 'Lightning',
      'psychic': 'Psychic',
      'dark': 'Dark',
      'bóng tối': 'Dark',
      'colorless': 'Colorless',
    };

    return types.keys.any(text.contains);
  }

  static bool _isCatalogQuery(String text) {
    return text.contains('có gì') ||
        text.contains('shop có') ||
        text.contains('danh sách') ||
        text.contains('catalog') ||
        text.contains('sản phẩm') ||
        text.contains('thẻ nào');
  }

  static String _formatCardReply(PokemonCard card) {
    return '${card.name} là thẻ ${card.type}-type, ${card.rarity}, '
        'giá \$${card.marketPrice.toStringAsFixed(2)}, ${card.hp} HP — '
        'kỹ năng "${card.attackName}" gây ${card.attackDamage} damage. '
        'Yếu điểm: ${card.weakness}.';
  }

  static String _formatPriceSummary(List<PokemonCard> catalog) {
    if (catalog.isEmpty) {
      return 'Shop hiện chưa có thẻ nào trong catalog.';
    }

    final sorted = List<PokemonCard>.from(catalog)
      ..sort((a, b) => a.marketPrice.compareTo(b.marketPrice));
    final cheapest = sorted.first;
    final priciest = sorted.last;

    return 'Shop có ${catalog.length} thẻ. '
        'Rẻ nhất: ${cheapest.name} (\$${cheapest.marketPrice.toStringAsFixed(2)}). '
        'Đắt nhất: ${priciest.name} (\$${priciest.marketPrice.toStringAsFixed(2)}).';
  }

  static String _formatTypeSummary(String text, List<PokemonCard> catalog) {
    const typeKeywords = {
      'fire': 'Fire',
      'lửa': 'Fire',
      'water': 'Water',
      'nước': 'Water',
      'grass': 'Grass',
      'cỏ': 'Grass',
      'lightning': 'Lightning',
      'điện': 'Lightning',
      'psychic': 'Psychic',
      'dark': 'Dark',
      'bóng tối': 'Dark',
      'colorless': 'Colorless',
    };

    String? targetType;
    for (final entry in typeKeywords.entries) {
      if (text.contains(entry.key)) {
        targetType = entry.value;
        break;
      }
    }

    if (targetType == null) {
      return _formatCatalogOverview(catalog);
    }

    final typed = catalog.where((c) => c.type == targetType).toList();
    if (typed.isEmpty) {
      return 'Shop hiện không có thẻ hệ $targetType.';
    }

    final names = typed.map((c) => '${c.name} (\$${c.marketPrice.toStringAsFixed(2)})').join(', ');
    return 'Thẻ hệ $targetType trong shop: $names.';
  }

  static String _formatCatalogOverview(List<PokemonCard> catalog) {
    if (catalog.isEmpty) {
      return 'Shop hiện chưa có thẻ nào trong catalog.';
    }

    final names = catalog
        .map((c) => '${c.name} (\$${c.marketPrice.toStringAsFixed(2)})')
        .join(', ');
    return 'Shop hiện có ${catalog.length} thẻ: $names.';
  }
}
