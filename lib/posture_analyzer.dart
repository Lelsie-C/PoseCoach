import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

class PostureAnalyzer {
  static Interpreter? _interpreter;
  static bool _isInitialized = false;

  // Configuration (same as Python)
  static const double CONF_THRESHOLD = 0.35;
  static const double DOWN_THRESHOLD = 100;
  static const double UP_THRESHOLD = 160;
  static const double BACK_ANGLE_THRESHOLD = 165;
  static const double KNEE_ALIGNMENT_THRESHOLD = 15;

  // Skeleton connections
  static const List<List<int>> SKELETON = [
    [0, 1],
    [0, 2],
    [1, 3],
    [2, 4],
    [5, 6],
    [5, 7],
    [7, 9],
    [6, 8],
    [8, 10],
    [5, 11],
    [6, 12],
    [11, 12],
    [11, 13],
    [13, 15],
    [12, 14],
    [14, 16],
  ];

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final interpreterOptions = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset(
        'movenet.tflite',
        options: interpreterOptions,
      );
      _isInitialized = true;
      print('TFLite model initialized successfully');
    } catch (e) {
      print('TFLite initialization failed: $e');
      throw Exception('Failed to initialize TFLite: $e');
    }
  }

  static Future<Map<String, dynamic>> analyzeVideo(String videoPath) async {
    if (!_isInitialized) await initialize();

    try {
      final analyzer = _PostureAnalyzer();
      final frames = await _extractFrames(videoPath);

      for (int i = 0; i < frames.length; i++) {
        final frame = frames[i];
        final keypoints = await _runInference(frame);
        final frameTime = i / 30.0; // Assuming 30 FPS

        analyzer.analyzeFrame(keypoints, frame.width, frame.height, frameTime);
      }

      return {
        'success': true,
        'rep_count': analyzer.repCount,
        'rep_details': analyzer.repDetails,
        'report': analyzer.generateFinalReport(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'rep_count': 0,
        'rep_details': [],
      };
    }
  }

  static Future<List<img.Image>> _extractFrames(String videoPath) async {
    final frames = <img.Image>[];

    for (int i = 0; i < 100; i += 2) {
      try {
        final uint8list = await VideoThumbnail.thumbnailData(
          video: videoPath,
          imageFormat: ImageFormat.JPEG,
          timeMs: i * 100,
          quality: 50,
        );

        if (uint8list != null) {
          final image = img.decodeImage(uint8list);
          if (image != null) {
            frames.add(image);
          }
        }
      } catch (e) {
        print('Error extracting frame: $e');
      }
    }

    return frames;
  }

  static Future<List<List<double>>> _runInference(img.Image image) async {
    if (_interpreter == null) throw Exception('Interpreter not initialized');

    // Preprocess image → shape [1,192,192,3]
    final input = _preprocessImage(image);

    // Output → shape [1,17,3]
    final output = List.generate(
      1,
      (_) => List.generate(17, (_) => List.filled(3, 0.0)),
    );

    _interpreter!.run(input, output);

    return output[0]; // shape [17,3]
  }

  static List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    final resized = img.copyResize(image, width: 192, height: 192);

    final input = List<List<List<List<double>>>>.generate(
      1,
      (_) => List<List<List<double>>>.generate(
        192,
        (_) => List<List<double>>.generate(
          192,
          (_) => List<double>.filled(3, 0.0),
        ),
      ),
    );

    for (var y = 0; y < 192; y++) {
      for (var x = 0; x < 192; x++) {
        final pixel = resized.getPixel(x, y);
        input[0][y][x][0] = pixel.r / 255.0;
        input[0][y][x][1] = pixel.g / 255.0;
        input[0][y][x][2] = pixel.b / 255.0;
      }
    }

    return input;
  }

  static double _calculateAngle(
    List<double> a,
    List<double> b,
    List<double> c,
  ) {
    final ba = [a[0] - b[0], a[1] - b[1]];
    final bc = [c[0] - b[0], c[1] - b[1]];

    final dotProduct = ba[0] * bc[0] + ba[1] * bc[1];
    final magnitudeBA = sqrt(ba[0] * ba[0] + ba[1] * ba[1]);
    final magnitudeBC = sqrt(bc[0] * bc[0] + bc[1] * bc[1]);

    final cosine = dotProduct / (magnitudeBA * magnitudeBC + 1e-6);
    final angle = acos(cosine.clamp(-1.0, 1.0)) * 180 / pi;

    return angle;
  }
}

