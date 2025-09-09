import 'package:flutter/material.dart';
import 'package:sugmps/camera_screen.dart';
import 'package:sugmps/video_store.dart';

class Statisticspage extends StatefulWidget {
  const Statisticspage({super.key});

  @override
  State<Statisticspage> createState() => _StatisticspageState();
}

class _StatisticspageState extends State<Statisticspage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.arrow_back, size: 20, color: Colors.black),
                      SizedBox(height: 13),
                      Text(
                        "Statistics",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const CircleAvatar(
                    radius: 25,
                    backgroundImage: AssetImage('assets/wo_image.png'),
                  ),
                ],
              ),
              const SizedBox(height: 35),

              // Dynamic video list
              Expanded(
                child:
                    savedVideos.isEmpty
                        ? const Center(
                          child: Text(
                            "No videos recorded yet",
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                        : ListView.separated(
                          itemCount: savedVideos.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 20),
                          itemBuilder: (context, index) {
                            final video = savedVideos[index];
                            return _statisticsap(
                              context: context,
                              label: video.label,
                              path: video.path,
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _statisticsap({
  required BuildContext context,
  required String label,
  required String path,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: const Color.fromARGB(128, 41, 103, 45),
        width: 2,
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VideoPlayerScreen(videoPath: path),
              ),
            );
          },
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                colors: [Color(0xFF31782B), Color.fromARGB(80, 43, 120, 69)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds);
            },
            child: const Icon(Icons.play_arrow, size: 40, color: Colors.white),
          ),
        ),
      ],
    ),
  );
}
