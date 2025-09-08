import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MoveNet Flutter Demo',
    home: const PoseHomePage(),
    debugShowCheckedModeBanner: false,
  );
}

class PoseHomePage extends StatefulWidget {
  const PoseHomePage({super.key});

  @override
  State<PoseHomePage> createState() => _PoseHomePageState();
}

class _PoseHomePageState extends State<PoseHomePage> {
  CameraController? _cameraController;
  Interpreter? _interpreter;
  bool _isProcessing = false;
  int _frameCounter = 0;
  final int _frameSkip = 3; // Process every 4th frame

  final int inputSize = 192;
  final int smoothingWindow = 3;
  final List<List<double>> _kpHistory = [];

  List<List<double>> keypoints = List.generate(17, (_) => [0.0, 0.0, 0.0]);
  int repCount = 0;
  String feedback = "Move into view";
  String debugInfo = "Initializing...";

  String squatState = "UP";
  final double downThreshold = 90.0;
  final double upThreshold = 160.0;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadModel();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final camera = cameras.isNotEmpty ? cameras.first : throw ("No camera");
      _cameraController = CameraController(
        camera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _cameraController!.initialize();
      await _cameraController!.startImageStream(_processCameraImage);
      setState(() {
        debugInfo = "Camera initialized";
      });
    } catch (e) {
      debugPrint("Camera init error: $e");
      setState(() {
        debugInfo = "Camera error: $e";
      });
    }
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/movenet.tflite',
      );
      debugPrint("Interpreter loaded successfully");

      final inputTensors = _interpreter!.getInputTensors();
      final outputTensors = _interpreter!.getOutputTensors();
      debugPrint("Input tensors: $inputTensors");
      debugPrint("Output tensors: $outputTensors");

      setState(() {
        debugInfo = "Model loaded - Input: ${inputTensors.first.type}";
      });
    } catch (e) {
      debugPrint("Error loading model: $e");
      setState(() {
        debugInfo = "Model error: ${e.toString()}";
      });
    }
  }

  Future<void> _processCameraImage(CameraImage camImage) async {
    if (_isProcessing || _interpreter == null) return;

    // Skip more frames for better performance
    _frameCounter++;
    if (_frameCounter % _frameSkip != 0) return;

    _isProcessing = true;

    try {
      // FAST conversion directly to input tensor
      final input = _fastConvertYUV420ToInputTensor(camImage, inputSize);
      final inputTensor = input.reshape([1, inputSize, inputSize, 3]);

      final output = List.filled(1 * 1 * 17 * 3, 0.0).reshape([1, 1, 17, 3]);
      _interpreter!.run(inputTensor, output);

      // DEBUG: Print raw output values occasionally
      if (_frameCounter % 20 == 0) {
        for (int i = 0; i < 3; i++) {
          debugPrint(
            "KP $i: x=${output[0][0][i][0]?.toStringAsFixed(3)}, "
            "y=${output[0][0][i][1]?.toStringAsFixed(3)}, "
            "conf=${output[0][0][i][2]?.toStringAsFixed(3)}",
          );
        }
      }

      // Extract keypoints
      List<List<double>> kp = List.generate(
        17,
        (i) => [
          output[0][0][i][1] ?? 0.0, // y coordinate
          output[0][0][i][0] ?? 0.0, // x coordinate
          output[0][0][i][2] ?? 0.0, // confidence
        ],
      );

      // Debug info
      final maxConfidence = kp.map((point) => point[2]).reduce(math.max);
      final confidentKeypoints = kp.where((point) => point[2] > 0.3).length;

      setState(() {
        debugInfo =
            "Max conf: ${maxConfidence.toStringAsFixed(3)}\n"
            "Good points: $confidentKeypoints/17";
      });

      // Smoothing
      _kpHistory.add(kp.expand((e) => e).toList());
      if (_kpHistory.length > smoothingWindow) _kpHistory.removeAt(0);

      if (_kpHistory.isNotEmpty) {
        List<double> avgFlat = List.filled(17 * 3, 0.0);
        for (var hist in _kpHistory) {
          for (int i = 0; i < avgFlat.length; i++) {
            avgFlat[i] += hist[i];
          }
        }
        for (int i = 0; i < avgFlat.length; i++) {
          avgFlat[i] /= _kpHistory.length;
        }

        List<List<double>> kpAvg = List.generate(
          17,
          (i) => [avgFlat[i * 3], avgFlat[i * 3 + 1], avgFlat[i * 3 + 2]],
        );

        // Check if keypoints are confident enough
        final List<int> required = [11, 12, 13, 14, 15, 16, 5, 6];
        final bool confident = required.every((idx) => kpAvg[idx][2] > 0.3);

        if (confident) {
          // Convert normalized coordinates to image coordinates
          final double ih = camImage.height.toDouble();
          final double iw = camImage.width.toDouble();
          List<List<double>> pts =
              kpAvg
                  .map(
                    (p) => [
                      p[0] * ih, // y * image height
                      p[1] * iw, // x * image width
                      p[2], // confidence
                    ],
                  )
                  .toList();

          final leftHip = pts[11], rightHip = pts[12];
          final leftKnee = pts[13], rightKnee = pts[14];
          final leftAnkle = pts[15], rightAnkle = pts[16];

          double leftKneeAngle = _angle(leftHip, leftKnee, leftAnkle);
          double rightKneeAngle = _angle(rightHip, rightKnee, rightAnkle);
          double avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2.0;

          setState(() {
            debugInfo += "\nAngle: ${avgKneeAngle.toStringAsFixed(1)}°";
          });

          if (squatState == "UP" && avgKneeAngle < downThreshold) {
            setState(() {
              squatState = "DOWN";
              feedback = "Squat down";
            });
          } else if (squatState == "DOWN" && avgKneeAngle > upThreshold) {
            setState(() {
              squatState = "UP";
              repCount += 1;
              feedback = "Good rep!";
            });
          } else {
            setState(() {
              feedback = "Hold position";
            });
          }
        } else {
          setState(() {
            feedback = "Move full body into view";
          });
        }

        setState(() => keypoints = kpAvg);
      }
    } catch (e) {
      debugPrint("Processing error: $e");
    } finally {
      _isProcessing = false;
    }
  }

  // HIGH-SPEED YUV to Input Tensor conversion
  Int32List _fastConvertYUV420ToInputTensor(CameraImage image, int targetSize) {
    final input = Int32List(targetSize * targetSize * 3);
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBuffer = yPlane.bytes;
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;

    final yStride = yPlane.bytesPerRow;
    final uvStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;

    final scaleX = image.width / targetSize;
    final scaleY = image.height / targetSize;

    int inputIndex = 0;

    for (int y = 0; y < targetSize; y++) {
      final srcY = (y * scaleY).toInt();

      for (int x = 0; x < targetSize; x++) {
        final srcX = (x * scaleX).toInt();

        final yIndex = srcY * yStride + srcX;
        final uvIndex = (srcY ~/ 2) * uvStride + (srcX ~/ 2) * uvPixelStride;

        if (yIndex < yBuffer.length &&
            uvIndex < uBuffer.length &&
            uvIndex < vBuffer.length) {
          final yValue = yBuffer[yIndex];
          final uValue = uBuffer[uvIndex] - 128;
          final vValue = vBuffer[uvIndex] - 128;

          // YUV to RGB conversion
          final r = (yValue + 1.402 * vValue).round().clamp(0, 255);
          final g = (yValue - 0.344 * uValue - 0.714 * vValue).round().clamp(
            0,
            255,
          );
          final b = (yValue + 1.772 * uValue).round().clamp(0, 255);

          input[inputIndex++] = r;
          input[inputIndex++] = g;
          input[inputIndex++] = b;
        } else {
          // Fill with zeros if out of bounds
          input[inputIndex++] = 0;
          input[inputIndex++] = 0;
          input[inputIndex++] = 0;
        }
      }
    }

    return input;
  }

  double _angle(List<double> a, List<double> b, List<double> c) {
    final baX = a[0] - b[0];
    final baY = a[1] - b[1];
    final bcX = c[0] - b[0];
    final bcY = c[1] - b[1];

    final dot = baX * bcX + baY * bcY;
    final magBA = math.sqrt(baX * baX + baY * baY);
    final magBC = math.sqrt(bcX * bcX + bcY * bcY);

    final cosAngle = dot / (magBA * magBC + 1e-6);
    final angle = math.acos(cosAngle.clamp(-1.0, 1.0)) * 180.0 / math.pi;

    return angle;
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text("MoveNet Squat Tracker")),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),
          CustomPaint(painter: PosePainter(keypoints), child: Container()),
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black54,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Reps: $repCount",
                    style: const TextStyle(fontSize: 20, color: Colors.yellow),
                  ),
                  Text(
                    feedback,
                    style: const TextStyle(fontSize: 18, color: Colors.red),
                  ),
                  Text(
                    debugInfo,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PosePainter extends CustomPainter {
  final List<List<double>> keypoints;
  PosePainter(this.keypoints);

  static const List<List<int>> skeleton = [
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

  @override
  void paint(Canvas canvas, Size size) {
    final paintPoint =
        Paint()
          ..style = PaintingStyle.fill
          ..strokeWidth = 4.0;

    final paintLine =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..color = Colors.green;

    // Draw skeleton lines
    for (var edge in skeleton) {
      final a = keypoints[edge[0]];
      final b = keypoints[edge[1]];
      if (a[2] > 0.1 && b[2] > 0.1) {
        final p1 = Offset(a[1] * size.width, a[0] * size.height);
        final p2 = Offset(b[1] * size.width, b[0] * size.height);
        canvas.drawLine(p1, p2, paintLine);
      }
    }

    // Draw keypoints
    for (int i = 0; i < keypoints.length; i++) {
      final kp = keypoints[i];
      if (kp[2] > 0.1) {
        paintPoint.color = Colors.red.withOpacity(kp[2].clamp(0.1, 1.0));
        final p = Offset(kp[1] * size.width, kp[0] * size.height);
        canvas.drawCircle(p, 6.0, paintPoint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) => true;
}