class _PostureAnalyzer {
  int repCount = 0;
  String squatState = "UP";
  String feedback = "Starting analysis...";
  List<Map<String, dynamic>> repDetails = [];
  Map<String, dynamic> currentRepData = {
    'start_time': 0,
    'end_time': 0,
    'min_knee_angle': 180.0,
    'max_back_angle': 0.0,
    'knee_alignment_issues': 0,
    'back_straightness_issues': 0,
  };

  void analyzeFrame(
    List<List<double>> keypoints,
    int frameWidth,
    int frameHeight,
    double frameTime,
  ) {
    final feedbackList = <String>[];
    final warnings = <String>[];

    final requiredIndices = [5, 6, 11, 12, 13, 14, 15, 16];
    final allDetected = requiredIndices.every(
      (i) =>
          i < keypoints.length &&
          keypoints[i][2] > PostureAnalyzer.CONF_THRESHOLD,
    );

    if (!allDetected) {
      feedback = "Keypoints not fully visible";
      return;
    }

    final keypointsPx =
        keypoints
            .map((kp) => [kp[1] * frameWidth, kp[0] * frameHeight, kp[2]])
            .toList();

    final leftKneeAngle = _calculateKneeAngle(keypointsPx, 11, 13, 15);
    final rightKneeAngle = _calculateKneeAngle(keypointsPx, 12, 14, 16);
    final backAngle = _calculateBackAngle(keypointsPx, 5, 6, 11, 12);

    final avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2;
    final kneeAlignmentIssue = _checkKneeAlignment(keypointsPx, 13, 14, 15, 16);

    if (squatState == "UP" && avgKneeAngle < PostureAnalyzer.DOWN_THRESHOLD) {
      squatState = "DOWN";
      currentRepData['start_time'] = frameTime;
      feedbackList.add("Squat down detected");
    } else if (squatState == "DOWN" &&
        avgKneeAngle > PostureAnalyzer.UP_THRESHOLD) {
      squatState = "UP";
      repCount++;
      currentRepData['end_time'] = frameTime;
      _finalizeRepAnalysis();
      feedbackList.add("Good rep! ($repCount)");
    }

    if (squatState == "DOWN") {
      currentRepData['min_knee_angle'] = min(
        currentRepData['min_knee_angle'],
        avgKneeAngle,
      );
      currentRepData['max_back_angle'] = max(
        currentRepData['max_back_angle'],
        backAngle,
      );

      if (kneeAlignmentIssue) {
        currentRepData['knee_alignment_issues']++;
        warnings.add("Knees moving forward too much");
      }

      if (backAngle < PostureAnalyzer.BACK_ANGLE_THRESHOLD) {
        currentRepData['back_straightness_issues']++;
        warnings.add("Keep your back straight");
      }
    }

    feedbackList.add("Knee angle: ${avgKneeAngle.toInt()}°");
    feedbackList.add("Back angle: ${backAngle.toInt()}°");

    feedback = feedbackList.join(" | ");
  }

  double _calculateKneeAngle(
    List<List<double>> keypoints,
    int hipIdx,
    int kneeIdx,
    int ankleIdx,
  ) {
    final hip = [keypoints[hipIdx][0], keypoints[hipIdx][1]];
    final knee = [keypoints[kneeIdx][0], keypoints[kneeIdx][1]];
    final ankle = [keypoints[ankleIdx][0], keypoints[ankleIdx][1]];

    return PostureAnalyzer._calculateAngle(hip, knee, ankle);
  }

  double _calculateBackAngle(
    List<List<double>> keypoints,
    int lShoulderIdx,
    int rShoulderIdx,
    int lHipIdx,
    int rHipIdx,
  ) {
    final shoulderCenter = [
      (keypoints[lShoulderIdx][0] + keypoints[rShoulderIdx][0]) / 2,
      (keypoints[lShoulderIdx][1] + keypoints[rShoulderIdx][1]) / 2,
    ];

    final hipCenter = [
      (keypoints[lHipIdx][0] + keypoints[rHipIdx][0]) / 2,
      (keypoints[lHipIdx][1] + keypoints[rHipIdx][1]) / 2,
    ];

    final verticalRef = [shoulderCenter[0], shoulderCenter[1] - 100];

    return PostureAnalyzer._calculateAngle(
      verticalRef,
      shoulderCenter,
      hipCenter,
    );
  }

