import 'dart:ui';

class Profile {
  final String id;
  final String accountId;
  final String name;
  final int dobTimestamp;
  final String gender; // "Male", "Female", "Other"
  final double heightCm;
  final double weightKg;

  const Profile({
    required this.id,
    required this.accountId,
    required this.name,
    required this.dobTimestamp,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
  });

  Profile copyWith({
    String? name,
    String? gender,
    double? heightCm,
    double? weightKg,
  }) {
    return Profile(
      id: id,
      accountId: accountId,
      name: name ?? this.name,
      dobTimestamp: dobTimestamp,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
    );
  }

  // BMI = weight(kg) / height(m)^2
  double get bmi {
    final hm = heightCm / 100.0;
    if (hm <= 0) return 0.0;
    return weightKg / (hm * hm);
  }

  String get bmiCategory {
    final b = bmi;
    if (b < 18.5) return 'Underweight';
    if (b < 25.0) return 'Normal Weight';
    if (b < 30.0) return 'Overweight';
    return 'Obese';
  }

  Color get bmiColor {
    final b = bmi;
    if (b < 18.5) return const Color(0xFF2196F3); // blue
    if (b < 25.0) return const Color(0xFF4CAF50); // green
    if (b < 30.0) return const Color(0xFFFF9800); // orange
    return const Color(0xFFF44336); // red
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'accountId': accountId,
        'name': name,
        'dobTimestamp': dobTimestamp,
        'gender': gender,
        'heightCm': heightCm,
        'weightKg': weightKg,
      };

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        accountId: json['accountId'] as String,
        name: json['name'] as String,
        dobTimestamp: json['dobTimestamp'] as int,
        gender: json['gender'] as String,
        heightCm: (json['heightCm'] as num).toDouble(),
        weightKg: (json['weightKg'] as num).toDouble(),
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Profile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
