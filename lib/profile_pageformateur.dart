import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'formateur.dart';

class FormateurProfilePage extends StatefulWidget {
  final Formateur formateur;

  const FormateurProfilePage({Key? key, required this.formateur}) : super(key: key);

  @override
  State<FormateurProfilePage> createState() => _FormateurProfilePageState();
}

class _FormateurProfilePageState extends State<FormateurProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController specialityController;
  late TextEditingController officeHoursController;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.formateur.name);
    emailController = TextEditingController(text: widget.formateur.email);
    phoneController = TextEditingController(text: widget.formateur.phone);
    specialityController = TextEditingController(text: widget.formateur.speciality);
    officeHoursController = TextEditingController(text: widget.formateur.officeHours);

    _loadDataFromRealtimeDB();
  }

  Future<void> _loadDataFromRealtimeDB() async {
    final id = widget.formateur.id;
    if (id.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final snapshot = await FirebaseDatabase.instance.ref('formateurs/$id').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          nameController.text = data['name'] ?? '';
          emailController.text = data['email'] ?? '';
          phoneController.text = data['phone'] ?? '';
          specialityController.text = data['speciality'] ?? '';
          officeHoursController.text = data['officeHours'] ?? '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    specialityController.dispose();
    officeHoursController.dispose();
    super.dispose();
  }

  void _confirmSave() {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmer la sauvegarde"),
        content: const Text("Voulez-vous enregistrer les modifications ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveData();
            },
            child: const Text("Confirmer"),
          ),
        ],
      ),
    );
  }

  void _saveData() async {
    final id = widget.formateur.id;
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Identifiant du formateur requis pour sauvegarder.'),
        ),
      );
      return;
    }

    final data = {
      'name': nameController.text.trim(),
      'email': emailController.text.trim(),
      'phone': phoneController.text.trim(),
      'speciality': specialityController.text.trim(),
      'officeHours': officeHoursController.text.trim(),
    };

    try {
      await FirebaseDatabase.instance.ref('formateurs/$id').update(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Données sauvegardées avec succès ✅')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sauvegarde ❌: $e')),
      );
    }
  }

  void _deleteFormateur() async {
    final id = widget.formateur.id;
    if (id.isEmpty) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Voulez-vous vraiment supprimer ce formateur ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await FirebaseDatabase.instance.ref('formateurs/$id').remove();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Formateur supprimé avec succès ✅')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression ❌: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Profil du Formateur'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteFormateur,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 60,
                      backgroundImage: AssetImage('assets/images/icon.jpeg'),
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    _buildCardSection(
                      children: [
                        _buildTextField(
                          'Nom',
                          nameController,
                          validator: _requiredValidator,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCardSection(
                      title: 'Coordonnées',
                      children: [
                        _buildTextField(
                          'Email',
                          emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: _emailValidator,
                        ),
                        _buildTextField(
                          'Téléphone',
                          phoneController,
                          keyboardType: TextInputType.phone,
                          validator: _requiredValidator,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCardSection(
                      title: 'Détails professionnels',
                      children: [
                        _buildTextField(
                          'Spécialité',
                          specialityController,
                          validator: _requiredValidator,
                        ),
                        _buildTextField(
                          'Heures de bureau',
                          officeHoursController,
                          validator: _requiredValidator,
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _confirmSave,
                        icon: const Icon(Icons.save),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        label: const Text(
                          'Enregistrer les modifications',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCardSection({
    String? title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Champ requis';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Champ requis';
    }
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Email invalide';
    }
    return null;
  }
}
