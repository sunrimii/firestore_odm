import 'package:equatable/equatable.dart';
import 'package:firestore_odm/firestore_odm.dart';

class ManualUser3<T> with EquatableMixin {
  @DocumentIdField()
  final String id;

  final String name;
  final T customField; // Generic field for additional flexibility

  const ManualUser3({
    required this.id,
    required this.name,
    required this.customField,
  });

  ManualUser3<T> copyWith({
    String? id,
    String? name,
    T? customField,
  }) {
    return ManualUser3<T>(
      id: id ?? this.id,
      name: name ?? this.name,
      customField: customField ?? this.customField,
    );
  }

  @override
  List<Object?> get props => [id, name, customField];
}

class ManualUser3Profile<T> with EquatableMixin {
  final String email;
  final int age;
  final bool isPremium;
  final double rating;
  final List<String> tags;
  final Map<String, String> preferences;
  final List<T> customList; // Generic list for additional flexibility

  const ManualUser3Profile({
    required this.email,
    required this.age,
    this.isPremium = false,
    this.rating = 0.0,
    this.tags = const [],
    this.preferences = const {},
    this.customList = const [],
  });

  ManualUser3Profile<T> copyWith({
    String? email,
    int? age,
    bool? isPremium,
    double? rating,
    List<String>? tags,
    Map<String, String>? preferences,
    List<T>? customList,
  }) {
    return ManualUser3Profile<T>(
      email: email ?? this.email,
      age: age ?? this.age,
      isPremium: isPremium ?? this.isPremium,
      rating: rating ?? this.rating,
      tags: tags ?? this.tags,
      preferences: preferences ?? this.preferences,
      customList: customList ?? this.customList,
    );
  }

  @override
  List<Object?> get props => [email, age, isPremium, rating, tags, preferences, customList];
}

class Book with EquatableMixin {
  final String title;
  final String author;

  const Book({
    required this.title,
    required this.author,
  });

  @override
  List<Object?> get props => [title, author];
}