  bool _checkKneeAlignment(
    List<List<double>> keypoints,
    int lKneeIdx,
    int rKneeIdx,
    int lAnkleIdx,
    int rAnkleIdx,
  ) {
    final lKnee = keypoints[lKneeIdx];
    final rKnee = keypoints[rKneeIdx];
    final lAnkle = keypoints[lAnkleIdx];
    final rAnkle = keypoints[rAnkleIdx];

    final lIssue =
        lKnee[0] > lAnkle[0] + PostureAnalyzer.KNEE_ALIGNMENT_THRESHOLD;
    final rIssue =
        rKnee[0] > rAnkle[0] + PostureAnalyzer.KNEE_ALIGNMENT_THRESHOLD;

    return lIssue || rIssue;
  }

  void _finalizeRepAnalysis() {
    var repScore = 100;

    if (currentRepData['min_knee_angle'] >
        PostureAnalyzer.DOWN_THRESHOLD + 10) {
      repScore -= 20;
    }

    if (currentRepData['max_back_angle'] <
        PostureAnalyzer.BACK_ANGLE_THRESHOLD - 10) {
      repScore -= 15;
    }

    if (currentRepData['knee_alignment_issues'] > 0) {
      repScore -= 10;
    }

    final repDuration =
        currentRepData['end_time'] - currentRepData['start_time'];

    repDetails.add({
      'rep_number': repCount,
      'score': repScore.clamp(60, 100),
      'depth_angle': currentRepData['min_knee_angle'],
      'back_angle': currentRepData['max_back_angle'],
      'duration': repDuration,
      'knee_issues': currentRepData['knee_alignment_issues'],
      'back_issues': currentRepData['back_straightness_issues'],
    });

    currentRepData = {
      'start_time': 0,
      'end_time': 0,
      'min_knee_angle': 180.0,
      'max_back_angle': 0.0,
      'knee_alignment_issues': 0,
      'back_straightness_issues': 0,
    };
  }

  String generateFinalReport() {
    if (repDetails.isEmpty) return "No reps detected in the video";

    final totalScore =
        repDetails.fold(0.0, (sum, rep) => sum + (rep['score'] ?? 0)) /
        repDetails.length;
    final avgDepth =
        repDetails.fold(0.0, (sum, rep) => sum + (rep['depth_angle'] ?? 0)) /
        repDetails.length;
    final avgDuration =
        repDetails.fold(0.0, (sum, rep) => sum + (rep['duration'] ?? 0)) /
        repDetails.length;

    final report = StringBuffer();
    report.writeln("=" * 50);
    report.writeln("SQUAT PERFORMANCE ANALYSIS REPORT");
    report.writeln("=" * 50);
    report.writeln("Total Reps: $repCount");
    report.writeln("Overall Score: ${totalScore.toStringAsFixed(1)}/100");
    report.writeln("Average Depth: ${avgDepth.toStringAsFixed(1)}°");
    report.writeln("Average Rep Duration: ${avgDuration.toStringAsFixed(2)}s");
    report.writeln();

    report.writeln("REP-BY-REP ANALYSIS:");
    report.writeln("-" * 30);
    for (final rep in repDetails) {
      report.writeln("Rep ${rep['rep_number']}: Score ${rep['score']}/100");
      report.writeln(
        "  Depth: ${rep['depth_angle']?.toStringAsFixed(1) ?? 'N/A'}°, Back: ${rep['back_angle']?.toStringAsFixed(1) ?? 'N/A'}°",
      );
      report.writeln(
        "  Duration: ${rep['duration']?.toStringAsFixed(2) ?? 'N/A'}s",
      );
      if (rep['knee_issues'] > 0) {
        report.writeln("  ⚠️  Knee alignment issues: ${rep['knee_issues']}");
      }
      if (rep['back_issues'] > 0) {
        report.writeln("  ⚠️  Back straightness issues: ${rep['back_issues']}");
      }
      report.writeln();
    }

    report.writeln("RECOMMENDATIONS:");
    report.writeln("-" * 20);
    if (avgDepth > PostureAnalyzer.DOWN_THRESHOLD + 5) {
      report.writeln(
        "➡️  Go deeper in your squats (aim for thighs parallel to ground)",
      );
    }
    if (repDetails.any(
      (rep) =>
          (rep['back_angle'] ?? 0) < PostureAnalyzer.BACK_ANGLE_THRESHOLD - 5,
    )) {
      report.writeln(
        "➡️  Focus on keeping your back straight throughout the movement",
      );
    }
    if (repDetails.any((rep) => (rep['knee_issues'] ?? 0) > 0)) {
      report.writeln("➡️  Keep your knees behind your toes during descent");
    }
    if (avgDuration < 1.5) {
      report.writeln("➡️  Slow down your reps for better form control");
    }

    report.writeln();
    report.writeln("Keep up the good work! 💪");

    return report.toString();
  }
}
