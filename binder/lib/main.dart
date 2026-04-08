import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:camera/camera.dart'; // import the package
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';
import 'package:binder/doc_scanner_capture_screen.dart';
import 'package:binder/doc_detail_screen.dart';
import 'package:binder/loading_screen.dart';

Future<void> main() async {
  // Ensure the app initializes properly
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const BinderApp());
}

class BinderApp extends StatelessWidget {
  const BinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Binder',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        cupertinoOverrideTheme: const CupertinoThemeData(
          brightness: Brightness.dark,
          primaryColor: Color(0xFF007AFF),
        ),
      ),
      home: BinderLoadingScreen(nextScreen: BinderMainScreen()),
    );
  }
}

class BinderMainScreen extends StatefulWidget {
  const BinderMainScreen({super.key});

  @override
  State<BinderMainScreen> createState() => _BinderMainScreenState();
}

class _BinderMainScreenState extends State<BinderMainScreen> {
  int _selectedIndex = 0;
  bool _isSearchActive = false;
  final List<Map<String, dynamic>> _savedDocuments = [];

  // The simplified body switcher
 Widget _getBody() {
  switch (_selectedIndex) {
    case 0:
      return HomeContent(documents: _savedDocuments);
    case 1:
      return HomeContent(documents: _savedDocuments);
    case 2:
      return BrowseContent(
        documents: _savedDocuments,
        autoFocusSearch: _isSearchActive,
      );
    default:
      return const SizedBox();
  }
}

