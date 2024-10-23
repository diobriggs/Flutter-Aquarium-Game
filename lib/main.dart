import 'package:flutter/material.dart';
import 'dart:math';
import 'database_helper.dart'; // Import the DBHelper class

void main() => runApp(AquariumApp());

class AquariumApp extends StatelessWidget {
  const AquariumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aquarium',
      home: AquariumScreen(),
    );
  }
}

class AquariumScreen extends StatefulWidget {
  const AquariumScreen({super.key});

  @override
  _AquariumScreenState createState() => _AquariumScreenState();
}

class _AquariumScreenState extends State<AquariumScreen> with TickerProviderStateMixin {
  List<Fish> fishList = [];
  double fishSpeed = 1.0;
  Color selectedColor = Colors.blue;
  final dbHelper = DBHelper.instance; // Use singleton instance of DBHelper

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final settings = await dbHelper.loadSettings();
    setState(() {
      if (settings != null) {
        fishSpeed = settings['fishSpeed'] ?? 1.0;
        int colorInt = settings['fishColor'] ?? Colors.blue.value;
        Color loadedColor = Color(colorInt); // Retrieve color from stored int value
        int fishCount = settings['fishCount'] ?? 0;

        // Ensure the loaded color is part of the available options
        if (loadedColor == Colors.blue ||
            loadedColor == Colors.red ||
            loadedColor == Colors.green ||
            loadedColor == Colors.purple) {
          selectedColor = loadedColor;
        } else {
          selectedColor = Colors.blue; // Fallback to a default color
        }

        // Add saved fish to the aquarium
        for (int i = 0; i < fishCount; i++) {
          fishList.add(Fish(
            color: selectedColor,
            speed: fishSpeed,
            vsync: this, // Pass TickerProviderStateMixin for vsync
            aquariumWidth: 300,
            aquariumHeight: 300,
          ));
        }
      }
    });
  }

  Future<void> saveSettings() async {
    await dbHelper.saveSettings(fishSpeed, selectedColor.value, fishList.length);
  }

  void addFish() {
    if (fishList.length < 10) { // Check if fish count is less than 10
      setState(() {
        fishList.add(Fish(
          color: selectedColor,
          speed: fishSpeed,
          vsync: this, // Pass TickerProviderStateMixin for vsync
          aquariumWidth: 300,
          aquariumHeight: 300,
        ));
      });
    } else {
      // Show a snackbar or alert if the limit is reached
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only add up to 10 fish!')),
      );
    }
  }

  void removeFish() {
    if (fishList.isNotEmpty) {
      setState(() {
        fishList.removeLast(); // Remove the last fish from the list
      });
    } else {
      // Show a snackbar or alert if there are no fish to remove
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fish to remove!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aquarium'),
      ),
      body: Column(
        children: [
          // Aquarium Container
          Container(
            width: 300,
            height: 300,
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueAccent),
              color: Colors.lightBlueAccent.withOpacity(0.5),
            ),
            child: Stack(
              children: fishList.map((fish) => fish.buildFish(context)).toList(),
            ),
          ),
          // Slider for Fish Speed
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Fish Speed: ${fishSpeed.toStringAsFixed(1)}"),
                Slider(
                  value: fishSpeed,
                  min: 0.5,
                  max: 5.0,
                  divisions: 10,
                  label: fishSpeed.toStringAsFixed(1),
                  onChanged: (double value) {
                    setState(() {
                      fishSpeed = value;
                    });
                  },
                ),
              ],
            ),
          ),
          // Dropdown for Fish Color
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<Color>(
              value: selectedColor,
              items: const [
                DropdownMenuItem(
                  value: Colors.blue,
                  child: Text('Blue', style: TextStyle(color: Colors.blue)),
                ),
                DropdownMenuItem(
                  value: Colors.red,
                  child: Text('Red', style: TextStyle(color: Colors.red)),
                ),
                DropdownMenuItem(
                  value: Colors.green,
                  child: Text('Green', style: TextStyle(color: Colors.green)),
                ),
                DropdownMenuItem(
                  value: Colors.purple,
                  child: Text('Purple', style: TextStyle(color: Colors.purple)),
                ),
              ],
              onChanged: (Color? newColor) {
                setState(() {
                  selectedColor = newColor!;
                });
              },
            ),
          ),
          // Buttons for Adding and Removing Fish and Saving Settings
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: addFish,
                  child: const Text('Add Fish'),
                ),
                ElevatedButton(
                  onPressed: removeFish, // Add remove fish functionality
                  child: const Text('Remove Fish'),
                ),
                ElevatedButton(
                  onPressed: saveSettings,
                  child: const Text('Save Settings'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Fish {
  Color color;
  double speed;
  late AnimationController _controller;
  double x = 0;
  double y = 0;
  double velocityX; 
  double velocityY;
  double aquariumWidth;
  double aquariumHeight;

  final Random random = Random();

  Fish({
    required this.color,
    required this.speed,
    required TickerProvider vsync,
    required this.aquariumWidth,
    required this.aquariumHeight,
  })  : velocityX = 0, // Temporary initialization
        velocityY = 0, // Temporary initialization
        x = 0,         // Temporary initialization
        y = 0          // Temporary initialization
  {
    // Initialize velocities and positions in the constructor body
    velocityX = (random.nextDouble() * 2 - 1) * speed;
    velocityY = (random.nextDouble() * 2 - 1) * speed;
    x = random.nextDouble() * aquariumWidth;
    y = random.nextDouble() * aquariumHeight;

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: vsync,
    )..repeat(); // Continuously repaint

    _controller.addListener(updatePosition); // Update position on each frame
  }

  void updatePosition() {
    x += velocityX;
    y += velocityY;

    // Bounce off the walls by reversing direction when hitting edges
    if (x <= 0 || x >= aquariumWidth - 30) { // 30 is the fish size
      velocityX = -velocityX;
    }
    if (y <= 0 || y >= aquariumHeight - 30) { // 30 is the fish size
      velocityY = -velocityY;
    }
  }

  Widget buildFish(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: x,
          top: y,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
