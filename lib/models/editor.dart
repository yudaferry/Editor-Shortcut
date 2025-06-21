class Editor {
  final int? id;
  final String name;
  final String command;
  final String? arguments;
  final String? description;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  Editor({
    this.id,
    required this.name,
    required this.command,
    this.arguments,
    this.description,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'command': command,
      'arguments': arguments,
      'description': description,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Editor.fromMap(Map<String, dynamic> map) {
    return Editor(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      command: map['command'] ?? '',
      arguments: map['arguments'],
      description: map['description'],
      isDefault: map['is_default'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Editor copyWith({
    int? id,
    String? name,
    String? command,
    String? arguments,
    String? description,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Editor(
      id: id ?? this.id,
      name: name ?? this.name,
      command: command ?? this.command,
      arguments: arguments ?? this.arguments,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}