class Product {
  final int? id;
  final int? categoryId;
  final String name;
  final String? barcode;
  final double purchasePrice;
  final double sellingPrice;
  final int stock;
  final int minStock;
  final String? imagePath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    this.id,
    this.categoryId,
    required this.name,
    this.barcode,
    required this.purchasePrice,
    required this.sellingPrice,
    this.stock = 0,
    this.minStock = 0,
    this.imagePath,
    this.createdAt,
    this.updatedAt,
  });

  Product copyWith({
    int? id,
    int? categoryId,
    String? name,
    String? barcode,
    double? purchasePrice,
    double? sellingPrice,
    int? stock,
    int? minStock,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
