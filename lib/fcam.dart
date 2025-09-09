import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:vector_math/vector_math.dart' as vmath;
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Squat Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SquatTrackerScreen(),
    );
  }
}

class SquatTrackerScreen extends StatefulWidget {
  @override
  _SquatTrackerScreenState createState() => _SquatTrackerScreenState();
}

class _SquatTrackerScreenState extends State<SquatTrackerScreen> {
  // Camera and ML variables
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isModelLoaded = false;
  bool _isInferencing = false;

  // TFLite Interpreter
  Interpreter? _interpreter;

  // Squat tracking variables
  int _repCount = 0;
  String _squatState = "UP";
  String _feedback = "Move into view";
  double _downThreshold = 100;
  double _upThreshold = 160;
  int _inferenceStride = 2;
  int _frameCount = 0;
  DateTime _lastRepTime = DateTime.now();

  // Keypoint tracking
  List<dynamic> _keypoints = [];
  List<List<dynamic>> _keypointHistory = [];
  int _smoothingWindow = 5;

  // FPS tracking
  int _fps = 0;
  DateTime _lastFpsTime = DateTime.now();
  int _framesProcessed = 0;

  // Debug mode
  bool _debugMode = false;
  String _debugInfo = "";

  @override
  void initState() {
    super.initState();
    _keepScreenOn();
    _initializeCamera();
    _testAssetLoading(); // Test asset loading first
    _loadModel();
  }

  void _keepScreenOn() {
    // Keep screen awake and set preferred orientation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _interpreter?.close();

    // Restore normal screen behavior
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    super.dispose();
  }

  Future<void> _testAssetLoading() async {
    try {
      // Test if asset loading works at all
      final data = await rootBundle.load('assets/movenet.tflite');
      final bytes = data.buffer.asUint8List();
      print('✅ Asset loading test: File size = ${bytes.length} bytes');

      if (bytes.isEmpty) {
        print('❌ File is empty!');
      } else if (bytes.length != 2700136) {
        print('❌ File size mismatch. Expected: 2700136, Got: ${bytes.length}');
      } else {
        print('✅ File size matches expected value (2700136 bytes)');
      }
    } catch (e) {
      print('❌ Asset loading test failed: $e');
    }
  }

  Future<bool> _verifyModelFile() async {
    try {
      final ByteData data = await rootBundle.load('assets/movenet.tflite');
      final bytes = data.buffer.asUint8List();

      print('File size: ${bytes.length} bytes');

      if (bytes.isEmpty) {
        print('❌ File is empty!');
        return false;
      }

      if (bytes.length != 2700136) {
        print('❌ File size mismatch. Expected: 2700136, Got: ${bytes.length}');
        return false;
      }

      print('✅ File integrity check passed');
      return true;
    } catch (e) {
      print('❌ File verification failed: $e');
      return false;
    }
  }

  Future<void> _loadModel() async {
    try {
      print('Attempting to load model...');

      // First verify the file
      final isFileValid = await _verifyModelFile();
      if (!isFileValid) {
        throw Exception('Model file verification failed');
      }

      // Method 1: Try direct asset loading
      try {
        print('Trying Interpreter.fromAsset()...');
        _interpreter = await Interpreter.fromAsset('movenet.tflite');
        print('✅ Model loaded successfully using fromAsset()');
      } catch (e) {
        print('❌ fromAsset() failed: $e');

        // Method 2: Try loading from buffer
        try {
          print('Trying Interpreter.fromBuffer()...');
          final ByteData data = await rootBundle.load('assets/movenet.tflite');
          final bytes = data.buffer.asUint8List();

          if (bytes.isEmpty) {
            throw Exception('File is empty');
          }

          _interpreter = await Interpreter.fromBuffer(bytes);
          print('✅ Model loaded successfully using fromBuffer()');
        } catch (e2) {
          print('❌ fromBuffer() also failed: $e2');
          throw Exception('All loading methods failed: ${e2.toString()}');
        }
      }

      // If we get here, model loaded successfully
      print('Input shape: ${_interpreter!.getInputTensor(0).shape}');
      print('Output shape: ${_interpreter!.getOutputTensor(0).shape}');

      setState(() {
        _isModelLoaded = true;
        _feedback = "Model loaded - ready for squats";
      });
    } catch (e) {
      print("❌ All model loading attempts failed: $e");

      // Continue without model for testing
      setState(() {
        _isModelLoaded = true;
        _feedback = "Camera mode - ML model not available";
      });

      // Add dummy keypoints for UI testing
      _addDummyKeypoints();
    }
  }

