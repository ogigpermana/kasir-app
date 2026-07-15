class Transaction {
  final int? id;
  final String invoiceNumber;
  final DateTime date;
  final List<TransactionItem> items;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final double paid;
  final double change;
  final String paymentMethod;
  final String? note;

  const Transaction({
    this.id,
    required this.invoiceNumber,
    required this.date,
    required this.items,
    required this.subtotal,
    required this.tax,
    this.discount = 0,
    required this.total,
    required this.paid,
    required this.change,
    this.paymentMethod = 'cash',
    this.note,
  });

  Transaction copyWith({
    int? id,
    String? invoiceNumber,
    DateTime? date,
    List<TransactionItem>? items,
    double? subtotal,
    double? tax,
    double? discount,
    double? total,
    double? paid,
    double? change,
    String? paymentMethod,
    String? note,
  }) {
    return Transaction(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      date: date ?? this.date,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paid: paid ?? this.paid,
      change: change ?? this.change,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
    );
  }
}

class TransactionItem {
  final int? id;
  final int? transactionId;
  final int productId;
  final String productName;
  final double price;
  final int quantity;
  final double subtotal;

  const TransactionItem({
    this.id,
    this.transactionId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });
}
