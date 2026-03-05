import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BinderMainScreen(),
    ));

class BinderMainScreen extends StatefulWidget {
  const BinderMainScreen({super.key});

  @override
  State<BinderMainScreen> createState() => _BinderMainScreenState();
}

class _BinderMainScreenState extends State<BinderMainScreen> {
  int _selectedIndex = 0;

  // The content for each page
  final List<Widget> _pages = [
    const Center(child: Text("Home Page", style: TextStyle(color: Colors.white, fontSize: 24))),
    const Center(child: Text("Scan Page", style: TextStyle(color: Colors.white, fontSize: 24))),
    const Center(child: Text("Browse Page", style: TextStyle(color: Colors.white, fontSize: 24))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Binder Dark Theme
      body: Stack(
        children: [
          // Background Content
          _pages[_selectedIndex],

          // Floating Liquid Glass Navigation
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