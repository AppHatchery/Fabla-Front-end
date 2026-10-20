enum BreadcrumbCategory { navigation, tap, network, lifecycle, custom }

extension BreadcrumbCategoryLabel on BreadcrumbCategory {
  String get label => name;
}

class Breadcrumb {
  final DateTime timestamp;
  final BreadcrumbCategory category;
  final String event;
  final Map<String, dynamic>? data;

  Breadcrumb({
    required this.category,
    required this.event,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'category': category.label,
        'event': event,
        if (data != null && data!.isNotEmpty) 'data': data,
      };

  @override
  String toString() {
    final time = timestamp.toIso8601String().substring(11, 23);
    final suffix = (data == null || data!.isEmpty) ? '' : ' $data';
    return '[$time] ${category.label}: $event$suffix';
  }
}
