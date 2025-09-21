class Product {
  final int? id;
  final String name;
  final String category;
  final int quantity;
  final String status;
  final DateTime lastUpdated;

  Product({
    this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.status,
    required this.lastUpdated,
  });

  // Convert Product to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'status': status,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // Create Product from Map (database result)
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      quantity: map['quantity'],
      status: map['status'],
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }

  // Create a copy of the product with updated fields
  Product copyWith({
    int? id,
    String? name,
    String? category,
    int? quantity,
    String? status,
    DateTime? lastUpdated,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'Product{id: $id, name: $name, category: $category, quantity: $quantity, status: $status, lastUpdated: $lastUpdated}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          category == other.category &&
          quantity == other.quantity &&
          status == other.status &&
          lastUpdated == other.lastUpdated;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      category.hashCode ^
      quantity.hashCode ^
      status.hashCode ^
      lastUpdated.hashCode;
}
