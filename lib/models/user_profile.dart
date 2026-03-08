class UserProfile {
  final String id;
  final String? name;
  final int? age;
  final String? gender;
  final String? occupation;
  final double? annualIncome;
  final bool? hasLand;
  final String? caste;
  final Map<String, bool> consents;

  UserProfile({
    required this.id,
    this.name,
    this.age,
    this.gender,
    this.occupation,
    this.annualIncome,
    this.hasLand,
    this.caste,
    this.consents = const {},
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      occupation: json['occupation'] as String?,
      annualIncome: (json['annualIncome'] as num?)?.toDouble(),
      hasLand: json['hasLand'] as bool?,
      caste: json['caste'] as String?,
      consents: Map<String, bool>.from(json['consents'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'age': age,
    'gender': gender,
    'occupation': occupation,
    'annualIncome': annualIncome,
    'hasLand': hasLand,
    'caste': caste,
    'consents': consents,
  };
}
