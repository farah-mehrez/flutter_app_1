import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'eleves_page.dart';
import 'presence_page.dart';
import 'emploi_page.dart';
import 'formateur.dart';
import 'events.dart';
import 'club.dart';
import 'notification.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Main App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const AndroidCompact(),
    );
  }
}

class AndroidCompact extends StatefulWidget {
  const AndroidCompact({super.key});

  @override
  State<AndroidCompact> createState() => _AndroidCompactState();
}

class _AndroidCompactState extends State<AndroidCompact>
    with SingleTickerProviderStateMixin {
  String searchQuery = '';
  late AnimationController _animationController;

  final List<_MenuItem> menuItems = [
    _MenuItem(
      label: 'Eleves',
      assetImagePath: 'assets/images/student.jpeg',
      onTap: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ElevesScreen()),
      ),
    ),
    _MenuItem(
      label: 'Formateurs',
      assetImagePath: 'assets/images/formateur.jpeg',
      onTap: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FormateursScreen()),
      ),
    ),
    _MenuItem(
      label: 'Emploi',
      assetImagePath: 'assets/images/emploi.jpeg',
      onTap: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EmploymentScheduleScreen()),
      ),
    ),
    _MenuItem(
      label: 'Presence',
      assetImagePath: 'assets/images/attendance.jpeg',
      onTap: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PresencePage()),
      ),
    ),
    _MenuItem(
      label: 'Events',
      assetImagePath: 'assets/images/events.jpeg',
      onTap: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EventsScreen()),
      ),
    ),
    _MenuItem(
      label: 'Club',
      assetImagePath: 'assets/images/club.jpeg',
      onTap: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ClubManagerScreen()),
      ),
    ),
    _MenuItem(
      label: 'Notifications',
      assetImagePath: 'assets/images/notification.jpeg',
      onTap: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NotificationsScreen()),
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = menuItems.where((item) {
      return item.label.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                '👋 Hello Amine !',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Recherche',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 30),
              Expanded(
                child: filteredItems.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun résultat pour "$searchQuery"',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : GridView.builder(
                        itemCount: filteredItems.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 20,
                              crossAxisSpacing: 20,
                              childAspectRatio: 0.95,
                            ),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final animation = CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(
                              (index / filteredItems.length),
                              1.0,
                              curve: Curves.easeOut,
                            ),
                          );
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: animation,
                              child: MenuButton(
                                label: item.label,
                                assetImagePath: item.assetImagePath,
                                onTap: () => item.onTap(context),
                              ),
                            ),
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

class _MenuItem {
  final String label;
  final String assetImagePath;
  final void Function(BuildContext) onTap;

  _MenuItem({
    required this.label,
    required this.assetImagePath,
    required this.onTap,
  });
}

class MenuButton extends StatefulWidget {
  final String label;
  final String assetImagePath;
  final VoidCallback onTap;

  const MenuButton({
    super.key,
    required this.label,
    required this.assetImagePath,
    required this.onTap,
  });

  @override
  State<MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<MenuButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _scale = 0.95;
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _scale = 1.0;
    });
  }

  void _onTapCancel() {
    setState(() {
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(widget.assetImagePath, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
