import 'package:flutter/material.dart';
import 'app.dart';

enum Trend { up, down, neutral }

class FinancialCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Trend trend;

  const FinancialCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Icon(
                  trend == Trend.up
                      ? Icons.trending_up
                      : trend == Trend.down
                      ? Icons.trending_down
                      : Icons.trending_flat,
                  color: trend == Trend.up
                      ? AppColors.trendUp
                      : trend == Trend.down
                      ? AppColors.trendDown
                      : AppColors.trendNeutral,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: trend == Trend.up
                    ? AppColors.trendUp
                    : trend == Trend.down
                    ? AppColors.trendDown
                    : AppColors.trendNeutral,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
