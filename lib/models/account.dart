class Account {
  final int id;
  final String fullName;
  final String email;
  final double balance;
  final String phoneNumber;

  Account({
    required this.id,
    required this.fullName,
    required this.email,
    required this.balance,
    required this.phoneNumber,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      balance: double.parse(json['balance'].toString()),
      phoneNumber: json['phone_number'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'balance': balance,
      'phone_number': phoneNumber,
    };
  }

  Account copyWith({
    int? id,
    String? fullName,
    String? email,
    double? balance,
    String? phoneNumber,
  }) {
    return Account(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      balance: balance ?? this.balance,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
} 