class Transaction {
  final String recipientPhone;
  final double amount;
  final DateTime date;

  Transaction({
    required this.recipientPhone,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'recipientPhone': recipientPhone,
    'amount': amount,
    'date': date.toIso8601String(),
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    recipientPhone: json['recipientPhone'],
    amount: json['amount'],
    date: DateTime.parse(json['date']),
  );
}
