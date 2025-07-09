import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_database/firebase_database.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, List<Map<String, dynamic>>> _events = {};

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  String _selectedColor = 'red';

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('emploi');

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAllEvents();
  }

  String _formatDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  void _showAddEventDialog(DateTime date) {
    _titleController.clear();
    _timeController.clear();
    _selectedColor = 'red';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ajouter un événement"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(_titleController, "Nom de l'événement"),
            _buildTextField(_timeController, "Heure (ex: 08:00)"),
            const SizedBox(height: 10),
            InputDecorator(
              decoration: InputDecoration(
                labelText: "Couleur de l'événement",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedColor,
                  isExpanded: true,
                  items: ['red', 'green', 'blue', 'yellow']
                      .map((color) => DropdownMenuItem(
                            value: color,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: _getColorFromName(color),
                                  radius: 10,
                                ),
                                const SizedBox(width: 10),
                                Text(color[0].toUpperCase() + color.substring(1)),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedColor = value);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text("Enregistrer"),
            onPressed: () {
              _addEvent(date);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Future<void> _addEvent(DateTime date) async {
    final dateKey = _formatDateKey(date);
    final time = _timeController.text.trim();
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Le nom de l'événement est requis")));
      return;
    }

    if (time.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("L'heure est requise")));
      return;
    }

    try {
      await _dbRef.child(dateKey).child(time).set({
        'name': title,
        'color': _selectedColor,
        'time': time,
      });
      await _loadAllEvents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: ${e.toString()}")));
    }
  }

  Future<void> _deleteEvent(String dateKey, String time) async {
    try {
      await _dbRef.child(dateKey).child(time).remove();
      await _loadAllEvents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur de suppression: ${e.toString()}")));
    }
  }

  Future<void> _loadAllEvents() async {
    try {
      final snapshot = await _dbRef.get();
      final Map<String, List<Map<String, dynamic>>> loadedEvents = {};

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        data.forEach((dateKey, times) {
          final Map<String, dynamic> timeMap = Map<String, dynamic>.from(times);
          final eventList = <Map<String, dynamic>>[];

          timeMap.forEach((time, details) {
            eventList.add(Map<String, dynamic>.from(details));
          });

          loadedEvents[dateKey] = eventList;
        });
      }

      setState(() => _events = loadedEvents);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur de chargement: ${e.toString()}")));
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[_formatDateKey(day)] ?? [];
  }

  Widget _buildSelectedDayEvents(DateTime day) {
    final dateKey = _formatDateKey(day);
    final events = _events[dateKey] ?? [];

    if (events.isEmpty) {
      return const Center(
        child: Text(
          "Aucun événement ce jour",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final eventName = event['name'] as String? ?? 'Sans nom';
        final eventTime = event['time'] as String? ?? 'Heure non spécifiée';
        final colorName = event['color'] as String? ?? 'grey';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getColorFromName(colorName),
              radius: 20,
              child: const Icon(Icons.event, color: Colors.white),
            ),
            title: Text(eventName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Heure: $eventTime"),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () {
                if (eventTime.isNotEmpty) {
                  _deleteEvent(dateKey, eventTime);
                }
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emploi du Temps"),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        elevation: 4,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            eventLoader: _getEventsForDay,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.deepPurple.shade300,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.deepPurpleAccent,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  final firstEvent = events.first as Map<String, dynamic>;
                  final colorName = firstEvent['color'] as String? ?? 'grey';
                  return Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getColorFromName(colorName),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          )
                        ],
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _selectedDay != null
                ? _buildSelectedDayEvents(_selectedDay!)
                : const Center(child: Text("Sélectionnez un jour")),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        elevation: 6,
        onPressed: () {
          if (_selectedDay != null) _showAddEventDialog(_selectedDay!);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red.shade400;
      case 'green':
        return Colors.green.shade400;
      case 'blue':
        return Colors.blue.shade400;
      case 'yellow':
        return Colors.amber.shade400;
      default:
        return Colors.grey;
    }
  }
}
