import 'package:flutter/material.dart';

import '../models/patient.dart';
import 'questionnaire_screen.dart';

class IntakeScreen extends StatefulWidget {
  const IntakeScreen({super.key});

  @override
  State<IntakeScreen> createState() => _IntakeScreenState();
}

class _IntakeScreenState extends State<IntakeScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _heightController = TextEditingController(text: '170');
  final TextEditingController _weightController = TextEditingController(text: '70');
  final TextEditingController _campController = TextEditingController(text: 'camp-01');
  final TextEditingController _districtController = TextEditingController(text: '');
  final TextEditingController _injuryNotesController = TextEditingController();

  Gender _selectedGender = Gender.male;
  int _age = 45;
  bool _priorInjury = false;
  String _preferredLanguage = 'en';

  @override
  void dispose() {
    _nameController.dispose();
    _occupationController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _campController.dispose();
    _districtController.dispose();
    _injuryNotesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final patient = Patient(
      name: _nameController.text.trim(),
      age: _age,
      sex: _selectedGender,
      occupation: _occupationController.text.trim(),
      heightCm: double.tryParse(_heightController.text.trim()) ?? 170.0,
      weightKg: double.tryParse(_weightController.text.trim()) ?? 70.0,
      priorInjuryHistory: _priorInjury,
      injuryNotes: _injuryNotesController.text.trim(),
      preferredLanguage: _preferredLanguage,
      campId: _campController.text.trim().isEmpty ? 'camp-01' : _campController.text.trim(),
      district: _districtController.text.trim().isEmpty ? 'Unknown' : _districtController.text.trim(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionnaireScreen(patient: patient),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Intake'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Patient name'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _age.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Age'),
                      onChanged: (value) => _age = int.tryParse(value) ?? 45,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<Gender>(
                      value: _selectedGender,
                      decoration: const InputDecoration(labelText: 'Sex'),
                      items: Gender.values
                          .map(
                            (gender) => DropdownMenuItem(
                              value: gender,
                              child: Text(gender.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _selectedGender = value ?? Gender.male),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _occupationController,
                decoration: const InputDecoration(labelText: 'Occupation'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Height (cm)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Weight (kg)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Prior injury history'),
                value: _priorInjury,
                onChanged: (value) => setState(() => _priorInjury = value),
              ),
              TextFormField(
                controller: _injuryNotesController,
                decoration: const InputDecoration(labelText: 'Injury notes (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _preferredLanguage,
                decoration: const InputDecoration(labelText: 'Preferred language'),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'as', child: Text('Assamese')),
                  DropdownMenuItem(value: 'bn', child: Text('Bengali')),
                  DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                  DropdownMenuItem(value: 'mni', child: Text('Meitei')),
                  DropdownMenuItem(value: 'ne', child: Text('Nepali')),
                ],
                onChanged: (value) => setState(() => _preferredLanguage = value ?? 'en'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _campController,
                decoration: const InputDecoration(labelText: 'Camp ID'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _districtController,
                decoration: const InputDecoration(labelText: 'District'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Continue to questionnaire'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
