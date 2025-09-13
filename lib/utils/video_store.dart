// video_store.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SavedVideo {
  final String label;
  final String path;

  // new stats fields
  final int reps;
  final int goodReps;
  final double accuracy; // percentage 0..100
  final int grade; // 0..100
  final String notes;

  SavedVideo({
    required this.label,
    required this.path,
    this.reps = 0,
    this.goodReps = 0,
    this.accuracy = 0.0,
    this.grade = 0,
    this.notes = "",
  });

  Map<String, dynamic> toMap() => {
    'label': label,
    'path': path,
    'reps': reps,
    'goodReps': goodReps,
    'accuracy': accuracy,
    'grade': grade,
    'notes': notes,
  };

  factory SavedVideo.fromMap(Map<String, dynamic> m) => SavedVideo(
    label: m['label'] as String? ?? '',
    path: m['path'] as String? ?? '',
    reps: (m['reps'] as num?)?.toInt() ?? 0,
    goodReps: (m['goodReps'] as num?)?.toInt() ?? 0,
    accuracy: (m['accuracy'] as num?)?.toDouble() ?? 0.0,
    grade: (m['grade'] as num?)?.toInt() ?? 0,
    notes: m['notes'] as String? ?? '',
  );
}

// Global list of saved videos
List<SavedVideo> savedVideos = [];

// Load saved videos from SharedPreferences
Future<void> loadVideosFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonList = prefs.getStringList('savedVideos') ?? [];
  savedVideos =
      jsonList.map((s) {
        try {
          final map = jsonDecode(s) as Map<String, dynamic>;
          return SavedVideo.fromMap(map);
        } catch (_) {
          // fallback in case of older format (just a path string)
          return SavedVideo(label: "Workout Video", path: s);
        }
      }).toList();
}

// Save videos list to SharedPreferences
Future<void> saveVideosToPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonList = savedVideos.map((v) => jsonEncode(v.toMap())).toList();
  await prefs.setStringList('savedVideos', jsonList);
}
