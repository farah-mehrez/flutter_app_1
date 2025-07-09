import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ClubData {
  String id;
  String name;
  String responsable;
  String price;
  String groupCount;
  String salle;

  ClubData({
    this.id = '',
    required this.name,
    required this.responsable,
    required this.price,
    required this.groupCount,
    required this.salle,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'responsable': responsable,
      'price': price,
      'groupCount': groupCount,
      'salle': salle,
    };
  }
}

class ClubManagerScreen extends StatefulWidget {
  const ClubManagerScreen({Key? key}) : super(key: key);

  @override
  State<ClubManagerScreen> createState() => _ClubManagerScreenState();
}

class _ClubManagerScreenState extends State<ClubManagerScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseReference clubsRef = FirebaseDatabase.instance.ref().child('clubs');
  List<ClubData> _clubs = [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _responsableController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _groupController = TextEditingController();
  final TextEditingController _salleController = TextEditingController();

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadClubs();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadClubs() {
    clubsRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final Map<String, dynamic> clubMap = Map<String, dynamic>.from(data);
        final loadedClubs = clubMap.entries.map((entry) {
          final clubData = Map<String, dynamic>.from(entry.value);
          return ClubData(
            id: entry.key,
            name: clubData['name'] ?? '',
            responsable: clubData['responsable'] ?? '',
            price: clubData['price'] ?? '',
            groupCount: clubData['groupCount'] ?? '',
            salle: clubData['salle'] ?? '',
          );
        }).toList();

        setState(() {
          _clubs = loadedClubs;
          _animationController.forward(from: 0);
        });
      } else {
        setState(() {
          _clubs = [];
        });
      }
    });
  }

  Future<void> _addClub(ClubData club) async {
    await clubsRef.push().set(club.toMap());
  }

  Future<void> _removeClub(String id) async {
    await clubsRef.child(id).remove();
  }

  void _showAddClubDialog() {
    _nameController.clear();
    _responsableController.clear();
    _priceController.clear();
    _groupController.clear();
    _salleController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ajouter un club"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField(_nameController, "Nom du club"),
              _buildTextField(_responsableController, "Responsable"),
              _buildTextField(_priceController, "Prix"),
              _buildTextField(_groupController, "Nombre de groupes"),
              _buildTextField(_salleController, "Salle"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text("Ajouter"),
            onPressed: () {
              if (_nameController.text.trim().isNotEmpty) {
                final newClub = ClubData(
                  name: _nameController.text.trim(),
                  responsable: _responsableController.text.trim(),
                  price: _priceController.text.trim(),
                  groupCount: _groupController.text.trim(),
                  salle: _salleController.text.trim(),
                );
                _addClub(newClub);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showRemoveClubDialog() {
    if (_clubs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aucun club à supprimer.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer un club"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _clubs.length,
            itemBuilder: (context, index) {
              final club = _clubs[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _colorForClub(club.name),
                  child: const Icon(Icons.group, color: Colors.white),
                ),
                title: Text(club.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _removeClub(club.id);
                    Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }

  Color _colorForClub(String clubName) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.pink,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    return colors[clubName.hashCode % colors.length];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des clubs"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAddClubDialog,
                  icon: const Icon(Icons.add),
                  label: const Text("Ajouter un club"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showRemoveClubDialog,
                  icon: const Icon(Icons.delete),
                  label: const Text("Supprimer un club"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Column(
                children: _clubs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final club = entry.value;
                  final animation = CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      index / _clubs.length,
                      1.0,
                      curve: Curves.easeOut,
                    ),
                  );
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: animation,
                      child: _buildClubCard(club),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClubCard(ClubData club) {
    final color = _colorForClub(club.name);
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color,
                  child: const Icon(Icons.group, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    club.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text("Responsable: ${club.responsable}"),
            Text("Prix: ${club.price}"),
            Text("Nombre de groupes: ${club.groupCount}"),
            Text("Salle: ${club.salle}"),
          ],
        ),
      ),
    );
  }
}
