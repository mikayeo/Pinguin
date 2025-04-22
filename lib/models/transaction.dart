class Transaction {
  final int? id;
  final String sender_phone;
  final String recipient_phone;
  final double amount;
  final String type;
  final DateTime createdAt;

  Transaction({
    this.id,
    required this.sender_phone,
    required this.recipient_phone,
    required this.amount,
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'sender_phone': sender_phone,
    'recipient_phone': recipient_phone,
    'amount': amount,
    'type': type,
    'created_at': createdAt.toIso8601String(),
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'],
    sender_phone: json['sender_phone'],
    recipient_phone: json['recipient_phone'],
    amount: double.parse(json['amount'].toString()),
    type: json['type'],
    createdAt: DateTime.parse(json['created_at']),
  );
}
