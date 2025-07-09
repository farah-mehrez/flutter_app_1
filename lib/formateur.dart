import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'profile_pageformateur.dart';

class Formateur {
  String id;
  String name;
  String email;
  String phone;
  String speciality;
  String officeHours;

  Formateur({
    this.id = '',
    required this.name,
    required this.email,
    this.phone = '',
    this.speciality = '',
    this.officeHours = '',
  });

  factory Formateur.fromSnapshot(DataSnapshot snap) {
    final data = Map<String, dynamic>.from(snap.value as Map);
    return Formateur(
      id: snap.key ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      speciality: data['speciality'] ?? '',
      officeHours: data['officeHours'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'speciality': speciality,
      'officeHours': officeHours,
    };
  }
}

class FormateursScreen extends StatefulWidget {
  @override
  _FormateursScreenState createState() => _FormateursScreenState();
}

class _FormateursScreenState extends State<FormateursScreen> {
  final DatabaseReference _formateursRef = FirebaseDatabase.instance
      .ref()
      .child('formateurs');

  List<Formateur> formateurs = [];
  String searchQuery = '';
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    _loadFormateurs();
  }

  void _loadFormateurs() {
    _formateursRef.onValue.listen(
      (event) {
        final data = event.snapshot.value;
        if (data != null && data is Map) {
          final loaded = Map<String, dynamic>.from(data).entries.map((entry) {
            final fData = Map<String, dynamic>.from(entry.value);
            return Formateur(
              id: entry.key,
              name: fData['name'] ?? '',
              email: fData['email'] ?? '',
              phone: fData['phone'] ?? '',
              speciality: fData['speciality'] ?? '',
              officeHours: fData['officeHours'] ?? '',
            );
          }).toList();
          setState(() {
            formateurs = loaded;
            isLoading = false;
          });
        } else {
          setState(() {
            formateurs = [];
            isLoading = false;
          });
        }
      },
      onError: (e) {
        setState(() {
          isLoading = false;
          error = 'Erreur : $e';
        });
      },
    );
  }

  Future<void> _addFormateurDialog() async {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String email = '';
    String phone = '';
    String speciality = '';
    String officeHours = '';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ajouter un formateur'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _customField('Nom', onChanged: (v) => name = v),
                _customField(
                  'Email',
                  onChanged: (v) => email = v,
                  keyboard: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email requis';
                    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!regex.hasMatch(v)) return 'Email invalide';
                    return null;
                  },
                ),
                _customField(
                  'Téléphone',
                  keyboard: TextInputType.phone,
                  onChanged: (v) => phone = v,
                ),
                _customField('Spécialité', onChanged: (v) => speciality = v),
                _customField(
                  'Heures de bureau',
                  onChanged: (v) => officeHours = v,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              final newF = Formateur(
                name: name.trim(),
                email: email.trim(),
                phone: phone.trim(),
                speciality: speciality.trim(),
                officeHours: officeHours.trim(),
              );
              final newRef = _formateursRef.push();
              await newRef.set(newF.toMap());
              _loadFormateurs();
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _editFormateurDialog(Formateur f) async {
    final formKey = GlobalKey<FormState>();
    String name = f.name;
    String email = f.email;
    String phone = f.phone;
    String speciality = f.speciality;
    String officeHours = f.officeHours;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifier le formateur'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _customField('Nom', onChanged: (v) => name = v, initial: name),
                _customField(
                  'Email',
                  onChanged: (v) => email = v,
                  initial: email,
                  keyboard: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email requis';
                    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!regex.hasMatch(v)) return 'Email invalide';
                    return null;
                  },
                ),
                _customField(
                  'Téléphone',
                  keyboard: TextInputType.phone,
                  onChanged: (v) => phone = v,
                  initial: phone,
                ),
                _customField(
                  'Spécialité',
                  onChanged: (v) => speciality = v,
                  initial: speciality,
                ),
                _customField(
                  'Heures de bureau',
                  onChanged: (v) => officeHours = v,
                  initial: officeHours,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              await _formateursRef.child(f.id).update({
                'name': name.trim(),
                'email': email.trim(),
                'phone': phone.trim(),
                'speciality': speciality.trim(),
                'officeHours': officeHours.trim(),
              });
              _loadFormateurs();
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Widget _customField(
    String label, {
    TextInputType keyboard = TextInputType.text,
    String? initial,
    String? Function(String?)? validator,
    required Function(String) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: initial,
        keyboardType: keyboard,
        validator:
            validator ??
            (v) => v == null || v.isEmpty ? 'Ce champ est requis' : null,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _deleteFormateur(String id) async {
    await _formateursRef.child(id).remove();
  }

  void _showDeleteConfirmation(Formateur f) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer formateur'),
        content: Text('Voulez-vous supprimer ${f.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteFormateur(f.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('${f.name} supprimé')));
            },
            child: const Text('Oui'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = formateurs.where((f) {
      return f.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _addFormateurDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Ajouter un formateur'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (error.isNotEmpty)
              Expanded(
                child: Center(
                  child: Text(error, style: TextStyle(color: Colors.red)),
                ),
              )
            else if (filtered.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'Aucun formateur trouvé',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85, // ✅ Adjusted to prevent overflow
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final f = filtered[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FormateurProfilePage(formateur: f),
                        ),
                      ),
                      onLongPress: () => _showDeleteConfirmation(f),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircleAvatar(
                              radius: 30,
                              backgroundImage: AssetImage(
                                'assets/images/icon.jpeg',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Flexible(
                              child: Text(
                                f.name,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 20,
                                color: Colors.blueAccent,
                              ),
                              tooltip: 'Modifier ce formateur',
                              onPressed: () => _editFormateurDialog(f),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 20),
          const Text(
            'Formateurs',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Recherche...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onChanged: (value) => setState(() => searchQuery = value),
      ),
    );
  }
}
