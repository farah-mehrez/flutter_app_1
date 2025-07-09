import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: EmploymentScheduleScreen(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins', primarySwatch: Colors.deepPurple),
    );
  }
}

class EmploymentScheduleScreen extends StatefulWidget {
  @override
  _EmploymentScheduleScreenState createState() =>
      _EmploymentScheduleScreenState();
}

class _EmploymentScheduleScreenState extends State<EmploymentScheduleScreen> {
  final Map<String, bool> _collapsedState = {
    "Lundi": true,
    "Mardi": true,
    "Mercredi": true,
    "Jeudi": true,
    "Vendredi": true,
    "Samedi": true,
    "Dimanche": true,
  };

  Map<String, Map<String, dynamic>> emploiData = {};
  bool isLoading = true;
  DateTime _currentWeekStart = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday - 1),
  );

  @override
  void initState() {
    super.initState();
    fetchEmploiData();
  }

  Future<void> fetchEmploiData() async {
    try {
      final ref = FirebaseDatabase.instance.ref("emploi");
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          emploiData = data.map(
            (day, times) =>
                MapEntry(day, Map<String, dynamic>.from(times as Map)),
          );
          isLoading = false;
        });
      } else {
        print("No data found for emploi!");
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      print("Error fetching data: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getDayName(DateTime date) {
    switch (date.weekday) {
      case 1:
        return "Lundi";
      case 2:
        return "Mardi";
      case 3:
        return "Mercredi";
      case 4:
        return "Jeudi";
      case 5:
        return "Vendredi";
      case 6:
        return "Samedi";
      case 7:
        return "Dimanche";
      default:
        return "";
    }
  }

  String _getMonthName(DateTime date) {
    switch (date.month) {
      case 1:
        return "Janvier";
      case 2:
        return "Février";
      case 3:
        return "Mars";
      case 4:
        return "Avril";
      case 5:
        return "Mai";
      case 6:
        return "Juin";
      case 7:
        return "Juillet";
      case 8:
        return "Août";
      case 9:
        return "Septembre";
      case 10:
        return "Octobre";
      case 11:
        return "Novembre";
      case 12:
        return "Décembre";
      default:
        return "";
    }
  }

  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: 7));
    });
  }

  @override
  Widget build(BuildContext context) {
    // Generate dates for the current week
    List<DateTime> weekDates = [];
    for (int i = 0; i < 7; i++) {
      weekDates.add(_currentWeekStart.add(Duration(days: i)));
    }

    // Calculate end date for the week range
    final endDate = _currentWeekStart.add(Duration(days: 6));

    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with week navigation
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Text(
                              "Emploi du Temps",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.calendar_today,
                                color: Colors.white,
                              ),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.arrow_back_ios,
                                size: 18,
                                color: Colors.white,
                              ),
                              onPressed: _previousWeek,
                            ),
                            Text(
                              "${_currentWeekStart.day} ${_getMonthName(_currentWeekStart)} - ${endDate.day} ${_getMonthName(endDate)}",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.arrow_forward_ios,
                                size: 18,
                                color: Colors.white,
                              ),
                              onPressed: _nextWeek,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Weekday headers
                  Container(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 7,
                      itemBuilder: (context, index) {
                        final date = weekDates[index];
                        final isToday = isSameDay(date, DateTime.now());
                        return Container(
                          width: MediaQuery.of(context).size.width / 7,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isToday
                                    ? Colors.deepPurple
                                    : Colors.grey[300]!,
                                width: isToday ? 3 : 1,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getDayName(date).substring(0, 3),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isToday
                                      ? Colors.deepPurple
                                      : Colors.grey,
                                ),
                              ),
                              Text(
                                date.day.toString(),
                                style: TextStyle(
                                  color: isToday
                                      ? Colors.deepPurple
                                      : Colors.black,
                                  fontWeight: isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Schedule content
                  Expanded(
                    child: ListView.builder(
                      itemCount: 7,
                      itemBuilder: (context, index) {
                        final date = weekDates[index];
                        final dayName = _getDayName(date);
                        return _buildDayScheduleContainer(dayName, date);
                      },
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.deepPurple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  Widget _buildDayScheduleContainer(String day, DateTime date) {
    bool isCollapsed = _collapsedState[day] ?? true;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Toggle
          InkWell(
            onTap: () {
              setState(() {
                _collapsedState[day] = !isCollapsed;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$day ${date.day} ${_getMonthName(date)}",
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.deepPurple.withOpacity(0.1),
                    ),
                    child: Icon(
                      isCollapsed ? Icons.expand_more : Icons.expand_less,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Schedule rows
          if (!isCollapsed) ..._buildScheduleDetails(day),
        ],
      ),
    );
  }

  List<Widget> _buildScheduleDetails(String day) {
    final times = emploiData[day] ?? {};
    final sortedTimes = times.keys.toList()..sort();

    if (sortedTimes.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "Aucun événement prévu",
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ),
      ];
    }

    return sortedTimes.map((time) {
      final value = times[time];
      final name = value['name'] ?? '';
      final colorString = value['color'] ?? 'grey';
      final color = _getColorFromName(colorString);

      return _buildScheduleRow(time, color, name);
    }).toList();
  }

  Widget _buildScheduleRow(String time, Color color, String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 16),
          Container(
            width: 60,
            child: Text(
              time,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 4),
                Text(
                  "Salle 203",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Color _getColorFromName(String name) {
    switch (name.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'pink':
        return Colors.pink;
      case 'yellow':
        return Colors.amber;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