  Future<void> _openScannerFlow() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocScannerCaptureScreen(
          onDocumentSaved: (savedDocument) {
            setState(() {
              _savedDocuments.add(savedDocument);
              _selectedIndex = 2;
            });
          },
        ),
      ),
    );

    if (!mounted) return;
    setState(() {
      if (_savedDocuments.isNotEmpty) {
        _selectedIndex = 2;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Stack(
        children: [
          _getBody(),

          if (_selectedIndex != 1) 
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: GlassNavigation(
                  selectedIndex: _selectedIndex,
                  onTap: (index) {
                    if (index == 1) {
                      _openScannerFlow();
                      return;
                    }
                    setState(() {
                      _selectedIndex = index;
                      _isSearchActive = false;
                    });
                  },
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
class HomeContent extends StatelessWidget {
  const HomeContent({super.key, required this.documents});

  final List<Map<String, dynamic>> documents;

  DateTime? _readDocumentDate(Map<String, dynamic> doc, String key) {
    final value = doc[key];
    if (value is DateTime) return value;
    return null;
  }

  Widget _buildGlassContainer({required Widget child, double? height}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: height,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildExpireRow(Map<String, dynamic> doc, bool isLast) {
    final expiry = doc['expiryDate'] as DateTime;
    final int daysLeft = expiry.difference(DateTime.now()).inDays;
    final String dateString = DateFormat('MMMM dd, yyyy').format(expiry);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0.0 : 15.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(CupertinoIcons.car_fill, color: Color(0xFF007AFF), size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc['name'] as String? ?? 'Untitled',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(dateString, style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          Text('$daysLeft Days', style: const TextStyle(color: Color(0xFFFF9500), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRecentItem(Map<String, dynamic> doc, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => DocDetailScreen(
              documentFile: doc['file'] as File,
              documentName: doc['name'] as String? ?? 'Untitled',
            ),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(image: FileImage(doc['file'] as File), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 50,
            child: Text(
              doc['name'] as String? ?? 'Untitled',
              style: const TextStyle(color: Colors.white60, fontSize: 10),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRecentSlot() {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
        ),
        const SizedBox(height: 6),
        const SizedBox(width: 50, height: 12),
      ],
    );
  }

  Widget _buildListCard(String title, List<Map<String, dynamic>> docs, BuildContext context) {
    return _buildGlassContainer(
      height: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white60, fontSize: 14)),
          const SizedBox(height: 15),
          docs.isEmpty
              ? const Expanded(
                  child: Center(
                    child: Text('No items found', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ),
                )
              : Column(
                  children: docs
                      .map(
                        (doc) => GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => DocDetailScreen(
                                  documentFile: doc['file'] as File,
                                  documentName: doc['name'] as String? ?? 'Untitled',
                                ),
                              ),
                            );
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 15.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc['name'] as String? ?? 'Untitled',
                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat('dd.MM.yyyy').format(
                                          _readDocumentDate(doc, 'dateScanned') ??
                                              _readDocumentDate(doc, 'savedAt') ??
                                              DateTime.now(),
                                        ),
                                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(CupertinoIcons.doc, color: Colors.white24, size: 16),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedByRecents = List<Map<String, dynamic>>.from(documents)
      ..sort((a, b) {
        final aDate = _readDocumentDate(a, 'dateScanned') ?? _readDocumentDate(a, 'savedAt') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = _readDocumentDate(b, 'dateScanned') ?? _readDocumentDate(b, 'savedAt') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    final recentScans = sortedByRecents.take(5).toList();
    final workScans = sortedByRecents.where((doc) => (doc['category'] as String? ?? '') == 'Work').take(3).toList();
    final personalScans = sortedByRecents.where((doc) => (doc['category'] as String? ?? '') == 'Personal').take(3).toList();

    final expirations = documents
        .where((doc) {
          final expiry = _readDocumentDate(doc, 'expiryDate');
          return expiry != null && expiry.isAfter(DateTime.now());
        })
        .toList()
      ..sort((a, b) {
        final aExpiry = _readDocumentDate(a, 'expiryDate') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bExpiry = _readDocumentDate(b, 'expiryDate') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aExpiry.compareTo(bExpiry);
      });

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            const Text('Welcome back,', style: TextStyle(color: Colors.white60, fontSize: 18)),
            const Text('Gebo', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            const Text('Expires Soon', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildGlassContainer(
              child: expirations.isEmpty
                  ? const Center(
                      child: Text('No expiring documents.', style: TextStyle(color: Colors.white38, fontSize: 14)),
                    )
                  : Column(
                      children: expirations.take(3).toList().asMap().entries.map((entry) {
                        final isLast = entry.key == (expirations.take(3).length - 1);
                        return _buildExpireRow(entry.value, isLast);
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 25),
            _buildGlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recents', style: TextStyle(color: Colors.white60, fontSize: 14)),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(5, (index) {
                      if (index < recentScans.length) {
                        return _buildRecentItem(recentScans[index], context);
                      }
                      return _buildEmptyRecentSlot();
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildListCard('Personal', personalScans, context)),
                const SizedBox(width: 15),
                Expanded(child: _buildListCard('Work', workScans, context)),
              ],
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}

class BrowseContent extends StatefulWidget {
  final List<Map<String, dynamic>> documents;
  final bool autoFocusSearch;

  const BrowseContent({
    super.key,
    required this.documents,
    this.autoFocusSearch = false,
  });

  @override
  State<BrowseContent> createState() => _BrowseContentState();
}

class _BrowseContentState extends State<BrowseContent> {
  String _activeFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchingActive = false;
  List<Map<String, dynamic>> _displayDocuments = [];

  @override
  void initState() {
    super.initState();
    _displayDocuments = List<Map<String, dynamic>>.from(widget.documents);

    _searchFocusNode.addListener(() {
      if (!mounted) return;
      setState(() {
        _isSearchingActive = _searchFocusNode.hasFocus;
      });
    });

    if (widget.autoFocusSearch) {
      _requestSearchFocusSoon();
    }
  }

  @override
  void didUpdateWidget(covariant BrowseContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.autoFocusSearch && widget.autoFocusSearch) {
      _requestSearchFocusSoon();
    }
    if (oldWidget.documents != widget.documents) {
      _runFilter(_searchController.text);
    }
  }

  void _requestSearchFocusSoon() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(_searchFocusNode);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _runFilter(String enteredKeyword) {
    List<Map<String, dynamic>> results;
    final query = enteredKeyword.trim().toLowerCase();

    if (query.isEmpty) {
      results = List<Map<String, dynamic>>.from(widget.documents);
    } else {
      results = widget.documents.where((doc) {
        final name = (doc['name'] as String? ?? '').toLowerCase();
        return name.contains(query);
      }).toList();
    }

    if (_activeFilter != 'All') {
      results = results.where((doc) => doc['category'] == _activeFilter).toList();
    }

    setState(() {
      _displayDocuments = results;
    });
  }

  void _applyCategoryFilter(String category) {
    setState(() {
      _activeFilter = category;
    });
    _runFilter(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Search',
              style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            CupertinoSearchTextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              placeholder: 'Search documents',
              style: const TextStyle(color: Colors.white),
              placeholderStyle: const TextStyle(color: Colors.white30),
              itemColor: CupertinoColors.systemGrey,
              backgroundColor: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(15),
              padding: const EdgeInsets.all(12),
              onChanged: _runFilter,
              onSubmitted: _runFilter,
            ),

            if (!_isSearchingActive && _searchController.text.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 15.0, bottom: 20.0),
                child: Row(
                  children: [
                    _buildFilterButton(CupertinoIcons.list_bullet, 'All'),
                    const SizedBox(width: 10),
                    _buildFilterButton(CupertinoIcons.briefcase_fill, 'Work'),
                    const SizedBox(width: 10),
                    _buildFilterButton(CupertinoIcons.person_fill, 'Personal'),
                  ],
                ),
              ),

            if (_isSearchingActive || _searchController.text.isNotEmpty)
              const SizedBox(height: 20),

            Expanded(
              child: _displayDocuments.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: _displayDocuments.length,
                      itemBuilder: (context, index) {
                        final doc = _displayDocuments[index];
                        final originalIndex = widget.documents.indexOf(doc);
                        return _buildDocumentCard(context, doc, originalIndex);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(IconData icon, String label) {
    bool isSelected = _activeFilter == label;
    return GestureDetector(
      onTap: () => _applyCategoryFilter(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white24 : Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.white30 : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white60, size: 16),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white60)),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, Map<String, dynamic> doc, int index) {
    final File realImageFile = doc['file'] as File;
    final DateTime savedAt = (doc['savedAt'] as DateTime?) ?? DateTime.now();
    final String saveDate =
        '${savedAt.day.toString().padLeft(2, '0')}.${savedAt.month.toString().padLeft(2, '0')}.${savedAt.year}';
    final String category = doc['category'] as String? ?? 'Scanned';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => DocDetailScreen(
              documentFile: realImageFile,
              documentName: doc['name'] as String? ?? 'Untitled',
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(image: FileImage(realImageFile), fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc['name'] as String? ?? 'Untitled',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$saveDate • $category',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showActionMenu(context, doc, index),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Icon(CupertinoIcons.ellipsis_vertical, color: Colors.white38, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showActionMenu(BuildContext context, Map<String, dynamic> doc, int index) {
    final File documentFile = doc['file'] as File;
    final String documentName = doc['name'] as String? ?? 'Untitled';

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext popupContext) => CupertinoActionSheet(
        title: Text(documentName),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            child: const Text('Edit Scan'),
            onPressed: () async {
              Navigator.pop(popupContext);

              final croppedFile = await ImageCropper().cropImage(
                sourcePath: documentFile.path,
                uiSettings: [
                  IOSUiSettings(
                    title: 'Edit Document',
                    doneButtonTitle: 'Done',
                    cancelButtonTitle: 'Cancel',
                    aspectRatioLockEnabled: false,
                    aspectRatioPresets: [
                      CropAspectRatioPreset.original,
                      CropAspectRatioPreset.ratio4x3,
                    ],
                  ),
                ],
              );

              if (!mounted) return;
              if (croppedFile != null && index >= 0 && index < widget.documents.length) {
                setState(() {
                  widget.documents[index]['file'] = File(croppedFile.path);
                });
                _runFilter(_searchController.text);
              }
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Move Category'),
            onPressed: () {
              Navigator.pop(popupContext);
              _showCategoryPicker(doc, index);
            },
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () {
              Navigator.pop(popupContext);
              if (index < 0 || index >= widget.documents.length) return;

              setState(() {
                widget.documents.removeAt(index);
              });
              _runFilter(_searchController.text);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(popupContext),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showCategoryPicker(Map<String, dynamic> doc, int index) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext popupContext) => CupertinoActionSheet(
        title: const Text('Select Category'),
        message: const Text('Move this document to a new category.'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            child: const Text('Work'),
            onPressed: () {
              if (index >= 0 && index < widget.documents.length) {
                setState(() {
                  widget.documents[index]['category'] = 'Work';
                });
                _runFilter(_searchController.text);
              }
              Navigator.pop(popupContext);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Personal'),
            onPressed: () {
              if (index >= 0 && index < widget.documents.length) {
                setState(() {
                  widget.documents[index]['category'] = 'Personal';
                });
                _runFilter(_searchController.text);
              }
              Navigator.pop(popupContext);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(popupContext),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool hasQuery = _searchController.text.trim().isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasQuery ? CupertinoIcons.search : CupertinoIcons.folder_open,
            color: Colors.white10,
            size: 60,
          ),
          const SizedBox(height: 20),
          Text(
            hasQuery ? "No matching files for\n'${_searchController.text}'" : 'No files saved yet.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white24, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class SearchButton extends StatelessWidget {
  const SearchButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: const Icon(
            CupertinoIcons.search,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}