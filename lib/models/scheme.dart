class Scheme {
  final String id;
  final String name;
  final String description;
  final String category;
  final List<String> benefits;
  final List<String> documentsRequired;

  Scheme({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.benefits,
    required this.documentsRequired,
  });

  factory Scheme.fromJson(Map<String, dynamic> json) {
    return Scheme(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      benefits: List<String>.from(json['benefits'] as List),
      documentsRequired: List<String>.from(json['documentsRequired'] as List),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category,
    'benefits': benefits,
    'documentsRequired': documentsRequired,
  };
}
