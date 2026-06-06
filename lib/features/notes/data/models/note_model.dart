// lib/features/notes/data/models/note_model.dart

import 'package:hive/hive.dart';

part 'note_model.g.dart';

@HiveType(typeId: 3)
class NoteModel extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String dateKey;
  @HiveField(2) String content;
  @HiveField(3) DateTime createdAt;
  @HiveField(4) DateTime updatedAt;

  NoteModel({
    required this.id,
    required this.dateKey,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  NoteModel copyWith({
    String? id,
    String? dateKey,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      dateKey: dateKey ?? this.dateKey,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
