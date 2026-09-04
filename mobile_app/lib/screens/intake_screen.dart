import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/patient.dart';
import 'questionnaire_screen.dart';

class IntakeScreen extends StatefulWidget {
  const IntakeScreen({super.key, this.onLocaleChanged});

  final ValueChanged<Locale>? onLocaleChanged;

  @override
  State<IntakeScreen> createState() => _IntakeScreenState();
}

class _IntakeScreenState extends State<IntakeScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _heightController =
      TextEditingController(text: '170');
  final TextEditingController _weightController =
      TextEditingController(text: '70');
  final TextEditingController _campController =
      TextEditingController(text: 'camp-01');
  final TextEditingController _districtController =
      TextEditingController(text: '');
  final TextEditingController _injuryNotesController = TextEditingController();

  Gender _selectedGender = Gender.male;
  String _preferredLanguage = 'English';
  String _heightUnit = 'cm';
  int _heightFeet = 5;
  int _heightInches = 7;
  int _age = 45;
  bool _priorInjury = false;

  double get _heightInCm {
    if (_heightUnit == 'cm') {
      return double.tryParse(_heightController.text.trim()) ?? 0;
    }
    return (_heightFeet * 12 + _heightInches) * 2.54;
  }

  String get _bmiDisplay {
    final weight = double.tryParse(_weightController.text.trim()) ?? 0;
    final bmi = Patient.calculateBmi(_heightInCm, weight);
    final category = bmi == 0
        ? 'Enter height and weight'
        : bmi < 18.5
            ? 'Underweight'
            : bmi < 25
                ? 'Normal'
                : bmi < 30
                    ? 'Overweight'
                    : 'Obese';
    return 'BMI: ${bmi.toStringAsFixed(1)} — $category';
  }

  void _changeHeightUnit(String unit) {
    if (unit == _heightUnit) return;
    setState(() {
      if (unit == 'ft') {
        final totalInches = _heightInCm / 2.54;
        _heightFeet = totalInches ~/ 12;
        _heightInches = (totalInches - _heightFeet * 12).round().clamp(0, 11);
      } else {
        _heightController.text = _heightInCm.toStringAsFixed(1);
      }
      _heightUnit = unit;
    });
  }

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
      heightCm: _heightInCm,
      weightKg: double.tryParse(_weightController.text.trim()) ?? 70.0,
      priorInjuryHistory: _priorInjury,
      injuryNotes: _injuryNotesController.text.trim(),
      preferredLanguage: _preferredLanguage,
      campId: _campController.text.trim().isEmpty
          ? 'camp-01'
          : _campController.text.trim(),
      district: _districtController.text.trim().isEmpty
          ? 'Unknown'
          : _districtController.text.trim(),
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
    final loc = AppLocalizations.of(context);
    const brandTeal = Color(0xFF1D7D8D);
    const darkText = Color(0xFF243845);
    const border = Color(0xFFB9D6D7);

    final occupationOptions = ['Farmer', 'Labourer', 'Homemaker', 'Other'];
    final languageOptions = [
      'English',
      'Hindi',
      'Bengali',
      'Assamese',
      'Meitei'
    ];
    final languageCode = loc.locale.languageCode;
    final sectionLabels = _sectionLabels(languageCode);

    return Scaffold(
      backgroundColor: const Color(0xFFEFF4F5),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      loc.tr('patientIntake'),
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: darkText,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ),
                  Container(
                    width: 110,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [brandTeal, brandTeal],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Step 1 of 3',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                title: sectionLabels['identity']!,
                child: Column(
                  children: [
                    _textField(
                      label: '${loc.tr('patientName')} *',
                      controller: _nameController,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? loc.tr('required')
                              : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _numberField(
                            label: '${loc.tr('age')} *',
                            initialValue: _age.toString(),
                            onChanged: (value) =>
                                _age = int.tryParse(value) ?? 45,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonFormField<Gender>(
                              initialValue: _selectedGender,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                labelText: loc.tr('sex'),
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 14),
                              ),
                              items: Gender.values
                                  .map(
                                    (gender) => DropdownMenuItem(
                                      value: gender,
                                      child: Text(gender.name[0].toUpperCase() +
                                          gender.name.substring(1)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) => setState(
                                  () => _selectedGender = value ?? Gender.male),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _sectionCard(
                title: sectionLabels['physical']!,
                trailing: Text(_bmiDisplay,
                    style: const TextStyle(
                        color: brandTeal,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
                child: Row(
                  children: [
                    Expanded(
                      child: _heightUnit == 'cm'
                          ? Row(
                              children: [
                                Expanded(
                                  child: _textField(
                                    label: loc.tr('heightCm'),
                                    controller: _heightController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                _heightUnitMenu(),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: _heightDropdown('ft')),
                                const SizedBox(width: 8),
                                Expanded(child: _heightDropdown('in')),
                                _heightUnitMenu(),
                              ],
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _textField(
                        label: loc.tr('weightKg'),
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _sectionCard(
                title: sectionLabels['occupation']!,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: occupationOptions.map((option) {
                    final selected =
                        _occupationController.text.trim().toLowerCase() ==
                            option.toLowerCase();
                    return ChoiceChip(
                      label: Text(option),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _occupationController.text = option;
                        });
                      },
                      selectedColor: brandTeal.withOpacity(0.12),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: selected ? brandTeal : border),
                      ),
                      labelStyle: TextStyle(
                        color: selected ? brandTeal : darkText,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              _sectionCard(
                title: sectionLabels['injury']!,
                trailing: Switch(
                  value: _priorInjury,
                  onChanged: (value) => setState(() => _priorInjury = value),
                  activeColor: Colors.white,
                  activeTrackColor: brandTeal,
                ),
                child: _textField(
                  label: loc.tr('injuryNotes'),
                  controller: _injuryNotesController,
                  maxLines: 2,
                  hint: 'Prior injury notes',
                ),
              ),
              const SizedBox(height: 14),
              _sectionCard(
                title: sectionLabels['location']!,
                child: Row(
                  children: [
                    Expanded(
                      child: _textField(
                        label: loc.tr('campId'),
                        controller: _campController,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _textField(
                        label: loc.tr('district'),
                        controller: _districtController,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? loc.tr('required')
                                : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _sectionCard(
                title: sectionLabels['preferredLanguage']!,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: languageOptions.map((option) {
                    final selected = option == _preferredLanguage;
                    return ChoiceChip(
                      label: Text(option),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _preferredLanguage = option);
                        final locale = switch (option) {
                          'Hindi' => const Locale('hi'),
                          'Bengali' => const Locale('bn'),
                          'Assamese' => const Locale('as'),
                          _ => const Locale('en'),
                        };
                        widget.onLocaleChanged?.call(locale);
                      },
                      selectedColor: brandTeal,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: selected ? brandTeal : border),
                      ),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : darkText,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    '${loc.tr('continueQuestionnaire')} →',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
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

  Map<String, String> _sectionLabels(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return {
          'identity': 'पहचान',
          'physical': 'शारीरिक प्रोफ़ाइल',
          'occupation': 'मुख्य व्यवसाय',
          'injury': 'घुटने की चोट का इतिहास',
          'location': 'स्थान कार्यक्षेत्र',
          'preferredLanguage': 'परीक्षण की पसंदीदा भाषा',
          'heightFeet': 'ऊंचाई (फुट/इंच)',
        };
      case 'bn':
        return {
          'identity': 'পরিচয়',
          'physical': 'শারীরিক প্রোফাইল',
          'occupation': 'প্রধান পেশা',
          'injury': 'হাঁটুর আঘাতের ইতিহাস',
          'location': 'স্থান কর্মক্ষেত্র',
          'preferredLanguage': 'পরীক্ষার পছন্দের ভাষা',
          'heightFeet': 'উচ্চতা (ফুট/ইঞ্চি)',
        };
      case 'as':
        return {
          'identity': 'পৰিচয়',
          'physical': 'শাৰীৰিক প্ৰফাইল',
          'occupation': 'মুখ্য বৃত্তি',
          'injury': 'আঁঠুৰ আঘাতৰ ইতিহাস',
          'location': 'স্থান কৰ্মক্ষেত্ৰ',
          'preferredLanguage': 'পৰীক্ষাৰ পছন্দৰ ভাষা',
          'heightFeet': 'উচ্চতা (ফুট/ইঞ্চি)',
        };
      default:
        return {
          'identity': 'IDENTITY',
          'physical': 'PHYSICAL PROFILE',
          'occupation': 'PRIMARY OCCUPATION',
          'injury': 'KNEE INJURY HISTORY',
          'location': 'LOCATION WORKSPACE',
          'preferredLanguage': 'PREFERRED LANGUAGE FOR TEST',
          'heightFeet': 'Height (ft/in)',
        };
    }
  }

  Widget _heightUnitMenu() {
    return PopupMenuButton<String>(
      initialValue: _heightUnit,
      onSelected: _changeHeightUnit,
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'cm', child: Text('Centimeters')),
        PopupMenuItem(value: 'ft', child: Text('Feet / inches')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE7F3F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(_heightUnit,
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _heightDropdown(String unit) {
    final isFeet = unit == 'ft';
    final selected = isFeet ? _heightFeet : _heightInches;
    final values = isFeet
        ? List<int>.generate(8, (index) => index + 3)
        : List<int>.generate(12, (index) => index);

    return DropdownButtonFormField<int>(
      initialValue: selected,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: isFeet ? 'Feet' : 'Inches',
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB9D6D7)),
        ),
      ),
      items: values
          .map((value) => DropdownMenuItem(value: value, child: Text('$value')))
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          if (isFeet) {
            _heightFeet = value;
          } else {
            _heightInches = value;
          }
        });
      },
    );
  }

  Widget _sectionCard(
      {required String title, Widget? child, Widget? trailing}) {
    const darkText = Color(0xFF243845);
    const cardBg = Color(0xFFF4F7F7);
    const border = Color(0xFFB9D6D7);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: darkText,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          if (child != null) child,
        ],
      ),
    );
  }

  Widget _textField({
    required String label,
    TextEditingController? controller,
    String? initialValue,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hint,
    void Function(String)? onChanged,
  }) {
    const border = Color(0xFFB9D6D7);
    const fill = Colors.white;
    const darkText = Color(0xFF243845);

    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(
          color: darkText, fontSize: 18, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        filled: true,
        fillColor: fill,
        hintText: hint,
        labelText: label,
        labelStyle: const TextStyle(
            color: Color(0xFF607680), fontWeight: FontWeight.w600),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1D7D8D), width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _numberField({
    required String label,
    required String initialValue,
    required void Function(String) onChanged,
  }) {
    const border = Color(0xFFB9D6D7);
    const fill = Colors.white;
    const darkText = Color(0xFF243845);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: initialValue,
              keyboardType: TextInputType.number,
              onChanged: onChanged,
              style: const TextStyle(
                  color: darkText, fontSize: 18, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                border: InputBorder.none,
                labelText: label,
                labelStyle: const TextStyle(
                    color: Color(0xFF607680), fontWeight: FontWeight.w600),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
