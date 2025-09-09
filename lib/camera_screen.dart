import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'video_store.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras; // cameras are passed in
  const CameraScreen({super.key, required this.cameras});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  bool _isRecording = false;
  String? _videoPath;

  @override
  void initState() {
    super.initState();

    // Use front camera if available, otherwise first camera
    final frontCamera =
        widget.cameras.length > 1 ? widget.cameras[1] : widget.cameras[0];

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: true,
    );

    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _startRecording() async {
    try {
      await _controller.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      debugPrint("Error starting recording: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      final file = await _controller.stopVideoRecording();

      final dir = await getApplicationDocumentsDirectory();
      final newPath =
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';

      // Save permanently
      final savedFile = await File(file.path).copy(newPath);

      setState(() {
        _isRecording = false;
        _videoPath = savedFile.path;

        // Add to global list
        savedVideos.add(
          SavedVideo(
            label: "Workout Video ${savedVideos.length + 1}",
            path: savedFile.path,
          ),
        );
      });

      // Persist the updated list
      await saveVideosToPrefs();

      // Play video immediately
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(videoPath: _videoPath!),
        ),
      );
    } catch (e) {
      debugPrint("Error stopping recording: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Video Recorder")),
      body: CameraPreview(_controller),
      floatingActionButton: FloatingActionButton(
        onPressed: _isRecording ? _stopRecording : _startRecording,
        child: Icon(_isRecording ? Icons.stop : Icons.videocam),
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;

  const VideoPlayerScreen({super.key, required this.videoPath});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _videoController.play();
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Playback")),
      body: Center(
        child:
            _videoController.value.isInitialized
                ? AspectRatio(
                  aspectRatio: _videoController.value.aspectRatio,
                  child: VideoPlayer(_videoController),
                )
                : const CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _videoController.value.isPlaying
                ? _videoController.pause()
                : _videoController.play();
          });
        },
        child: Icon(
          _videoController.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
