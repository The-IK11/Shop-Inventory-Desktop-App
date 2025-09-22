class SalesData {
  final DateTime date;
  final int quantity;
  final String period;

  SalesData({
    required this.date,
    required this.quantity,
    required this.period,
  });
}

class CategoryData {
  final String category;
  final int quantity;
  final double percentage;

  CategoryData({
    required this.category,
    required this.quantity,
    required this.percentage,
  });
}

class ProductPerformance {
  final String productName;
  final int quantitySold;
  final String category;
  final double revenue;

  ProductPerformance({
    required this.productName,
    required this.quantitySold,
    required this.category,
    required this.revenue,
  });
}

class ReportSummary {
  final int totalProductsSold;
  final int totalQuantitySold;
  final int activeProducts;
  final int lowStockItems;

  ReportSummary({
    required this.totalProductsSold,
    required this.totalQuantitySold,
    required this.activeProducts,
    required this.lowStockItems,
  });
}
