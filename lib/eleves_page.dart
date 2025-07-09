import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'profile_page.dart';

class Student {
  String id;
  String name;
  String phone;
  String birthDate;
  String email;
  String group;
  String club;
  String registrationNumber;
  String subscriptionPayment;
  String clubPayment;

  Student({
    this.id = '',
    required this.name,
    this.phone = '',
    this.birthDate = '',
    this.email = '',
    this.group = '',
    this.club = '',
    this.registrationNumber = '',
    this.subscriptionPayment = '',
    this.clubPayment = '',
  });

  factory Student.fromSnapshot(DataSnapshot snap) {
    final data = Map<String, dynamic>.from(snap.value as Map);
    return Student(
      id: snap.key ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      birthDate: data['birthDate'] ?? '',
      email: data['email'] ?? '',
      group: data['group'] ?? '',
      club: data['club'] ?? '',
      registrationNumber: data['registrationNumber'] ?? '',
      subscriptionPayment: data['subscriptionPayment'] ?? '',
      clubPayment: data['clubPayment'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'birthDate': birthDate,
      'email': email,
      'group': group,
      'club': club,
      'registrationNumber': registrationNumber,
      'subscriptionPayment': subscriptionPayment,
      'clubPayment': clubPayment,
    };
  }
}

class ElevesScreen extends StatefulWidget {
  const ElevesScreen({Key? key}) : super(key: key);

  @override
  _ElevesScreenState createState() => _ElevesScreenState();
}

class _ElevesScreenState extends State<ElevesScreen> {
  final DatabaseReference studentsRef = FirebaseDatabase.instance.ref().child('students');
  List<Student> students = [];
  String searchQuery = '';
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  void _loadStudents() {
    studentsRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final loaded = Map<String, dynamic>.from(data).entries.map((entry) {
          final studentData = Map<String, dynamic>.from(entry.value);
          return Student(
            id: entry.key,
            name: studentData['name'] ?? '',
            email: studentData['email'] ?? '',
            phone: studentData['phone'] ?? '',
          );
        }).toList();
        setState(() {
          students = loaded;
          isLoading = false;
        });
      } else {
        setState(() {
          students = [];
          isLoading = false;
        });
      }
    }, onError: (e) {
      setState(() {
        isLoading = false;
        error = 'Erreur de chargement : $e';
      });
    });
  }

  Future<void> _addStudentDialog() async {
    final formKey = GlobalKey<FormState>();
    String newName = '', email = '', phone = '';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ajouter un élève'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _customField('Nom', onChanged: (v) => newName = v),
              _customField('Email',
                  onChanged: (v) => email = v,
                  keyboard: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Email requis';
                    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!regex.hasMatch(value)) return 'Email invalide';
                    return null;
                  }),
              _customField('Téléphone',
                  keyboard: TextInputType.phone, onChanged: (v) => phone = v),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              final newStudent = Student(name: newName.trim(), email: email.trim(), phone: phone.trim());
              final newRef = studentsRef.push();
              await newRef.set(newStudent.toMap());
              _loadStudents();
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _editStudentDialog(Student student) async {
    final formKey = GlobalKey<FormState>();
    String name = student.name, email = student.email, phone = student.phone;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifier l'élève"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _customField("Nom", onChanged: (v) => name = v, initial: name),
              _customField("Email",
                  keyboard: TextInputType.emailAddress,
                  onChanged: (v) => email = v,
                  initial: email,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Email requis';
                    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!regex.hasMatch(value)) return 'Email invalide';
                    return null;
                  }),
              _customField("Téléphone",
                  keyboard: TextInputType.phone,
                  onChanged: (v) => phone = v,
                  initial: phone),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              await studentsRef.child(student.id).update({
                'name': name.trim(),
                'email': email.trim(),
                'phone': phone.trim(),
              });
              _loadStudents();
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  Widget _customField(String label,
      {TextInputType keyboard = TextInputType.text,
      String? Function(String?)? validator,
      String? initial,
      required Function(String) onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: initial,
        keyboardType: keyboard,
        validator: validator ?? (value) => value == null || value.isEmpty ? 'Ce champ est requis' : null,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _deleteStudent(String id) async {
    await studentsRef.child(id).remove();
  }

  void _showDeleteConfirmation(Student student) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer élève'),
        content: Text('Voulez-vous supprimer ${student.name} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Non')),
          ElevatedButton(
            onPressed: () {
              _deleteStudent(student.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${student.name} supprimé')));
            },
            child: const Text('Oui'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = students.where((s) => s.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Liste des élèves',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _addStudentDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text("Ajouter"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Appuyez longuement pour supprimer.')),
                      );
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text("Supprimer"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Recherche...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onChanged: (value) => setState(() => searchQuery = value),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : error.isNotEmpty
                      ? Center(child: Text(error, style: const TextStyle(color: Colors.red)))
                      : filtered.isEmpty
                          ? Center(child: Text("Aucun élève trouvé", style: TextStyle(color: Colors.grey[600])))
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.9,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final student = filtered[index];
                                return GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StudentProfilePage(student: student),
                                    ),
                                  ),
                                  onLongPress: () => _showDeleteConfirmation(student),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.15),
                                          blurRadius: 10,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        const CircleAvatar(
                                          radius: 30,
                                          backgroundImage: AssetImage('assets/images/icon.jpeg'),
                                        ),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                student.name,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(fontWeight: FontWeight.w600),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.edit, size: 20, color: Colors.blueAccent),
                                                tooltip: "Modifier cet élève",
                                                onPressed: () => _editStudentDialog(student),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
