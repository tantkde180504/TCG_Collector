import 'package:flutter/material.dart';
import '../services/tcg_price_service.dart';
import 'package:provider/provider.dart';
import '../viewmodels/settings_viewmodel.dart';

/// Enhanced PriceChart that displays real market data from pokemontcg.io API.
/// Shows date labels on X-axis, source badge, % change, and loading/error states.
class PriceChart extends StatelessWidget {
  // Legacy support: hardcoded price list (used while real data loads)
  final List<double> prices;
  final String pokemonType;

  // Real data (optional — populated when API data arrives)
  final PriceData? priceData;
  final bool isLoading;

  const PriceChart({
    super.key,
    required this.prices,
    required this.pokemonType,
    this.priceData,
    this.isLoading = false,
  });

  Color _getChartColor() {
    switch (pokemonType.toLowerCase()) {
      case 'fire':
        return Colors.redAccent;
      case 'water':
        return const Color(0xFF4FC3F7);
      case 'grass':
        return const Color(0xFF69F0AE);
      case 'lightning':
        return Colors.amber;
      case 'psychic':
        return Colors.purpleAccent;
      case 'dark':
        return Colors.purple.shade300;
      case 'colorless':
      default:
        return Colors.blueGrey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsVM = context.watch<SettingsViewModel>();
    final chartColor = _getChartColor();
    final displayPrices = priceData?.prices ?? prices;
    final displayDates = priceData?.dates ?? [];
    final currentPrice = priceData?.currentPrice;
    final source = priceData?.source;
    final percentChange = priceData?.percentChange;
    final isRising = priceData?.isRising ?? true;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Market Price History',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayDates.length > 1
                            ? '${displayDates.length} day${displayDates.length == 1 ? '' : 's'} of data'
                            : isLoading
                                ? 'Fetching live prices...'
                                : 'Accumulating history daily',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Source badge
                if (source != null && !isLoading)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: source == 'TCGPlayer'
                          ? const Color(0xFF1A3A5C)
                          : const Color(0xFF1A3A1A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: source == 'TCGPlayer'
                            ? const Color(0xFF4A90D9)
                            : const Color(0xFF4A9D4A),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.price_check_rounded,
                          size: 10,
                          color: source == 'TCGPlayer'
                              ? const Color(0xFF4A90D9)
                              : const Color(0xFF4A9D4A),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          source,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: source == 'TCGPlayer'
                                ? const Color(0xFF4A90D9)
                                : const Color(0xFF4A9D4A),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isLoading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        color: Colors.amber, strokeWidth: 1.5),
                  ),
              ],
            ),
          ),

          // ── Price & % Change Row ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Current price
                Text(
                  currentPrice != null
                      ? settingsVM.formatPrice(currentPrice, isExact: true)
                      : displayPrices.isNotEmpty
                          ? settingsVM.formatPrice(displayPrices.last, isExact: true)
                          : '--',
                  style: TextStyle(
                    color: chartColor,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(width: 10),
                // % change badge
                if (percentChange != null && displayPrices.length >= 2)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isRising
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isRising
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 12,
                          color: isRising ? Colors.greenAccent : Colors.redAccent,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${percentChange.abs().toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color:
                                isRising ? Colors.greenAccent : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                // Low / High from TCGPlayer
                if (priceData?.tcgplayerLow != null &&
                    priceData!.tcgplayerLow! > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Text('L ',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  fontSize: 10)),
                          Text(
                            settingsVM.formatPrice(priceData!.tcgplayerLow!),
                            style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text('H ',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  fontSize: 10)),
                          Text(
                            priceData!.tcgplayerHigh! < 9999 ? settingsVM.formatPrice(priceData!.tcgplayerHigh!) : '∞',
                            style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Chart Canvas ─────────────────────────────────────────────────
          if (isLoading)
            _buildLoadingChart()
          else if (displayPrices.isEmpty)
            _buildEmptyState()
          else if (displayPrices.length == 1)
            _buildSinglePointState(displayPrices.first, chartColor, settingsVM)
          else
            _buildChart(displayPrices, displayDates, chartColor, settingsVM),

          // ── CardMarket comparison row ─────────────────────────────────────
          if (priceData?.cardmarketAvg7 != null &&
              priceData!.cardmarketAvg7! > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4A9D4A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'CardMarket 7d avg: ${settingsVM.formatPrice(priceData!.cardmarketAvg7!, isExact: true)}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11),
                  ),
                  if (priceData?.cardmarketAvg30 != null &&
                      priceData!.cardmarketAvg30! > 0) ...[
                    const SizedBox(width: 12),
                    Text(
                      '30d: ${settingsVM.formatPrice(priceData!.cardmarketAvg30!, isExact: true)}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.25),
                          fontSize: 11),
                    ),
                  ],
                ],
              ),
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildChart(
      List<double> prices, List<String> dates, Color chartColor, SettingsViewModel settingsVM) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CustomPaint(
              painter: PriceChartPainter(prices: prices, color: chartColor, settingsVM: settingsVM),
            ),
          ),
          const SizedBox(height: 6),
          // Date labels X-axis
          if (dates.isNotEmpty) _buildDateLabels(dates),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDateLabels(List<String> dates) {
    // Show max 7 labels evenly distributed
    const maxLabels = 7;
    final step = dates.length <= maxLabels
        ? 1
        : (dates.length / maxLabels).ceil();

    final labelIndices = <int>[];
    for (int i = 0; i < dates.length; i += step) {
      labelIndices.add(i);
    }
    if (labelIndices.last != dates.length - 1) {
      labelIndices.add(dates.length - 1);
    }

    return LayoutBuilder(builder: (context, constraints) {
      return SizedBox(
        height: 14,
        child: Stack(
          children: labelIndices.map((idx) {
            final fraction = dates.length == 1
                ? 0.0
                : idx / (dates.length - 1).toDouble();
            final x = fraction * constraints.maxWidth;
            final label = _formatDateLabel(dates[idx]);
            return Positioned(
              left: (x - 16).clamp(0.0, constraints.maxWidth - 32),
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 9,
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  String _formatDateLabel(String date) {
    // "2026-06-20" → "Jun 20"
    try {
      final parts = date.split('-');
      if (parts.length < 3) return date;
      final months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final month = int.tryParse(parts[1]) ?? 1;
      return '${months[month]} ${parts[2]}';
    } catch (_) {
      return date;
    }
  }

  Widget _buildLoadingChart() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.amber, strokeWidth: 2),
              ),
              const SizedBox(height: 10),
              Text(
                'Loading live market prices...',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.05), style: BorderStyle.solid),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart_rounded,
                  size: 32, color: Colors.white.withValues(alpha: 0.15)),
              const SizedBox(height: 8),
              Text(
                'No price data available',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSinglePointState(double price, Color chartColor, SettingsViewModel settingsVM) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: chartColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: chartColor.withValues(alpha: 0.15)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_graph_rounded,
                  size: 28, color: chartColor.withValues(alpha: 0.5)),
              const SizedBox(height: 6),
              Text(
                'Today\'s price: ${settingsVM.formatPrice(price, isExact: true)}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'History builds up daily — check back tomorrow!',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Custom Painter (unchanged logic, improved visual) ─────────────────────────

class PriceChartPainter extends CustomPainter {
  final List<double> prices;
  final Color color;
  final SettingsViewModel settingsVM;

  PriceChartPainter({required this.prices, required this.color, required this.settingsVM});

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.length < 2) return;

    final paintLine = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintPoint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final paintPointOuter = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;

    final double minPrice = prices.reduce((a, b) => a < b ? a : b);
    final double maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final double priceDiff = maxPrice - minPrice == 0 ? 1 : maxPrice - minPrice;
    final double stepX = size.width / (prices.length - 1);

    const double padTop = 12;
    const double padBottom = 8;

    double getY(double price) {
      final normalized = (price - minPrice) / priceDiff;
      return size.height - padBottom - normalized * (size.height - padTop - padBottom);
    }

    // ── Grid lines ────────────────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 3; i++) {
      final y = padTop + (size.height - padTop - padBottom) * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);

      // Y-axis price label
      if (i == 0 || i == 3) {
        final labelPrice = i == 0 ? maxPrice : minPrice;
        final textSpan = TextSpan(
          text: settingsVM.formatPrice(labelPrice),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.2),
            fontSize: 9,
          ),
        );
        final tp = TextPainter(
            text: textSpan, textDirection: TextDirection.ltr)
          ..layout();
        tp.paint(canvas, Offset(size.width - tp.width, i == 0 ? padTop : size.height - padBottom - tp.height));
      }
    }

    // ── Build bezier path ─────────────────────────────────────────────────
    final path = Path();
    final fillPath = Path();

    path.moveTo(0, getY(prices.first));
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, getY(prices.first));

    for (int i = 0; i < prices.length - 1; i++) {
      final x1 = i * stepX;
      final y1 = getY(prices[i]);
      final x2 = (i + 1) * stepX;
      final y2 = getY(prices[i + 1]);
      final cx1 = x1 + (x2 - x1) / 2;
      final cx2 = cx1;

      path.cubicTo(cx1, y1, cx2, y2, x2, y2);
      fillPath.cubicTo(cx1, y1, cx2, y2, x2, y2);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // ── Gradient fill ─────────────────────────────────────────────────────
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.25),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paintLine);

    // ── Data points ───────────────────────────────────────────────────────
    for (int i = 0; i < prices.length; i++) {
      final x = i * stepX;
      final y = getY(prices[i]);

      // Show dot only for first, last, and notable points (not every point if many)
      final shouldDot = prices.length <= 14 || i == 0 || i == prices.length - 1;
      if (shouldDot) {
        canvas.drawCircle(Offset(x, y), 4.5, paintPointOuter);
        canvas.drawCircle(Offset(x, y), 2.5, paintPoint);
      }
    }

    // ── Last price label ──────────────────────────────────────────────────
    final lastX = (prices.length - 1) * stepX;
    final lastY = getY(prices.last);
    final textSpan = TextSpan(
      text: settingsVM.formatPrice(prices.last),
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(
      canvas,
      Offset((lastX - tp.width - 6).clamp(0.0, size.width - tp.width), (lastY - tp.height - 6).clamp(0, size.height - tp.height)),
    );
  }

  @override
  bool shouldRepaint(covariant PriceChartPainter oldDelegate) =>
      oldDelegate.prices != prices || oldDelegate.color != color;
}
