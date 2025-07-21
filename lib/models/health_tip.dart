enum TipCategory {
  nutrition,
  exercise,
  lifestyle,
  mental,
  sleep,
}

class HealthTip {
  final String id;
  final String title;
  final String content;
  final TipCategory category;
  final String imageUrl;
  final List<String> tags;
  final int readTime; // minutes
  final bool isFavorite;

  HealthTip({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    this.imageUrl = '',
    this.tags = const [],
    this.readTime = 2,
    this.isFavorite = false,
  });

  String get categoryName {
    switch (category) {
      case TipCategory.nutrition:
        return 'Dinh dưỡng';
      case TipCategory.exercise:
        return 'Vận động';
      case TipCategory.lifestyle:
        return 'Lối sống';
      case TipCategory.mental:
        return 'Tinh thần';
      case TipCategory.sleep:
        return 'Giấc ngủ';
    }
  }

  String get categoryIcon {
    switch (category) {
      case TipCategory.nutrition:
        return '🥗';
      case TipCategory.exercise:
        return '💪';
      case TipCategory.lifestyle:
        return '🌱';
      case TipCategory.mental:
        return '🧠';
      case TipCategory.sleep:
        return '😴';
    }
  }

  String get categoryColor {
    switch (category) {
      case TipCategory.nutrition:
        return '#2ECC71';
      case TipCategory.exercise:
        return '#E74C3C';
      case TipCategory.lifestyle:
        return '#3498DB';
      case TipCategory.mental:
        return '#9B59B6';
      case TipCategory.sleep:
        return '#34495E';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category.index,
      'imageUrl': imageUrl,
      'tags': tags,
      'readTime': readTime,
      'isFavorite': isFavorite,
    };
  }

  factory HealthTip.fromMap(Map<String, dynamic> map) {
    return HealthTip(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      category: TipCategory.values[map['category'] ?? 0],
      imageUrl: map['imageUrl'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      readTime: map['readTime'] ?? 2,
      isFavorite: map['isFavorite'] ?? false,
    );
  }

  HealthTip copyWith({
    String? id,
    String? title,
    String? content,
    TipCategory? category,
    String? imageUrl,
    List<String>? tags,
    int? readTime,
    bool? isFavorite,
  }) {
    return HealthTip(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      readTime: readTime ?? this.readTime,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
