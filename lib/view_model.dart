import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KanbanViewModel extends ChangeNotifier {
  late final prefs = SharedPreferencesAsync();
  final tasks = <Task>[];

  Future<void> load() async {
    final data = await prefs.getString('kanban');
    if (data == null) return;
    tasks.clear();
    for (final t in jsonDecode(data)) {
      tasks.add(Task.fromJson(t));
    }
  }

  Future<void> save() async {
    notifyListeners();
    final data = [for (final t in tasks) t.toJson()];
    await prefs.setString('kanban', jsonEncode(data));
  }

  void add(String text, {DateTime? lastActionDate}) {
    text = text.trim();
    if (text.isEmpty) return;
    tasks.add(Task(text, 0, lastActionDate));
    save();
  }

  void move(Task t, int status) {
    t.status = status;
    save();
  }

  void rename(Task t, String text) {
    text = text.trim();
    if (text.isEmpty) return;
    t.title = text;
    save();
  }

  void update(Task t, String text, {DateTime? lastActionDate}) {
    text = text.trim();
    if (text.isEmpty) return;
    t.title = text;
    t.lastActionDate = lastActionDate;
    save();
  }

  void markLost(Task t) {
    t.status = 3;
    save();
  }
}
