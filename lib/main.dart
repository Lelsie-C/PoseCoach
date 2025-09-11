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
      // Store the analysis image size for coordinate mapping
      _analysisImageSize = Size(
        cameraImage.width.toDouble(),
        cameraImage.height.toDouble(),
      );

      final inputImage = _convertCameraImage(cameraImage, _currentCamera!);
      final poses = await _poseDetector.processImage(inputImage);
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
    final sensorOrientation = camera.sensorOrientation;
    final isFront = camera.lensDirection == CameraLensDirection.front;

    // Calculate the actual displayed preview area
    final previewAspect = previewSize.width / previewSize.height;
    final screenAspect = size.width / size.height;

    double scaleX, scaleY;
    double offsetX = 0, offsetY = 0;

    if (previewAspect > screenAspect) {
      // Preview is wider than screen (letterbox on top/bottom)
      scaleX = size.width / previewSize.width;
      scaleY = scaleX;
      offsetY = (size.height - previewSize.height * scaleY) / 2;
    } else {
      // Preview is taller than screen (letterbox on sides)
      scaleY = size.height / previewSize.height;
      scaleX = scaleY;
      offsetX = (size.width - previewSize.width * scaleX) / 2;
    }

    Offset transform(PoseLandmark lm) {
      // The key insight: ML Kit returns coordinates in the analysis image space
      // We need to map these to the screen space where the preview is displayed

      double x = lm.x;
      double y = lm.y;

      // Handle different sensor orientations
      switch (sensorOrientation) {
        case 90:
          // Most common orientation for phones
          // Analysis image is rotated 90 degrees clockwise relative to preview
          final temp = x;
          x = analysisImageSize!.height - y;
          y = temp;
          break;
        case 270:
          final temp = x;
          x = y;
          y = analysisImageSize!.width - temp;
          break;
        case 180:
          x = analysisImageSize!.width - x;
          y = analysisImageSize!.height - y;
          break;
        // case 0: no rotation needed
      }

      // Mirror for front camera
      if (isFront) {
        x = analysisImageSize!.width - x;
      }

      // Scale from analysis image coordinates to preview coordinates
      // This is the CRITICAL part that was missing
      double previewX = (x / analysisImageSize!.width) * previewSize.width;
      double previewY = (y / analysisImageSize!.height) * previewSize.height;

      // Scale from preview coordinates to screen coordinates
      double screenX = previewX * scaleX + offsetX;
      double screenY = previewY * scaleY + offsetY;

      return Offset(screenX, screenY);
    }

    for (final pose in poses) {
      for (final lm in pose.landmarks.values) {
        final p = transform(lm);
        canvas.drawCircle(p, 10, pointPaint);
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

    // Debug: Draw the actual preview area
    final debugPaint =
        Paint()
          ..color = Colors.blue.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    final previewRect = Rect.fromLTWH(
      offsetX,
      offsetY,
      previewSize.width * scaleX,
      previewSize.height * scaleY,
    );
    canvas.drawRect(previewRect, debugPaint);
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) =>
      oldDelegate.poses != poses ||
      oldDelegate.analysisImageSize != analysisImageSize;
}
