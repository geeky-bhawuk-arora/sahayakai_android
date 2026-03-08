import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@JsonSerializable()
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

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
}
