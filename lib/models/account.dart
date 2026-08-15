class Account {
  final String id;
  final String email;
  final String passwordHash;

  const Account({
    required this.id,
    required this.email,
    required this.passwordHash,
  });

  Account copyWith({String? email, String? passwordHash}) {
    return Account(
      id: id,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'passwordHash': passwordHash,
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as String,
        email: json['email'] as String,
        passwordHash: json['passwordHash'] as String,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Account && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
