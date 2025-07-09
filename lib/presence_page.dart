import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class PresencePage extends StatefulWidget {
  const PresencePage({Key? key}) : super(key: key);

  @override
  State<PresencePage> createState() => _PresencePageState();
}

class _PresencePageState extends State<PresencePage> with TickerProviderStateMixin {
  String _searchQuery = '';
  String? selectedStudentId;
  String? selectedStudentName;
  List<Map<String, String>> matchedStudents = [];

  int currentYear = DateTime.now().year;
  int currentMonth = DateTime.now().month;

  Map<int, bool?> presenceMap = {};
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _searchStudents() async {
    if (_searchQuery.isEmpty) return;
    DatabaseEvent event = await _dbRef.child('students').once();
    final snapshot = event.snapshot;
    List<Map<String, String>> results = [];

    if (snapshot.exists) {
      Map<dynamic, dynamic> studentsMap = snapshot.value as Map;
      studentsMap.forEach((key, value) {
        if (value is Map && value.containsKey('name')) {
          String name = value['name'] ?? '';
          if (name.toLowerCase().contains(_searchQuery.toLowerCase())) {
            results.add({'id': key, 'name': name});
          }
        }
      });
    }

    setState(() {
      matchedStudents = results;
    });
  }

  void _loadPresenceData(String studentId) async {
    String docId = '${currentYear}-${currentMonth.toString().padLeft(2, '0')}';
    DatabaseEvent event = await _dbRef
        .child('presence')
        .child(studentId)
        .child(docId)
        .once();

    final snapshot = event.snapshot;
    if (snapshot.exists) {
      Map<dynamic, dynamic> data = snapshot.value as Map;
      Map<int, bool?> loadedPresence = {};
      data.forEach((key, value) {
        if (key.toString().startsWith('day_')) {
          int day = int.parse(key.toString().substring(4));
          loadedPresence[day] = value is bool
              ? value
              : (value.toString().toLowerCase() == 'true');
        }
      });
      setState(() {
        presenceMap = loadedPresence;
      });
    } else {
      setState(() {
        presenceMap.clear();
      });
    }
  }

  void _savePresenceData() async {
    if (selectedStudentId == null) return;
    String docId = '${currentYear}-${currentMonth.toString().padLeft(2, '0')}';
    Map<String, dynamic> saveData = {};

    presenceMap.forEach((day, value) {
      saveData['day_$day'] = value;
    });

    await _dbRef
        .child('presence')
        .child(selectedStudentId!)
        .child(docId)
        .set(saveData);
  }

  String _monthName(int month) {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return months[month - 1];
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(Colors.green.shade300, Icons.check, 'Présent'),
        const SizedBox(width: 20),
        _legendItem(Colors.red.shade300, Icons.close, 'Absent'),
        const SizedBox(width: 20),
        _legendItem(Colors.grey.shade300, Icons.help_outline, 'Non défini'),
      ],
    );
  }

  Widget _legendItem(Color color, IconData icon, String label) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.black12),
          ),
          child: Icon(icon, size: 14, color: Colors.black54),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildCalendar() {
    int totalDays = DateTime(currentYear, currentMonth + 1, 0).day;
    int firstWeekday = DateTime(currentYear, currentMonth, 1).weekday;
    int startOffset = firstWeekday - 1;

    int totalCells = totalDays + startOffset;
    if (totalCells % 7 != 0) {
      totalCells += 7 - (totalCells % 7);
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  if (currentMonth == 1) {
                    currentMonth = 12;
                    currentYear--;
                  } else {
                    currentMonth--;
                  }
                  presenceMap.clear();
                  if (selectedStudentId != null) {
                    _loadPresenceData(selectedStudentId!);
                  }
                });
              },
            ),
            Text(
              '${_monthName(currentMonth)} $currentYear',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  if (currentMonth == 12) {
                    currentMonth = 1;
                    currentYear++;
                  } else {
                    currentMonth++;
                  }
                  presenceMap.clear();
                  if (selectedStudentId != null) {
                    _loadPresenceData(selectedStudentId!);
                  }
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildLegend(),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            if (index < startOffset) return const SizedBox();
            int day = index - startOffset + 1;
            bool? status = presenceMap[day];
            Color bgColor = Colors.grey.shade300;
            IconData? icon;
            if (status == true) {
              bgColor = Colors.green.shade300;
              icon = Icons.check;
            }
            if (status == false) {
              bgColor = Colors.red.shade300;
              icon = Icons.close;
            }

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (presenceMap[day] == null) {
                    presenceMap[day] = true;
                  } else if (presenceMap[day] == true) {
                    presenceMap[day] = false;
                  } else {
                    presenceMap[day] = null;
                  }
                  _savePresenceData();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black12),
                ),
                child: Center(
                  child: icon != null
                      ? Icon(icon, color: Colors.black87, size: 20)
                      : Text(
                          '$day',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Présence par Élève'),
      ),
      body: FadeTransition(
        opacity: _fadeController,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Recherche d\'un élève',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (val) {
                  _searchQuery = val;
                },
                onSubmitted: (val) => _searchStudents(),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _searchStudents,
                icon: const Icon(Icons.search),
                label: const Text('Rechercher'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ...matchedStudents.map(
                (student) => Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(
                      student['name']!,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    onTap: () {
                      setState(() {
                        selectedStudentId = student['id'];
                        selectedStudentName = student['name'];
                        presenceMap.clear();
                      });
                      _loadPresenceData(student['id']!);
                    },
                    trailing: selectedStudentId == student['id']
                        ? const Icon(Icons.check_circle, color: Colors.teal)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (selectedStudentId != null) ...[
                Text(
                  'Présence de $selectedStudentName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildCalendar(),
              ] else ...[
                const SizedBox(height: 40),
                Image.asset('assets/images/cd.jpeg', height: 120),
                const SizedBox(height: 16),
                const Text(
                  'Recherchez un élève pour afficher son calendrier 📅',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                const Text(
                  '« L\'assiduité est le secret du succès. »',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.black38,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
