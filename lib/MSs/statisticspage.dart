import 'package:flutter/material.dart';
import 'package:sugmps/utils/video_store.dart';
import 'package:sugmps/utils/videoplayer.dart';

class Statisticspage extends StatefulWidget {
  const Statisticspage({super.key});

  @override
  State<Statisticspage> createState() => _StatisticspageState();
}

class _StatisticspageState extends State<Statisticspage> {
  @override
  void initState() {
    super.initState();
    // load saved videos when the page opens
    loadVideosFromPrefs().then((_) {
      if (mounted) setState(() {});
    });
  }

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
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
              const SizedBox(height: 30),

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
                            // Ensure label includes index
                            final displayLabel =
                                video.label.contains(RegExp(r'\d'))
                                    ? video.label
                                    : "Workout Video ${index + 1}";
                            return _statisticsap(
                              context: context,
                              label: displayLabel,
                              path: video.path,
                              video: video,
                              onRefresh: () {
                                loadVideosFromPrefs().then((_) {
                                  if (mounted) setState(() {});
                                });
                              },
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
  required SavedVideo video,
  required VoidCallback onRefresh,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Row(
          children: [
            // Play button in same box style as Stats
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF31782B), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VideoPlayerScreen(videoPath: path),
                  ),
                );
              },
              child: Row(
                children: const [
                  Icon(Icons.play_arrow, color: Color(0xFF31782B)),
                  SizedBox(width: 6),
                  Text(
                    "Play",
                    style: TextStyle(
                      color: Color(0xFF31782B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Stats button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF31782B), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => _showStatsDialog(ctx, video, onRefresh),
                );
              },
              child: Row(
                children: const [
                  Icon(Icons.bar_chart, color: Color(0xFF31782B)),
                  SizedBox(width: 6),
                  Text(
                    "Stats",
                    style: TextStyle(
                      color: Color(0xFF31782B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _showStatsDialog(
  BuildContext context,
  SavedVideo video,
  VoidCallback onRefresh,
) {
  return Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    video.label,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Grade circular
            SizedBox(
              height: 120,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: (video.grade / 100).clamp(0.0, 1.0),
                        strokeWidth: 10,
                        color: const Color(0xFF31782B),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${video.grade}%",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text("Grade"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Stats rows
            _statRow("Total reps", video.reps.toString()),
            const SizedBox(height: 8),
            _statRow("Good reps", video.goodReps.toString()),
            const SizedBox(height: 8),
            _statRow("Accuracy", "${video.accuracy.toStringAsFixed(1)}%"),
            const SizedBox(height: 14),

            // Notes
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Notes",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(20, 43, 120, 69),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color.fromARGB(50, 43, 120, 69),
                      ),
                    ),
                    child: Text(
                      video.notes.isEmpty ? "No notes" : video.notes,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Close"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF31782B),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onRefresh();
                  },
                  child: const Text("Done"),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _statRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54)),
      Text(
        value,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ],
  );
}
