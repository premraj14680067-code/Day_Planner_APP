// lib/features/notes/data/repositories/notes_repository.dart

import 'package:hive_flutter/hive_flutter.dart';
import 'package:daypilot/core/constants/app_constants.dart';
import 'package:daypilot/features/notes/data/models/note_model.dart';

class NotesRepository {
  Box<NoteModel> get _box => Hive.box<NoteModel>(AppConstants.notesBox);

  NoteModel? getNoteForDate(String dateKey) {
    return _box.get(dateKey);
  }

  Future<void> saveNote(NoteModel note) async {
    await _box.put(note.dateKey, note);
  }

  Future<void> deleteNote(String dateKey) async {
    await _box.delete(dateKey);
  }

  Future<void> deleteAllNotes() async {
    await _box.clear();
  }

  List<NoteModel> getAllNotes() {
    return _box.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
}
