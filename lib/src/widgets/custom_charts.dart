import 'dart:math';
import 'package:flutter/material.dart';

class CustomBarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color barColor;
  final double height;

  const CustomBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.barColor = const Color(0xFF0F766E), // Teal
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('No data available')),
      );
    }

    final double maxValue = values.reduce(max);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textStyle = TextStyle(
      color: isDark ? Colors.grey[400] : Colors.grey[600],
      fontSize: 10,
    );

    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (index) {
          final double val = values[index];
          final double heightFactor = maxValue > 0 ? (val / maxValue) : 0.0;
          final double barHeight = (heightFactor * (height - 40)).clamp(6.0, height - 40);

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  val.toInt().toString(),
                  style: textStyle.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 16,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[index],
                  style: textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class CustomHorizontalBarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color barColor;

  const CustomHorizontalBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.barColor = const Color(0xFF475569), // Slate
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final double maxValue = values.reduce(max);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelStyle = TextStyle(
      color: isDark ? Colors.grey[300] : Colors.grey[800],
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );
    final valueStyle = TextStyle(
      color: isDark ? Colors.grey[400] : Colors.grey[600],
      fontSize: 11,
      fontWeight: FontWeight.bold,
    );

    return Column(
      children: List.generate(values.length, (index) {
        final double val = values[index];
        final double widthFactor = maxValue > 0 ? (val / maxValue) : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              SpacerHelper(
                width: 90,
                child: Text(
                  labels[index],
                  style: labelStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 14,
                    color: isDark ? const Color(0xFF262322) : const Color(0xFFF1F5F9),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: widthFactor.clamp(0.02, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 32,
                child: Text(
                  val.toInt().toString(),
                  style: valueStyle,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class SpacerHelper extends StatelessWidget {
  final double width;
  final Widget child;
  const SpacerHelper({super.key, required this.width, required this.child});
  @override
  Widget build(BuildContext context) => SizedBox(width: width, child: child);
}

class CustomLineChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color lineColor;
  final Color fillC;
  final double height;

  const CustomLineChart({
    super.key,
    required this.values,
    required this.labels,
    this.lineColor = const Color(0xFFB45309), // Amber
    this.fillC = const Color(0x22B45309),
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('No data available')),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final axisColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _LineChartPainter(
                values: values,
                lineColor: lineColor,
                fillColor: fillC,
                axisColor: axisColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: labels.map((label) {
              return Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 9,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final Color fillColor;
  final Color axisColor;

  _LineChartPainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
    required this.axisColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final double maxVal = values.reduce(max);
    final double minVal = 0.0;
    final double valRange = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    final double width = size.width;
    final double height = size.height;

    // Draw horizontal grid lines
    final Paint gridPaint = Paint()
      ..color = axisColor.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 3; i++) {
      final double y = height - (i * height / 3);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    final int pointsCount = values.length;
    if (pointsCount < 2) return;

    final double stepX = width / (pointsCount - 1);
    final List<Offset> points = [];

    for (int i = 0; i < pointsCount; i++) {
      final double x = i * stepX;
      final double y = height - ((values[i] - minVal) / valRange * height);
      points.add(Offset(x, y));
    }

    // Draw area path (gradient/fill under the line)
    final Path areaPath = Path()..moveTo(0, height);
    for (var point in points) {
      areaPath.lineTo(point.dx, point.dy);
    }
    areaPath.lineTo(points.last.dx, height);
    areaPath.close();

    final Paint fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(areaPath, fillPaint);

    // Draw path line
    final Path linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final Paint linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, linePaint);

    // Draw points/dots
    final Paint dotOuterPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final Paint dotInnerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (var point in points) {
      canvas.drawCircle(point, 5.0, dotOuterPaint);
      canvas.drawCircle(point, 2.5, dotInnerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor;
  }
}

class CustomDonutChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final List<Color> colors;
  final double diameter;

  const CustomDonutChart({
    super.key,
    required this.values,
    required this.labels,
    required this.colors,
    this.diameter = 130,
  });

  @override
  Widget build(BuildContext context) {
    final double total = values.fold(0, (sum, val) => sum + val);

    if (total == 0) {
      return SizedBox(
        height: diameter,
        child: const Center(child: Text('No data')),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: diameter,
                height: diameter,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    values: values,
                    colors: colors,
                    backgroundColor: isDark ? const Color(0xFF1A1817) : Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(values.length, (index) {
              final double val = values[index];
              final double pct = total > 0 ? (val / total * 100) : 0.0;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${labels[index]} (${pct.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final Color backgroundColor;

  _DonutChartPainter({
    required this.values,
    required this.colors,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double total = values.fold(0, (sum, val) => sum + val);
    if (total == 0) return;

    final double radius = size.width / 2;
    final Rect rect = Rect.fromCircle(center: Offset(radius, radius), radius: radius);

    double startAngle = -pi / 2;

    for (int i = 0; i < values.length; i++) {
      final double sweepAngle = (values[i] / total) * 2 * pi;

      if (sweepAngle > 0) {
        final Paint paint = Paint()
          ..color = colors[i % colors.length]
          ..style = PaintingStyle.fill;

        canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
        startAngle += sweepAngle;
      }
    }

    // Draw center hole to make it a donut
    final Paint holePaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(radius, radius), radius * 0.65, holePaint);
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.colors != colors ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
