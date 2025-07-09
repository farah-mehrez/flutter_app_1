import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'eleves_page.dart'; // Your Student model

class StudentProfilePage extends StatefulWidget {
  final Student student;

  const StudentProfilePage({Key? key, required this.student}) : super(key: key);

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController birthDateController;
  late TextEditingController emailController;
  late TextEditingController registrationNumberController;
  late TextEditingController subscriptionPaymentController;
  late TextEditingController clubPaymentController;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  void _loadStudentData() async {
    final ref = FirebaseDatabase.instance.ref().child('students').child(widget.student.id);
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map;

      setState(() {
        nameController = TextEditingController(text: data['name'] ?? '');
        phoneController = TextEditingController(text: data['phone'] ?? '');
        birthDateController = TextEditingController(text: data['birthDate'] ?? '');
        emailController = TextEditingController(text: data['email'] ?? '');
        registrationNumberController = TextEditingController(text: data['registrationNumber'] ?? '');
        subscriptionPaymentController = TextEditingController(text: data['subscriptionPayment'] ?? '');
        clubPaymentController = TextEditingController(text: data['clubPayment'] ?? '');

        widget.student.group = data['group'] ?? widget.student.group;
        widget.student.club = data['club'] ?? widget.student.club;

        isLoading = false;
      });
    } else {
      setState(() {
        nameController = TextEditingController();
        phoneController = TextEditingController();
        birthDateController = TextEditingController();
        emailController = TextEditingController();
        registrationNumberController = TextEditingController();
        subscriptionPaymentController = TextEditingController();
        clubPaymentController = TextEditingController();
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    birthDateController.dispose();
    emailController.dispose();
    registrationNumberController.dispose();
    subscriptionPaymentController.dispose();
    clubPaymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Profil Étudiant'),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
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
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Nom',
                      nameController,
                      validator: _requiredValidator,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      border: InputBorder.none,
                    ),
                    const SizedBox(height: 16),
                    _buildChipRow(student),
                    const SizedBox(height: 24),
                    _buildCardSection(
                      title: 'Informations d\'inscription et paiements',
                      children: [
                        _buildTextField('Numéro d\'enregistrement', registrationNumberController, validator: _requiredValidator),
                        _buildTextField('Paiement d\'abonnement', subscriptionPaymentController, validator: _requiredValidator),
                        _buildTextField('Paiement de club', clubPaymentController, validator: _requiredValidator),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildCardSection(
                      title: 'Informations personnelles',
                      children: [
                        _buildTextField('Numéro de téléphone', phoneController, keyboardType: TextInputType.phone, validator: _requiredValidator),
                        _buildTextField('Date de naissance', birthDateController, readOnly: true, onTap: _pickDate, validator: _requiredValidator),
                        _buildTextField('Adresse email', emailController, keyboardType: TextInputType.emailAddress, validator: _emailValidator),
                      ],
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _confirmSave,
                        icon: const Icon(Icons.save),
                        label: const Text('Enregistrer les modifications'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildChipRow(Student student) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Chip(
          label: Text(student.club.isEmpty ? 'CLUB 🤖' : student.club),
          backgroundColor: Colors.blue.shade100,
        ),
        const SizedBox(width: 16),
        Chip(
          label: Text(student.group.isEmpty ? 'GROUPE 1' : 'GROUPE ${student.group}'),
          backgroundColor: Colors.green.shade100,
        ),
      ],
    );
  }

  Widget _buildCardSection({
    required String title,
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
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    TextStyle? style,
    TextAlign? textAlign,
    InputBorder? border,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        validator: validator,
        style: style,
        textAlign: textAlign ?? TextAlign.start,
        decoration: InputDecoration(
          labelText: label,
          border: border ?? OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _pickDate() async {
    final initialDate = DateTime.tryParse(birthDateController.text) ?? DateTime(2000);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        birthDateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _confirmSave() {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer'),
        content: const Text('Voulez-vous enregistrer les modifications ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveData();
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _saveData() async {
    final updatedData = {
      'name': nameController.text.trim(),
      'registrationNumber': registrationNumberController.text.trim(),
      'subscriptionPayment': subscriptionPaymentController.text.trim(),
      'clubPayment': clubPaymentController.text.trim(),
      'phone': phoneController.text.trim(),
      'birthDate': birthDateController.text.trim(),
      'email': emailController.text.trim(),
      'group': widget.student.group,
      'club': widget.student.club,
    };

    try {
      await FirebaseDatabase.instance.ref('students/${widget.student.id}').update(updatedData);
      widget.student.name = nameController.text.trim();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Données mises à jour ✅')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur ❌: $e')),
      );
    }
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
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}\$');
    if (!regex.hasMatch(value.trim())) {
      return 'Email invalide';
    }
    return null;
  }
}
