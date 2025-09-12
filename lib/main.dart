/*
// Squats 
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(
    const MaterialApp(
      home: PoseDetectionApp(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class PoseDetectionApp extends StatefulWidget {
  const PoseDetectionApp({super.key});

  @override
  State<PoseDetectionApp> createState() => _PoseDetectionAppState();
}

class _PoseDetectionAppState extends State<PoseDetectionApp> {
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
    _currentCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      _currentCamera!,
      ResolutionPreset.high,
      enableAudio: false,
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
    final format = InputImageFormatValue.fromRawValue(image.format.raw) ??
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

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                Text("Reps: $_reps",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
                const SizedBox(height: 12),
                Text("$_feedback",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: Colors.yellow,
                    )),
              ],
            ),
          )
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

    final pointPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
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
*/

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(
    const MaterialApp(
      home: PushupDetectionApp(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class PushupDetectionApp extends StatefulWidget {
  const PushupDetectionApp({super.key});

  @override
  State<PushupDetectionApp> createState() => _PushupDetectionAppState();
}

class _PushupDetectionAppState extends State<PushupDetectionApp> {
  CameraController? _cameraController;
  late final PoseDetector _poseDetector;
  bool _isProcessing = false;
  List<Pose> _poses = [];
  CameraDescription? _currentCamera;
  Size? _analysisImageSize;

  // Rep tracking state
  int _reps = 0;
  bool _goingDown = false;
  String _feedback = "Get ready!";

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
    _currentCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      _currentCamera!,
      ResolutionPreset.high,
      enableAudio: false,
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

  // ---- Rep counting and pushup detection logic ----
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
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    if ([
      leftShoulder,
      rightShoulder,
      leftElbow,
      rightElbow,
      leftWrist,
      rightWrist,
      leftHip,
      rightHip,
    ].contains(null))
      return;

    // Body straightness check
    double shoulderY = (leftShoulder!.y + rightShoulder!.y) / 2;
    double hipY = (leftHip!.y + rightHip!.y) / 2;
    double bodySlope = (shoulderY - hipY).abs();

    if (bodySlope > 40) {
      // Adjust threshold if needed
      _feedback = "Straighten your body!";
      return;
    }

    // Elbow angles
    double leftElbowAngle = _calculateAngle(
      Offset(leftShoulder.x, leftShoulder.y),
      Offset(leftElbow!.x, leftElbow.y),
      Offset(leftWrist!.x, leftWrist!.y),
    );

    double rightElbowAngle = _calculateAngle(
      Offset(rightShoulder!.x, rightShoulder!.y),
      Offset(rightElbow!.x, rightElbow!.y),
      Offset(rightWrist!.x, rightWrist!.y),
    );

    double avgElbowAngle = (leftElbowAngle + rightElbowAngle) / 2;

    // Rep counting logic
    if (avgElbowAngle < 90) {
      _goingDown = true;
      _feedback = "Down position, keep going!";
    } else if (_goingDown && avgElbowAngle > 160) {
      _reps++;
      _goingDown = false;
      _feedback = "Good rep!";
    } else if (!_goingDown) {
      _feedback = "Up position, lower down!";
    }
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
