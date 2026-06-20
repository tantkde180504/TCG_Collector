import 'package:flutter/material.dart';

class PriceChart extends StatelessWidget {
  final List<double> prices;
  final String pokemonType;

  const PriceChart({
    super.key,
    required this.prices,
    required this.pokemonType,
  });

  Color _getChartColor() {
    switch (pokemonType.toLowerCase()) {
      case 'fire':
        return Colors.redAccent;
      case 'water':
        return Colors.blueAccent;
      case 'grass':
        return Colors.greenAccent;
      case 'lightning':
        return Colors.amber;
      case 'psychic':
        return Colors.purpleAccent;
      case 'dark':
        return Colors.purple.shade300;
      case 'colorless':
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (prices.isEmpty) {
      return const Center(child: Text('No price history available', style: TextStyle(color: Colors.white70)));
    }

    final chartColor = _getChartColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Market Price History (7 Days)',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Last: \$${prices.last.toStringAsFixed(2)}',
              style: TextStyle(
                color: chartColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: CustomPaint(
            painter: PriceChartPainter(prices: prices, color: chartColor),
          ),
        ),
      ],
    );
  }
}

class PriceChartPainter extends CustomPainter {
  final List<double> prices;
  final Color color;

  PriceChartPainter({required this.prices, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.length < 2) return;

    final paintLine = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintPoint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final paintPointOuter = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final double minPrice = prices.reduce((a, b) => a < b ? a : b);
    final double maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final double priceDiff = maxPrice - minPrice == 0 ? 1 : maxPrice - minPrice;

    final double stepX = size.width / (prices.length - 1);
    
    // Convert price to Y coordinate
    double getY(double price) {
      final double normalized = (price - minPrice) / priceDiff;
      // Subtract from size.height so higher price is higher up
      return size.height - (normalized * (size.height - 20)) - 10;
    }

    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 3; i++) {
      final double y = 10 + (size.height - 20) * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    final fillPath = Path();

    path.moveTo(0, getY(prices.first));
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, getY(prices.first));

    // Draw lines using bezier curves
    for (int i = 0; i < prices.length - 1; i++) {
      final double x1 = i * stepX;
      final double y1 = getY(prices[i]);
      final double x2 = (i + 1) * stepX;
      final double y2 = getY(prices[i + 1]);

      final double controlX1 = x1 + (x2 - x1) / 2;
      final double controlY1 = y1;
      final double controlX2 = x1 + (x2 - x1) / 2;
      final double controlY2 = y2;

      path.cubicTo(controlX1, controlY1, controlX2, controlY2, x2, y2);
      fillPath.cubicTo(controlX1, controlY1, controlX2, controlY2, x2, y2);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Draw fill under the line
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.3),
          color.withOpacity(0.01),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paintLine);

    // Draw data points
    for (int i = 0; i < prices.length; i++) {
      final double x = i * stepX;
      final double y = getY(prices[i]);
      
      // Draw outer white circle
      canvas.drawCircle(Offset(x, y), 5.0, paintPointOuter);
      // Draw inner colored circle
      canvas.drawCircle(Offset(x, y), 3.0, paintPoint);

      // Label last point
      if (i == prices.length - 1) {
        final textSpan = TextSpan(
          text: '\$${prices[i].toStringAsFixed(0)}',
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width - 6, y - textPainter.height - 4),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant PriceChartPainter oldDelegate) {
    return oldDelegate.prices != prices || oldDelegate.color != color;
  }
}
