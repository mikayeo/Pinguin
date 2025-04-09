class Account {
  final String id;
  final String fullName;
  final String email;
  final double balance;
  final String accountNumber;

  Account({
    required this.id,
    required this.fullName,
    required this.email,
    required this.balance,
    required this.accountNumber,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      balance: (json['balance'] as num).toDouble(),
      accountNumber: json['accountNumber'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'balance': balance,
      'accountNumber': accountNumber,
    };
  }

  Account copyWith({
    String? id,
    String? fullName,
    String? email,
    double? balance,
    String? accountNumber,
  }) {
    return Account(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      balance: balance ?? this.balance,
      accountNumber: accountNumber ?? this.accountNumber,
    );
  }
} 