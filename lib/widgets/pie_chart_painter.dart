import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CategoryPieChart extends StatelessWidget {
  final Map<String, double> data;

  const CategoryPieChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold(0.0, (sum, val) => sum + val);

    final colors = <String, Color>{
      'Milk Tea': AppTheme.milkTeaBlue,
      'Snack': AppTheme.snackAmber,
    };

    if (total <= 0) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline_rounded, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'No sales data for this period',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          width: 180,
          child: CustomPaint(
            painter: _PiePainter(
              data: data,
              colors: colors,
              total: total,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: data.entries.map((entry) {
            final color = colors[entry.key] ?? AppTheme.amberGold;
            final pct = total > 0 ? (entry.value / total * 100).toStringAsFixed(1) : '0';
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${entry.key}: ',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1B18),
                  ),
                ),
                Text(
                  '\$${entry.value.toStringAsFixed(2)} ($pct%)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PiePainter extends CustomPainter {
  final Map<String, double> data;
  final Map<String, Color> colors;
  final double total;

  _PiePainter({
    required this.data,
    required this.colors,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -pi / 2;

    for (final entry in data.entries) {
      final sweepAngle = total > 0 ? (entry.value / total) * 2 * pi : 0.0;
      final paint = Paint()
        ..color = colors[entry.key] ?? AppTheme.amberGold
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      // White slice separator
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawArc(rect, startAngle, sweepAngle, true, borderPaint);

      startAngle += sweepAngle;
    }

    // Inner Donut hole for modern look
    final holePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.48, holePaint);

    final holeBorder = Paint()
      ..color = const Color(0xFFECE7DE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius * 0.48, holeBorder);
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) {
    return oldDelegate.total != total || oldDelegate.data != data;
  }
}

class PieChartPainter extends CustomPainter {
  final Map<String, double> data;
  final Map<String, Color>? colors;

  PieChartPainter({
    required this.data,
    this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.values.fold(0.0, (sum, val) => sum + val);
    if (total <= 0) return;

    final defaultPalette = [
      AppTheme.coffeeMedium,
      AppTheme.amberGold,
      AppTheme.softMatcha,
      AppTheme.roseBerry,
      AppTheme.coffeeDark,
      const Color(0xFF6366F1),
      const Color(0xFF14B8A6),
    ];

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -pi / 2;
    int idx = 0;

    for (final entry in data.entries) {
      final sweepAngle = (entry.value / total) * 2 * pi;
      final color = colors?[entry.key] ?? defaultPalette[idx % defaultPalette.length];
      idx++;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      // White slice separator
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawArc(rect, startAngle, sweepAngle, true, borderPaint);

      startAngle += sweepAngle;
    }

    // Inner Donut hole
    final holePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.52, holePaint);

    final holeBorder = Paint()
      ..color = const Color(0xFFECE7DE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius * 0.52, holeBorder);
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

