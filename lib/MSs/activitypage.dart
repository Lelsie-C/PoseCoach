import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Activitypage extends StatelessWidget {
  const Activitypage({super.key});

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
              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: Colors.black,
                      ),
                      const SizedBox(height: 13),
                      const Text(
                        "Perfect your pose",
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
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: [
                      _activityap(
                        icon: FontAwesomeIcons.dumbbell,
                        label: "Dumbbell Rows",
                      ),
                      const SizedBox(height: 20),
                      _activityap(
                        icon: FontAwesomeIcons.dumbbell,
                        label: "Squat Training",
                      ),
                      const SizedBox(height: 20),
                      _activityap(
                        icon: FontAwesomeIcons.dumbbell,
                        label: "Pull-Ups",
                      ),
                      const SizedBox(height: 20),
                      _activityap(
                        icon: FontAwesomeIcons.dumbbell,
                        label: "Bench Press",
                      ),
                      const SizedBox(height: 20),
                      _activityap(
                        icon: FontAwesomeIcons.dumbbell,
                        label: "Lunges",
                      ),
                      const SizedBox(height: 20),
                      _activityap(
                        icon: FontAwesomeIcons.dumbbell,
                        label: "Leg Raises",
                      ),
                      const SizedBox(height: 20),
                      _activityap(
                        icon: FontAwesomeIcons.dumbbell,
                        label: "Overhead Press",
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Activity Card Widget
Widget _activityap({required IconData icon, required String label}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    decoration: BoxDecoration(
      color: Color.fromARGB(100, 76, 175, 80),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  colors: [Color(0xFF31782B), Color.fromARGB(80, 43, 120, 69)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds);
              },
              child: Icon(icon, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(40, 30),
            backgroundColor: const Color.fromARGB(50, 76, 175, 80),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            "Start",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