  void _addDummyKeypoints() {
    // Add some dummy keypoints for testing the UI
    List<dynamic> dummyKeypoints = [];
    for (int i = 0; i < 17; i++) {
      dummyKeypoints.add({
        'y': 0.3 + i * 0.04, // Spread them out vertically
        'x': 0.5,
        'score': i < 6 ? 0.2 : 0.8, // Mix of low and high confidence
      });
    }

    setState(() {
      _keypoints = dummyKeypoints;
      _keypointHistory.add(dummyKeypoints);
    });
  }

  Future<void> _initializeCamera() async {
    // Check camera permission
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        print("Camera permission denied");
        setState(() {
          _feedback = "Camera permission required";
        });
        return;
      }
    }

    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) {
      print("No cameras found");
      setState(() {
        _feedback = "No camera available";
      });
      return;
    }

    // Use FRONT camera instead of back camera
    CameraDescription? frontCamera;
    try {
      frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
    } catch (e) {
      print("No front camera found, using back camera instead");
      frontCamera = _cameras!.first;
    }

    // Use the front camera
    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.low, // Use low resolution for better performance
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
        _feedback = "Camera ready - move into view";
      });

      // Start inference loop
      _startInferenceLoop();
    } catch (e) {
      print("Camera initialization failed: $e");
      setState(() {
        _feedback = "Camera error: ${e.toString()}";
      });
    }
  }

  // Preprocess image for MoveNet model
  List<List<List<List<double>>>> _preprocessImage(Uint8List imageBytes) {
    try {
      // Decode the image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Get model input shape
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final inputHeight = inputShape[1];
      final inputWidth = inputShape[2];

      // Resize image to model input size
      final resizedImage = img.copyResize(
        image,
        width: inputWidth,
        height: inputHeight,
      );

      // Convert to the format expected by MoveNet (normalized to [-1, 1] or [0, 1])
      // MoveNet typically expects input normalized to [-1, 1]
      final input = List.generate(
        1,
        (_) => List.generate(
          inputHeight,
          (y) => List.generate(inputWidth, (x) {
            final pixel = resizedImage.getPixel(x, y);
            return [
              (pixel.r / 127.5) - 1.0, // Normalize R to [-1, 1]
              (pixel.g / 127.5) - 1.0, // Normalize G to [-1, 1]
              (pixel.b / 127.5) - 1.0, // Normalize B to [-1, 1]
            ];
          }),
        ),
      );

      return input;
    } catch (e) {
      print('Error preprocessing image: $e');
      // Fallback to placeholder
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final inputHeight = inputShape[1];
      final inputWidth = inputShape[2];

      return List.generate(
        1,
        (_) => List.generate(
          inputHeight,
          (_) => List.generate(inputWidth, (_) => List.generate(3, (_) => 0.0)),
        ),
      );
    }
  }

  void _startInferenceLoop() {
    Future.doWhile(() async {
      if (!_isCameraInitialized || !_isModelLoaded || _isInferencing) {
        await Future.delayed(Duration(milliseconds: 10));
        return true;
      }

      // If no interpreter (model failed to load), just skip inference
      if (_interpreter == null) {
        await Future.delayed(Duration(milliseconds: 100));
        return true;
      }

      // Process every Nth frame based on stride
      _frameCount++;
      if (_frameCount % _inferenceStride != 0) {
        await Future.delayed(Duration(milliseconds: 1));
        return true;
      }

      setState(() {
        _isInferencing = true;
      });

      try {
        // Get camera image
        final image = await _cameraController!.takePicture();
        final bytes = await image.readAsBytes();

        // DEBUG: Print that we're processing a frame
        if (_debugMode) {
          print('Processing frame ${DateTime.now()}');
        }

        // Run inference using tflite_flutter
        var input = _preprocessImage(bytes);
        var output = List.filled(
          _interpreter!.getOutputTensor(0).shape.reduce((a, b) => a * b),
          0,
        ).reshape(_interpreter!.getOutputTensor(0).shape);

        _interpreter!.run(input, output);

        // DEBUG: Print output summary
        if (_debugMode) {
          print('Output received: ${output.length} elements');
          if (output.isNotEmpty && output[0] is List) {
            print('First keypoint: ${output[0][0]}');
          }
        }

        // Parse keypoints
        final keypoints = _parseKeypoints(output);

        // DEBUG: Print keypoints info
        if (_debugMode) {
          print('Parsed ${keypoints.length} keypoints');
          if (keypoints.isNotEmpty) {
            print('First keypoint score: ${keypoints[0]['score']}');
          }
        }

        setState(() {
          _keypoints = keypoints;
          _keypointHistory.add(keypoints);

          // Keep only the smoothing window size
          if (_keypointHistory.length > _smoothingWindow) {
            _keypointHistory.removeAt(0);
          }

          // Update FPS
          _framesProcessed++;
          final now = DateTime.now();
          if (now.difference(_lastFpsTime).inSeconds >= 1) {
            _fps = _framesProcessed;
            _framesProcessed = 0;
            _lastFpsTime = now;
          }

          // Analyze squat if we have enough keypoints
          if (_keypointHistory.length >= 2) {
            _analyzeSquat();
          }
        });
      } catch (e) {
        print("Inference error: $e");
        if (_debugMode) {
          setState(() {
            _debugInfo = "Inference error: ${e.toString()}";
          });
        }
      }

      setState(() {
        _isInferencing = false;
      });

      return true;
    });
  }

  List<dynamic> _parseKeypoints(List<dynamic> output) {
    List<dynamic> keypoints = [];

    try {
      // Handle different MoveNet output formats
      // Format 1: [1, 1, 17, 3] - most common
      // Format 2: [1, 17, 3]
      // Format 3: [17, 3]

      if (output is List && output.length > 0) {
        // Check if it's format [1, 1, 17, 3]
        if (output[0] is List && output[0][0] is List) {
          final keypointsData = output[0][0]; // Get the [17, 3] array
          for (int i = 0; i < 17; i++) {
            if (i < keypointsData.length) {
              final y = keypointsData[i][0].toDouble();
              final x = keypointsData[i][1].toDouble();
              final confidence = keypointsData[i][2].toDouble();
              keypoints.add({'y': y, 'x': x, 'score': confidence});
            }
          }
        }
        // Check if it's format [1, 17, 3]
        else if (output[0] is List && output[0].length >= 17) {
          final keypointsData = output[0]; // Get the [17, 3] array
          for (int i = 0; i < 17; i++) {
            final y = keypointsData[i][0].toDouble();
            final x = keypointsData[i][1].toDouble();
            final confidence = keypointsData[i][2].toDouble();
            keypoints.add({'y': y, 'x': x, 'score': confidence});
          }
        }
        // Check if it's format [17, 3]
        else if (output.length >= 17) {
          for (int i = 0; i < 17; i++) {
            final y = output[i][0].toDouble();
            final x = output[i][1].toDouble();
            final confidence = output[i][2].toDouble();
            keypoints.add({'y': y, 'x': x, 'score': confidence});
          }
        }
      }

      // DEBUG: Print keypoint confidence scores
      if (_debugMode && keypoints.isNotEmpty) {
        print('Keypoint confidence scores:');
        String debugText = "Keypoints: ";
        for (int i = 0; i < keypoints.length; i++) {
          if (keypoints[i]['score'] > 0.1) {
            // Only print reasonably confident points
            debugText += "$i:${keypoints[i]['score'].toStringAsFixed(2)} ";
          }
        }
        setState(() {
          _debugInfo = debugText;
        });
      }
    } catch (e) {
      print("Error parsing keypoints: $e");
      if (_debugMode) {
        setState(() {
          _debugInfo = "Keypoint error: ${e.toString()}";
        });
      }
    }

    return keypoints;
  }

  void _analyzeSquat() {
    if (_keypointHistory.isEmpty) return;

    // Get smoothed keypoints
    final smoothedKeypoints = _smoothKeypoints(_keypointHistory);

    // Check if required keypoints are detected
    final requiredIndices = [11, 12, 13, 14, 15, 16]; // Hips, knees, ankles
    bool allDetected = true;

    for (final idx in requiredIndices) {
      if (idx >= smoothedKeypoints.length ||
          smoothedKeypoints[idx]['score'] < 0.35) {
        allDetected = false;
        break;
      }
    }

    if (!allDetected) {
      setState(() {
        _feedback = "Move into view - ensure hips, knees and ankles visible";
      });
      return;
    }

    // Calculate knee angles
    final leftHip = smoothedKeypoints[11];
    final rightHip = smoothedKeypoints[12];
    final leftKnee = smoothedKeypoints[13];
    final rightKnee = smoothedKeypoints[14];
    final leftAnkle = smoothedKeypoints[15];
    final rightAnkle = smoothedKeypoints[16];

    final leftAngle = _calculateAngle(
      vmath.Vector2(leftHip['x'], leftHip['y']),
      vmath.Vector2(leftKnee['x'], leftKnee['y']),
      vmath.Vector2(leftAnkle['x'], leftAnkle['y']),
    );

    final rightAngle = _calculateAngle(
      vmath.Vector2(rightHip['x'], rightHip['y']),
      vmath.Vector2(rightKnee['x'], rightKnee['y']),
      vmath.Vector2(rightAnkle['x'], rightAnkle['y']),
    );

    final avgAngle = (leftAngle + rightAngle) / 2;

    // Update state based on angle thresholds
    final now = DateTime.now();

    setState(() {
      if (_squatState == "UP" && avgAngle < _downThreshold) {
        _squatState = "DOWN";
        _feedback = "Squat down";
      } else if (_squatState == "DOWN" && avgAngle > _upThreshold) {
        _squatState = "UP";
        _repCount++;
        _lastRepTime = now;
        _feedback = "Good rep! ($_repCount)";
      } else if (now.difference(_lastRepTime).inSeconds > 3) {
        _feedback = "Hold position";
      }
    });
  }

  List<dynamic> _smoothKeypoints(List<List<dynamic>> history) {
    if (history.isEmpty) return [];

    // Simple averaging for smoothing
    List<dynamic> smoothed = List.from(history[0]);

    for (int i = 1; i < history.length; i++) {
      for (int j = 0; j < history[i].length; j++) {
        if (j < smoothed.length) {
          smoothed[j]['x'] = (smoothed[j]['x'] + history[i][j]['x']) / 2;
          smoothed[j]['y'] = (smoothed[j]['y'] + history[i][j]['y']) / 2;
          smoothed[j]['score'] =
              (smoothed[j]['score'] + history[i][j]['score']) / 2;
        }
      }
    }

    return smoothed;
  }

  double _calculateAngle(vmath.Vector2 a, vmath.Vector2 b, vmath.Vector2 c) {
    // Calculate angle between three points using vector math
    final ba = a - b;
    final bc = c - b;

    final cosine = ba.dot(bc) / (ba.length * bc.length + 1e-6);
    final radians = acos(cosine.clamp(-1.0, 1.0));
    return radians * 180 / pi;
  }

  void _resetCounter() {
    setState(() {
      _repCount = 0;
      _feedback = "Counter reset";
    });
  }

  void _adjustStride(int change) {
    setState(() {
      _inferenceStride = max(1, min(6, _inferenceStride + change));
    });
  }

  void _testModel() async {
    if (_interpreter == null) {
      print('Model not loaded');
      setState(() {
        _debugInfo = 'Model not loaded';
      });
      return;
    }

    print('Testing model...');
    setState(() {
      _debugInfo = 'Testing model...';
    });

    // Create a test input (all zeros)
    final inputShape = _interpreter!.getInputTensor(0).shape;
    final testInput = List.filled(
      inputShape.reduce((a, b) => a * b),
      0.0,
    ).reshape(inputShape);

    try {
      var output = List.filled(
        _interpreter!.getOutputTensor(0).shape.reduce((a, b) => a * b),
        0,
      ).reshape(_interpreter!.getOutputTensor(0).shape);

      _interpreter!.run(testInput, output);

      print('Model test successful');
      print('Output shape: ${output.shape}');

      String debugOutput = 'Model test successful\n';
      debugOutput += 'Output shape: [${output.shape.join(', ')}]\n';

      if (output.isNotEmpty && output[0] is List && output[0].isNotEmpty) {
        debugOutput +=
            'First values: ${output[0][0].toString().substring(0, 50)}...';
      }

      setState(() {
        _debugInfo = debugOutput;
      });
    } catch (e) {
      print('Model test failed: $e');
      setState(() {
        _debugInfo = 'Model test failed: ${e.toString()}';
      });
    }
  }

  void _toggleDebugMode() {
    setState(() {
      _debugMode = !_debugMode;
      if (!_debugMode) {
        _debugInfo = "";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Squat Tracker'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetCounter,
            tooltip: 'Reset counter',
          ),
          IconButton(
            icon: Icon(Icons.bug_report),
            onPressed: _testModel,
            tooltip: 'Test model',
          ),
          IconButton(
            icon: Icon(_debugMode ? Icons.code_off : Icons.code),
            onPressed: _toggleDebugMode,
            tooltip: 'Toggle debug mode',
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          // Empty gesture detector to prevent touch issues
        },
        child: Stack(
          children: [
            // Camera preview - flipped horizontally for front camera
            if (_isCameraInitialized)
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(pi), // Flip horizontally
                child: CameraPreview(_cameraController!),
              )
            else
              Center(child: CircularProgressIndicator()),

            // Overlay with keypoints and info
            CustomPaint(
              painter: KeypointPainter(
                keypoints: _keypoints,
                squatState: _squatState,
                isFrontCamera: true,
              ),
              child: Container(),
            ),

            // Info panel
            Positioned(
              bottom: _debugMode ? 100 : 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.black.withOpacity(0.6),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _feedback,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Reps: $_repCount',
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            'FPS: $_fps',
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            'Stride: $_inferenceStride',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () => _adjustStride(1),
                            child: Text('+ Stride'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              padding: EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _adjustStride(-1),
                            child: Text('- Stride'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              padding: EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Debug info panel
            if (_debugMode && _debugInfo.isNotEmpty)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Card(
                  color: Colors.black.withOpacity(0.8),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      _debugInfo,
                      style: TextStyle(color: Colors.yellow, fontSize: 12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class KeypointPainter extends CustomPainter {
  final List<dynamic> keypoints;
  final String squatState;
  final bool isFrontCamera;

  KeypointPainter({
    required this.keypoints,
    required this.squatState,
    this.isFrontCamera = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (keypoints.isEmpty) return;

    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    final pointPaint = Paint()..style = PaintingStyle.fill;

    // Define skeleton connections
    const skeleton = [
      (0, 1), (0, 2), (1, 3), (2, 4), // Head
      (5, 6), (5, 7), (7, 9), (6, 8), (8, 10), // Arms
      (5, 11), (6, 12), (11, 12), // Shoulders & hips
      (11, 13), (13, 15), (12, 14), (14, 16), // Legs
    ];

    // Draw skeleton connections
    for (final connection in skeleton) {
      final i1 = connection.$1;
      final i2 = connection.$2;

      if (i1 < keypoints.length && i2 < keypoints.length) {
        final kp1 = keypoints[i1];
        final kp2 = keypoints[i2];

        if (kp1['score'] > 0.35 && kp2['score'] > 0.35) {
          // Set color based on squat state
          if (squatState == "DOWN") {
            paint.color = const Color.fromARGB(
              255,
              255,
              100,
              100,
            ); // Red when squatting down
          } else {
            paint.color = const Color.fromARGB(
              255,
              100,
              255,
              100,
            ); // Green when standing up
          }

          // Mirror x coordinates if using front camera
          final x1 =
              isFrontCamera
                  ? (1 - kp1['x']) *
                      size
                          .width // Mirror for front camera
                  : kp1['x'] * size.width; // Normal for back camera
          final y1 = kp1['y'] * size.height;

          final x2 =
              isFrontCamera
                  ? (1 - kp2['x']) *
                      size
                          .width // Mirror for front camera
                  : kp2['x'] * size.width; // Normal for back camera
          final y2 = kp2['y'] * size.height;

          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
        }
      }
    }

    // Draw keypoints (only critical ones for performance)
    const criticalPoints = [11, 12, 13, 14, 15, 16]; // Hips, knees, ankles
    for (final i in criticalPoints) {
      if (i < keypoints.length) {
        final kp = keypoints[i];
        if (kp['score'] > 0.35) {
          pointPaint.color = const Color.fromARGB(
            255,
            0,
            0,
            255,
          ); // Blue for critical points

          // Mirror x coordinate if using front camera
          final x =
              isFrontCamera
                  ? (1 - kp['x']) *
                      size
                          .width // Mirror for front camera
                  : kp['x'] * size.width; // Normal for back camera
          final y = kp['y'] * size.height;

          canvas.drawCircle(Offset(x, y), 5.0, pointPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
