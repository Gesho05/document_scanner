import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:camera/camera.dart'; // import the package

// A global list to store available cameras
late List<CameraDescription> _cameras;

Future<void> main() async {
  // Ensure the app initializes properly
  WidgetsFlutterBinding.ensureInitialized();
  
  // Get a list of the available cameras (like front/back)
  _cameras = await availableCameras();
  
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: BinderMainScreen(),
  ));
}

class BinderMainScreen extends StatefulWidget {
  const BinderMainScreen({super.key});

  @override
  State<BinderMainScreen> createState() => _BinderMainScreenState();
}

class _BinderMainScreenState extends State<BinderMainScreen> {
  int _selectedIndex = 0;

  // The simplified body switcher
 Widget _getBody() {
  switch (_selectedIndex) {
    case 0:
      return const HomeContent(); // Use the new widget here
    case 1:
      // Safety Check: If the list is empty (like in a simulator), show a message instead
      if (_cameras.isEmpty) {
        return const Center(
          child: Text(
            "No Camera Found\n(Use a real device)", 
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        );
      }
      return CameraPage(camera: _cameras.first); 
    case 2:
      return const Center(child: Text("Browse Page", style: TextStyle(color: Colors.white, fontSize: 24)));
    default:
      return const SizedBox();
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Stack(
        children: [
          // Background content (like the camera preview)
          _getBody(),
          
          // Only show the navigation bar if the camera page IS NOT active
          if (_selectedIndex != 1) 
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: GlassNavigation(
                  selectedIndex: _selectedIndex,
                  onTap: (index) => setState(() => _selectedIndex = index),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --- NEW CAMERA PAGE WIDGET ---
class CameraPage extends StatefulWidget {
  final CameraDescription camera;
  const CameraPage({super.key, required this.camera});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController controller;

  @override
  void initState() {
    super.initState();
    // 1. Setup the controller for the specific camera (rear camera)
    controller = CameraController(widget.camera, ResolutionPreset.max);
    
    // 2. Initialize it and redraw the screen when ready
    controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    // Very important: Always dispose of the camera when you leave
    controller.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading spinner until the lens is ready
    if (!controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // This creates the clean UI from your Figma prototype
    return Stack(
      children: [
        // 1. The full-screen live camera preview
        SizedBox.expand(child: CameraPreview(controller)),
        
        // 2. Back Button (Top Left)
        Positioned(
          top: 60,
          left: 30,
          child: GestureDetector(
            onTap: () {
              // Simple way to go "Back" by forcing the parent state change
              context.findAncestorStateOfType<_BinderMainScreenState>()?.setState(() {
                 context.findAncestorStateOfType<_BinderMainScreenState>()?._selectedIndex = 0; 
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(CupertinoIcons.back, color: Colors.white, size: 28),
            ),
          ),
        ),
        
        // 3. Capture Button (Bottom Center)
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: GestureDetector(
              onTap: () async {
                try {
                  // Capture a still photo
                  final image = await controller.takePicture();
                  print("Photo captured: ${image.path}"); 
                } catch (e) {
                  print("Error taking photo: $e");
                }
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 6),
                ),
                child: const Center(
                  child: Icon(CupertinoIcons.camera_fill, color: Colors.white, size: 30),
                ),
              ),
            ),
          ),
        ),
        
        // 4. Save Button (Bottom Right)
        Positioned(
          bottom: 75,
          right: 30,
          child: GestureDetector(
            onTap: () {
              // This does nothing for now as requested
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFC48B3F), // A gold/brown matching your prototype
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }
}
class GlassNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const GlassNavigation({super.key, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Keep your bar width at 260 for that "longer" prototype look
    double barWidth = 260; 
    double itemWidth = barWidth / 3;

    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 60, // Your preferred sleek height
          width: barWidth,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Stack(
            children: [
              // Sliding background pill
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                left: selectedIndex * itemWidth + 5,
                top: 5, // 5px from top
                child: Container(
                  width: itemWidth - 10,
                  height: 50, // This keeps the pill centered vertically (5px top + 50px height + 5px bottom = 60px)
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              // THE FIX: Wrap the Row in a Center widget to align icons vertically
              Center(
                child: Row(
                  children: [
                    _buildNavItem(CupertinoIcons.house_fill, "Home", 0),
                    _buildNavItem(CupertinoIcons.viewfinder, "Scan", 1),
                    _buildNavItem(CupertinoIcons.folder_fill, "Browse", 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min, // Constrains the column to take minimum height
          mainAxisAlignment: MainAxisAlignment.center, // Centers icon and text together
          children: [
            Icon(
              icon, 
              color: isSelected ? const Color(0xFF007AFF) : Colors.white60, 
              size: 20, // Slightly smaller for the sleek look
            ),
            const SizedBox(height: 2),
            Text(
              label, 
              style: TextStyle(
                color: isSelected ? const Color(0xFF007AFF) : Colors.white60,
                fontSize: 9, // Slightly smaller font to avoid yellow overflow
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// Add this new class at the bottom of your main.dart
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            // Welcome Header
            const Text("Welcome back,", 
              style: TextStyle(color: Colors.white60, fontSize: 18)),
            const Text("Gebo", 
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            
            const SizedBox(height: 40),
            
            // "Expires Soon" Section
            const Text("Expires Soon", 
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            
            // Bento Grid Card (Matching your Figma "Warranty of car")
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E), // Dark card grey
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(CupertinoIcons.car_fill, color: Color(0xFF007AFF)),
                  ),
                  const SizedBox(width: 15),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Warranty of car", 
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text("March 23, 2026", 
                        style: TextStyle(color: Colors.white60, fontSize: 14)),
                    ],
                  ),
                  const Spacer(),
                  const Text("3 Days", 
                    style: TextStyle(color: Color(0xFFFF9500), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}