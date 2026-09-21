import 'package:flutter/material.dart';

import '../diagnostics/breadcrumb.dart';
import '../diagnostics/breadcrumb_formatter.dart';

class BreadcrumbList extends StatelessWidget {
  final List<Breadcrumb> breadcrumbs;

  const BreadcrumbList({super.key, required this.breadcrumbs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (breadcrumbs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Text('No recent events.', style: theme.textTheme.bodySmall),
      );
    }

    final now = DateTime.now();
    final ordered = breadcrumbs.reversed.toList();
    final rows = <Widget>[];
    String? currentBucket;

    for (final crumb in ordered) {
      final bucket = BreadcrumbFormatter.timeBucket(crumb.timestamp, now);
      if (bucket != currentBucket) {
        currentBucket = bucket;
        rows.add(_SectionHeader(label: bucket));
      }
      rows.add(_BreadcrumbRow(crumb: crumb, now: now));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _BreadcrumbRow extends StatelessWidget {
  final Breadcrumb crumb;
  final DateTime now;

  const _BreadcrumbRow({required this.crumb, required this.now});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _categoryColor(theme, crumb.category);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_categoryIcon(crumb.category), size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              BreadcrumbFormatter.describe(crumb),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            BreadcrumbFormatter.relativeTime(crumb.timestamp, now),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(BreadcrumbCategory category) {
    switch (category) {
      case BreadcrumbCategory.navigation:
        return Icons.alt_route;
      case BreadcrumbCategory.tap:
        return Icons.touch_app_outlined;
      case BreadcrumbCategory.network:
        return Icons.cloud_outlined;
      case BreadcrumbCategory.lifecycle:
        return Icons.phone_android;
      case BreadcrumbCategory.custom:
        return Icons.flag_outlined;
    }
  }

  Color _categoryColor(ThemeData theme, BreadcrumbCategory category) {
    switch (category) {
      case BreadcrumbCategory.navigation:
        return theme.colorScheme.primary;
      case BreadcrumbCategory.tap:
        return theme.colorScheme.onSurfaceVariant;
      case BreadcrumbCategory.network:
        return const Color(0xFF0288D1);
      case BreadcrumbCategory.lifecycle:
        return const Color(0xFFFB8C00);
      case BreadcrumbCategory.custom:
        return theme.colorScheme.secondary;
    }
  }
}
