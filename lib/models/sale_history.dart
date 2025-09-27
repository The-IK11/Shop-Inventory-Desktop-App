class SaleHistory {
  final int? id;
  final String productName;
  final String category;
  final int quantitySold;
  final DateTime saleDate;
  final String notes;

  SaleHistory({
    this.id,
    required this.productName,
    required this.category,
    required this.quantitySold,
    required this.saleDate,
    this.notes = '',
  });

  // Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productName': productName,
      'category': category,
      'quantitySold': quantitySold,
      'saleDate': saleDate.toIso8601String(),
      'notes': notes,
    };
  }

  // Create from database map
  factory SaleHistory.fromMap(Map<String, dynamic> map) {
    return SaleHistory(
      id: map['id'],
      productName: map['productName'],
      category: map['category'],
      quantitySold: map['quantitySold'],
      saleDate: DateTime.parse(map['saleDate']),
      notes: map['notes'] ?? '',
    );
  }

  // Get formatted date string
  String get formattedDate {
    return "${saleDate.day.toString().padLeft(2, '0')}-${saleDate.month.toString().padLeft(2, '0')}-${saleDate.year}";
  }

  // Get just the date part (without time)
  DateTime get dateOnly {
    return DateTime(saleDate.year, saleDate.month, saleDate.day);
  }

  // Copy with new values
  SaleHistory copyWith({
    int? id,
    String? productName,
    String? category,
    int? quantitySold,
    DateTime? saleDate,
    String? notes,
  }) {
    return SaleHistory(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      quantitySold: quantitySold ?? this.quantitySold,
      saleDate: saleDate ?? this.saleDate,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'SaleHistory(id: $id, productName: $productName, category: $category, quantitySold: $quantitySold, saleDate: $saleDate)';
  }
}
