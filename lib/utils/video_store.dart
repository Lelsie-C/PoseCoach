// video_store.dart
import 'package:shared_preferences/shared_preferences.dart';

class SavedVideo {
  final String label;
  final String path;

  SavedVideo({required this.label, required this.path});

  // Convert to Map for easier storage if needed
  Map<String, String> toMap() => {'label': label, 'path': path};
}

// Global list of saved videos
List<SavedVideo> savedVideos = [];

// Load saved videos from SharedPreferences
Future<void> loadVideosFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  final paths = prefs.getStringList('savedVideos') ?? [];
  savedVideos =
      paths
          .asMap()
          .entries
          .map(
            (e) =>
                SavedVideo(label: "Workout Video ${e.key + 1}", path: e.value),
          )
          .toList();
}

// Save videos list to SharedPreferences
Future<void> saveVideosToPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  final paths = savedVideos.map((v) => v.path).toList();
  await prefs.setStringList('savedVideos', paths);
}
