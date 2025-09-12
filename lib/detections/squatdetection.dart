import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:sugmps/utils/video_store.dart';

class SquatDetectionPage extends StatefulWidget {
  const SquatDetectionPage({super.key});

  @override
  State<SquatDetectionPage> createState() => _SquatDetectionPageState();
}

class _SquatDetectionPageState extends State<SquatDetectionPage> {
  CameraController? _cameraController;
  late final PoseDetector _poseDetector;
  bool _isProcessing = false;
  List<Pose> _poses = [];
  CameraDescription? _currentCamera;
  Size? _analysisImageSize;

  // Rep tracking state
  int _reps = 0;
  bool _goingDown = false;
  String _feedback = "";

  // --- Video Recording State ---
  bool _isRecording = false;
  bool _isPaused = false;
  XFile? _recordedFile;

  @override
  void initState() {
    super.initState();
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        model: PoseDetectionModel.base,
        mode: PoseDetectionMode.stream,
      ),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();

    _currentCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      _currentCamera!,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController!.initialize();
    if (!mounted) return;

    _cameraController!.startImageStream(_processCameraImage);
    setState(() {});
  }

  Future<void> _processCameraImage(CameraImage cameraImage) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      _analysisImageSize = Size(
        cameraImage.width.toDouble(),
        cameraImage.height.toDouble(),
      );

      final inputImage = _convertCameraImage(cameraImage, _currentCamera!);
      final poses = await _poseDetector.processImage(inputImage);

      if (poses.isNotEmpty) {
        _analyzePose(poses.first);
      }

      setState(() => _poses = poses);
    } catch (e, st) {
      debugPrint('process camera image error: $e\n$st');
    } finally {
      _isProcessing = false;
    }
  }

  InputImage _convertCameraImage(CameraImage image, CameraDescription camera) {
    final bytesBuilder = BytesBuilder();
    for (final plane in image.planes) {
      bytesBuilder.add(plane.bytes);
    }
    final bytes = bytesBuilder.takeBytes();

    final size = Size(image.width.toDouble(), image.height.toDouble());
    final rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
        InputImageRotation.rotation0deg;
    final format =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;

    final metadata = InputImageMetadata(
      size: size,
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  // ---- Rep counting and feedback logic ----
  double _calculateAngle(Offset a, Offset b, Offset c) {
    final ab = Offset(a.dx - b.dx, a.dy - b.dy);
    final cb = Offset(c.dx - b.dx, c.dy - b.dy);

    final dot = (ab.dx * cb.dx) + (ab.dy * cb.dy);
    final magAB = math.sqrt(ab.dx * ab.dx + ab.dy * ab.dy);
    final magCB = math.sqrt(cb.dx * cb.dx + cb.dy * cb.dy);

    double angle = math.acos(dot / (magAB * magCB)) * (180 / math.pi);
    return angle;
  }

  void _analyzePose(Pose pose) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];

    if (leftHip == null || leftKnee == null || leftAnkle == null) return;

    double angle = _calculateAngle(
      Offset(leftHip.x, leftHip.y),
      Offset(leftKnee.x, leftKnee.y),
      Offset(leftAnkle.x, leftAnkle.y),
    );

    // Feedback
    if (angle < 45) {
      _feedback = "Too low! Don’t go that far.";
    } else if (angle < 100) {
      _feedback = "Good depth, keep it up!";
    } else if (angle < 180) {
      _feedback = "Too high, go lower!";
    }

    // Rep counting
    if (angle < 90) {
      _goingDown = true;
    }
    if (_goingDown && angle > 160) {
      _reps++;
      _goingDown = false;
    }
  }

  // --- Video controls ---
  Future<void> _startRecording() async {
    if (_cameraController == null || _cameraController!.value.isRecordingVideo)
      return;
    await _cameraController!.startVideoRecording();
    setState(() {
      _isRecording = true;
      _isPaused = false;
    });
  }

  Future<void> _pauseRecording() async {
    if (_cameraController == null || !_cameraController!.value.isRecordingVideo)
      return;
    await _cameraController!.pauseVideoRecording();
    setState(() => _isPaused = true);
  }

  Future<void> _resumeRecording() async {
    if (_cameraController == null || !_cameraController!.value.isRecordingVideo)
      return;
    await _cameraController!.resumeVideoRecording();
    setState(() => _isPaused = false);
  }

  Future<void> _stopRecording() async {
    if (_cameraController == null || !_cameraController!.value.isRecordingVideo)
      return;
    final file = await _cameraController!.stopVideoRecording();
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _recordedFile = file;
    });

    if (!mounted) return;
    _showSaveDialog(file);
  }

  void _showSaveDialog(XFile file) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Save Video"),
          content: const Text("Do you want to save this workout video?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                savedVideos.add(
                  SavedVideo(
                    label: "Workout Video ${savedVideos.length + 1}",
                    path: file.path,
                  ),
                );
                await saveVideosToPrefs();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Video saved successfully")),
                );
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),
          CustomPaint(
            painter: PosePainter(
              poses: _poses,
              cameraController: _cameraController!,
              camera: _currentCamera!,
              analysisImageSize: _analysisImageSize,
            ),
          ),
          Positioned(
            top: 60,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Reps: $_reps",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "$_feedback",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: Colors.yellow,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isRecording)
                  FloatingActionButton(
                    heroTag: "start",
                    onPressed: _startRecording,
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.fiber_manual_record),
                  ),
                if (_isRecording && !_isPaused)
                  FloatingActionButton(
                    heroTag: "pause",
                    onPressed: _pauseRecording,
                    backgroundColor: Colors.orange,
                    child: const Icon(Icons.pause),
                  ),
                if (_isRecording && _isPaused)
                  FloatingActionButton(
                    heroTag: "resume",
                    onPressed: _resumeRecording,
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.play_arrow),
                  ),
                if (_isRecording) const SizedBox(width: 20),
                if (_isRecording)
                  FloatingActionButton(
                    heroTag: "stop",
                    onPressed: _stopRecording,
                    backgroundColor: Colors.blue,
                    child: const Icon(Icons.stop),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final CameraController cameraController;
  final CameraDescription camera;
  final Size? analysisImageSize;

  PosePainter({
    required this.poses,
    required this.cameraController,
    required this.camera,
    required this.analysisImageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (analysisImageSize == null) return;

    final pointPaint =
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill;

    final linePaint =
        Paint()
          ..color = Colors.green
          ..strokeWidth = 4;

    final previewSize = cameraController.value.previewSize!;
    final isFront = camera.lensDirection == CameraLensDirection.front;

    final previewAspect = previewSize.width / previewSize.height;
    final screenAspect = size.width / size.height;

    double scaleX, scaleY;
    double offsetX = 0, offsetY = 0;

    if (previewAspect > screenAspect) {
      scaleX = size.width / previewSize.width;
      scaleY = scaleX;
      offsetY = (size.height - previewSize.height * scaleY) / 2;
    } else {
      scaleY = size.height / previewSize.height;
      scaleX = scaleY;
      offsetX = (size.width - previewSize.width * scaleX) / 2;
    }

    Offset transform(PoseLandmark lm) {
      double x = lm.x;
      double y = lm.y;
      if (isFront) x = analysisImageSize!.width - x;

      double previewX = (x / analysisImageSize!.width) * previewSize.width;
      double previewY = (y / analysisImageSize!.height) * previewSize.height;

      double screenX = previewX * scaleX + offsetX;
      double screenY = previewY * scaleY + offsetY;

      return Offset(screenX, screenY);
    }

    for (final pose in poses) {
      for (final lm in pose.landmarks.values) {
        canvas.drawCircle(transform(lm), 8, pointPaint);
      }

      void line(PoseLandmarkType a, PoseLandmarkType b) {
        final la = pose.landmarks[a];
        final lb = pose.landmarks[b];
        if (la != null && lb != null) {
          canvas.drawLine(transform(la), transform(lb), linePaint);
        }
      }

      line(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
      line(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
      line(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
      line(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
      line(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);
      line(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
      line(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
      line(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
      line(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
      line(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
      line(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
      line(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) =>
      oldDelegate.poses != poses ||
      oldDelegate.analysisImageSize != analysisImageSize;
}
