import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sugmps/utils/routes.dart'; // Make sure this contains your AppRoutes

class Homepage extends StatelessWidget {
  const Homepage({super.key});

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
                      const SizedBox(height: 13),
                      const Text("Hey there!", style: TextStyle(fontSize: 22)),
                      const SizedBox(height: 10),
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
                    radius: 35,
                    backgroundImage: AssetImage('assets/wo_image.png'),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Warm-up Card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(100, 76, 175, 80),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(50, 76, 175, 80),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Warm up",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Jumping Jacks",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 50),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(40, 30),
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            "Start",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Image.asset("assets/wo_image.png", width: 165, height: 180),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Popular Exercises Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Popular Exercises",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(25, 76, 175, 80),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text(
                      "4",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 76, 175, 80),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 35),

              // Horizontal Scroll of Exercise Cards
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    _activitymp(
                      context,
                      icon: FontAwesomeIcons.dumbbell,
                      label: "Squat Training",
                      wolabel: "5 Workouts",
                      time: "45min",
                    ),
                    const SizedBox(width: 10),
                    _activitymp(
                      context,
                      icon: FontAwesomeIcons.dumbbell,
                      label: "Pull-Ups",
                      wolabel: "20 Workouts",
                      time: "1hr",
                    ),
                    const SizedBox(width: 10),
                    _activitymp(
                      context,
                      icon: FontAwesomeIcons.dumbbell,
                      label: "Bench Press",
                      wolabel: "20 Workouts",
                      time: "1hr",
                    ),
                    const SizedBox(width: 10),
                    _activitymp(
                      context,
                      icon: FontAwesomeIcons.dumbbell,
                      label: "Leg Raises",
                      wolabel: "20 Workouts",
                      time: "1hr",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _activitymp(
  BuildContext context, { // added context parameter
  required IconData icon,
  required String label,
  required String wolabel,
  required String time,
}) {
  // Determine the route based on label
  String route;
  if (label == "Squat Training" || label == "Pull-Ups") {
    route = AppRoutes.squatdetection;
  } else {
    route = AppRoutes.notyetavailable;
  }

  return InkWell(
    onTap: () {
      Navigator.pushNamed(context, route);
    },
    child: Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color.fromARGB(128, 41, 103, 45),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
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
            child: Icon(icon, size: 30, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 7),
          Text(wolabel, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 45),
          Text("Accuracy", style: TextStyle(color: Colors.black)),
          Row(
            children: [
              const Icon(Icons.timelapse, size: 15, color: Colors.black54),
              const SizedBox(width: 5),
              Text(
                time,
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
