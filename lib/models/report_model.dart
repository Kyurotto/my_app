class ReportModel {
  final String id;
  final String reportType; // 'daily_summary', 'weekly_summary', 'monthly_summary', 'inventory_valuation', 'financial_overview'
  final String title;
  final String period; // 'today', 'week', 'month', 'year', 'all'
  final DateTime generatedAt;
  final String generatedBy;
  final Map<String, dynamic> metrics;
  final Map<String, dynamic> inventorySummary;
  final String? notes;

  ReportModel({
    required this.id,
    required this.reportType,
    required this.title,
    required this.period,
    required this.generatedAt,
    required this.generatedBy,
    required this.metrics,
    this.inventorySummary = const {},
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reportType': reportType,
      'title': title,
      'period': period,
      'generatedAt': generatedAt.toIso8601String(),
      'generatedBy': generatedBy,
      'metrics': metrics,
      'inventorySummary': inventorySummary,
      if (notes != null) 'notes': notes,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id']?.toString() ?? '',
      reportType: map['reportType']?.toString() ?? 'daily_summary',
      title: map['title']?.toString() ?? 'Report',
      period: map['period']?.toString() ?? 'today',
      generatedAt: map['generatedAt'] != null
          ? DateTime.tryParse(map['generatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      generatedBy: map['generatedBy']?.toString() ?? 'System',
      metrics: map['metrics'] != null ? Map<String, dynamic>.from(map['metrics'] as Map) : {},
      inventorySummary: map['inventorySummary'] != null
          ? Map<String, dynamic>.from(map['inventorySummary'] as Map)
          : {},
      notes: map['notes']?.toString(),
    );
  }
}
