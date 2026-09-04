import 'package:flutter/material.dart';

import '../models/patient.dart';
import '../models/questionnaire_response.dart';
import '../l10n/app_localizations.dart';
import 'mobility_test_screen.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key, required this.patient});

  final Patient patient;

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  late final List<int> _responses;

  @override
  void initState() {
    super.initState();
    _responses = List<int>.filled(
        QuestionnaireResponse.standardWomacQuestions.length, 0);
  }

  void _submit() {
    final questionnaire = QuestionnaireResponse(responsesRaw: _responses);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MobilityTestScreen(
          patient: widget.patient,
          questionnaire: questionnaire,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      String title, String subtitle, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const darkText = Color(0xFF243845);
    const brandTeal = Color(0xFF1D7D8D);
    const paleTeal = Color(0xFFE7F2F5);
    const border = Color(0xFFB4D6D8);
    const sectionPain = Color(0xFFBF5E56);
    const sectionStiff = Color(0xFFD07D47);
    const sectionFunction = Color(0xFF2B8EA7);

    final painTotal =
        _responses.take(5).fold<int>(0, (sum, item) => sum + item);
    final stiffnessTotal =
        _responses.skip(5).take(2).fold<int>(0, (sum, item) => sum + item);
    final functionTotal =
        _responses.skip(7).fold<int>(0, (sum, item) => sum + item);
    final allQuestions = QuestionnaireResponse.standardWomacQuestions;
    final loc = AppLocalizations.of(context);
    final languageCode = loc.locale.languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF4F5),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    loc.tr('womacQuestionnaire'),
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
                    color: brandTeal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Step 2 of 3',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            _questionSection(
              title: _sectionTitle(languageCode, 'pain'),
              score: '${_scoreLabel(languageCode)}: $painTotal / 20',
              tint: sectionPain,
              startIndex: 0,
              endIndex: 4,
              titleColor: sectionPain,
              languageCode: languageCode,
            ),
            const SizedBox(height: 12),
            _questionSection(
              title: _sectionTitle(languageCode, 'stiffness'),
              score: '${_scoreLabel(languageCode)}: $stiffnessTotal / 8',
              tint: sectionStiff,
              startIndex: 5,
              endIndex: 6,
              titleColor: sectionStiff,
              languageCode: languageCode,
            ),
            const SizedBox(height: 12),
            _questionSection(
              title: _sectionTitle(languageCode, 'function'),
              score: '${_scoreLabel(languageCode)}: $functionTotal / 68',
              tint: sectionFunction,
              startIndex: 7,
              endIndex: allQuestions.length - 1,
              titleColor: sectionFunction,
              languageCode: languageCode,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: paleTeal,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: Text(
                '${_cumulativeTitle(languageCode)}\n${_scoreWord(languageCode, 'pain')}: $painTotal/20 | ${_scoreWord(languageCode, 'stiffness')}: $stiffnessTotal/8 | ${_scoreWord(languageCode, 'function')}: $functionTotal/68',
                style: const TextStyle(
                  color: darkText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.5,
                ),
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
                  '${loc.tr('continueMobility')} →',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _sectionTitle(String languageCode, String section) {
    const english = {
      'pain': 'SECTION A: PAIN (5 Qs)',
      'stiffness': 'SECTION B: STIFFNESS (2 Qs)',
      'function': 'SECTION C: FUNCTION (17 Qs)',
    };
    const hindi = {
      'pain': 'खंड A: दर्द (5 प्रश्न)',
      'stiffness': 'खंड B: जकड़न (2 प्रश्न)',
      'function': 'खंड C: कार्यक्षमता (17 प्रश्न)',
    };
    const bengali = {
      'pain': 'বিভাগ A: ব্যথা (৫ প্রশ্ন)',
      'stiffness': 'বিভাগ B: শক্তভাব (২ প্রশ্ন)',
      'function': 'বিভাগ C: কার্যক্ষমতা (১৭ প্রশ্ন)',
    };
    const assamese = {
      'pain': 'অংশ A: বিষ (৫টা প্ৰশ্ন)',
      'stiffness': 'অংশ B: জঠৰতা (২টা প্ৰশ্ন)',
      'function': 'অংশ C: কাৰ্যক্ষমতা (১৭টা প্ৰশ্ন)',
    };
    return (switch (languageCode) {
      'hi' => hindi,
      'bn' => bengali,
      'as' => assamese,
      _ => english,
    })[section]!;
  }

  String _scoreLabel(String languageCode) => switch (languageCode) {
        'hi' => 'स्कोर',
        'bn' => 'স্কোর',
        'as' => 'স্কোৰ',
        _ => 'Score',
      };

  String _scoreWord(String languageCode, String section) =>
      switch ((languageCode, section)) {
        ('hi', 'pain') => 'दर्द',
        ('hi', 'stiffness') => 'जकड़न',
        ('hi', 'function') => 'कार्य',
        ('bn', 'pain') => 'ব্যথা',
        ('bn', 'stiffness') => 'শক্তভাব',
        ('bn', 'function') => 'কার্যক্ষমতা',
        ('as', 'pain') => 'বিষ',
        ('as', 'stiffness') => 'জঠৰতা',
        ('as', 'function') => 'কাৰ্যক্ষমতা',
        ('en', 'pain') => 'Pain',
        ('en', 'stiffness') => 'Stiffness',
        _ => 'Function',
      };

  String _cumulativeTitle(String languageCode) => switch (languageCode) {
        'hi' => 'संचयी स्कोर',
        'bn' => 'মোট স্কোর',
        'as' => 'মুঠ স্কোৰ',
        _ => 'CUMULATIVE SCORES',
      };

  Widget _questionSection({
    required String title,
    required String score,
    required Color tint,
    required int startIndex,
    required int endIndex,
    required Color titleColor,
    required String languageCode,
  }) {
    final items = <Widget>[];
    for (var index = startIndex; index <= endIndex; index++) {
      final question = QuestionnaireResponse.standardWomacQuestions[index];
      final value = _responses[index];
      final questionTitle =
          _questionTitle(question.id, question.title, languageCode);
      final questionDescription = _questionDescription(question, languageCode);
      items.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7F7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFB9D6D7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${index + 1}. $questionTitle',
                style: const TextStyle(
                  color: Color(0xFF243845),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                questionDescription,
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _severityChip(
                      _severityLabel(languageCode, 0), 0, value, tint, index),
                  _severityChip(
                      _severityLabel(languageCode, 1), 1, value, tint, index),
                  _severityChip(
                      _severityLabel(languageCode, 2), 2, value, tint, index),
                  _severityChip(
                      _severityLabel(languageCode, 3), 3, value, tint, index),
                  _severityChip(
                      _severityLabel(languageCode, 4), 4, value, tint, index),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: tint.withOpacity(0.12),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  score,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }

  Widget _severityChip(
      String label, int chipValue, int selectedValue, Color tint, int index) {
    final isSelected = selectedValue == chipValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _responses[index] = chipValue),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF243845),
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      backgroundColor: Colors.white,
      selectedColor: tint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? tint : const Color(0xFFB4D6D8)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  }

  String _severityLabel(String languageCode, int value) {
    const english = ['None', 'Mild', 'Mod', 'Sev', 'Ext'];
    const hindi = ['नहीं', 'हल्का', 'मध्यम', 'गंभीर', 'अत्यधिक'];
    const bengali = ['নেই', 'হালকা', 'মাঝারি', 'তীব্র', 'অত্যধিক'];
    const assamese = ['নাই', 'কম', 'মধ্যম', 'তীব্ৰ', 'অত্যাধিক'];
    final labels = switch (languageCode) {
      'hi' => hindi,
      'bn' => bengali,
      'as' => assamese,
      _ => english,
    };
    return labels[value];
  }

  String _questionTitle(String id, String fallback, String languageCode) {
    const hindi = {
      'P1': 'समतल सतह पर चलना',
      'P2': 'सीढ़ियां चढ़ना/उतरना',
      'P3': 'रात में बिस्तर पर',
      'P4': 'बैठना या लेटना',
      'P5': 'सीधे खड़े होना',
      'S1': 'सुबह की जकड़न',
      'S2': 'आराम के बाद जकड़न',
      'F1': 'सीढ़ियों से उतरना',
      'F2': 'सीढ़ियां चढ़ना',
      'F3': 'बैठने से उठना',
      'F4': 'खड़ा रहना',
      'F5': 'फर्श की ओर झुकना',
      'F6': 'समतल सतह पर चलना',
      'F7': 'गाड़ी में बैठना/उतरना',
      'F8': 'खरीदारी करना',
      'F9': 'मोज़े पहनना',
      'F10': 'बिस्तर से उठना',
      'F11': 'मोज़े उतारना',
      'F12': 'बिस्तर पर लेटना',
      'F13': 'स्नान में जाना/निकलना',
      'F14': 'बैठना',
      'F15': 'शौचालय पर बैठना/उठना',
      'F16': 'भारी घरेलू काम',
      'F17': 'हल्के घरेलू काम',
    };
    const bengali = {
      'P1': 'সমতল মাটিতে হাঁটা',
      'P2': 'সিঁড়ি ওঠা/নামা',
      'P3': 'রাতে বিছানায়',
      'P4': 'বসা বা শোয়া',
      'P5': 'সোজা দাঁড়ানো',
      'S1': 'সকালের শক্তভাব',
      'S2': 'বিশ্রামের পর শক্তভাব',
      'F1': 'সিঁড়ি দিয়ে নামা',
      'F2': 'সিঁড়ি দিয়ে ওঠা',
      'F3': 'বসা থেকে ওঠা',
      'F4': 'দাঁড়িয়ে থাকা',
      'F5': 'মেঝের দিকে ঝোঁকা',
      'F6': 'সমতল মাটিতে হাঁটা',
      'F7': 'গাড়িতে ওঠা/নামা',
      'F8': 'কেনাকাটা করা',
      'F9': 'মোজা পরা',
      'F10': 'বিছানা থেকে ওঠা',
      'F11': 'মোজা খোলা',
      'F12': 'বিছানায় শোয়া',
      'F13': 'স্নানে ওঠা/নামা',
      'F14': 'বসা',
      'F15': 'টয়লেটে ওঠা/বসা',
      'F16': 'ভারী ঘরের কাজ',
      'F17': 'হালকা ঘরের কাজ',
    };
    const assamese = {
      'P1': 'সমান মাটিত খোজ কঢ়া',
      'P2': 'জখলাত উঠা/নমা',
      'P3': 'ৰাতি বিচনাত',
      'P4': 'বহা বা শোৱা',
      'P5': 'পোনে পোনে থিয় হোৱা',
      'S1': 'ৰাতিপুৱাৰ জঠৰতা',
      'S2': 'জিৰণিৰ পাছত জঠৰতা',
      'F1': 'জখলাৰে নমা',
      'F2': 'জখলাৰে উঠা',
      'F3': 'বহাৰ পৰা উঠা',
      'F4': 'থিয় হৈ থকা',
      'F5': 'মজিয়ালৈ হাউলি যোৱা',
      'F6': 'সমান মাটিত খোজ কঢ়া',
      'F7': 'গাড়ীত উঠা/নমা',
      'F8': 'বজাৰ কৰা',
      'F9': 'মোজা পিন্ধা',
      'F10': 'বিচনাৰ পৰা উঠা',
      'F11': 'মোজা খোলা',
      'F12': 'বিচনাত শোৱা',
      'F13': 'গা ধোৱা ঠাইত উঠা/নমা',
      'F14': 'বহা',
      'F15': 'শৌচালয়ত উঠা/বহা',
      'F16': 'গধুৰ ঘৰুৱা কাম',
      'F17': 'লঘু ঘৰুৱা কাম',
    };
    final translations = switch (languageCode) {
      'hi' => hindi,
      'bn' => bengali,
      'as' => assamese,
      _ => const <String, String>{},
    };
    return translations[id] ?? fallback;
  }

  String _questionDescription(WomacQuestion question, String languageCode) {
    if (languageCode == 'en') return question.description;
    return switch ((languageCode, question.category)) {
      ('hi', 'pain') => 'इस गतिविधि के दौरान दर्द',
      ('hi', 'stiffness') => 'इस समय जकड़न',
      ('hi', _) => 'इस गतिविधि में कठिनाई',
      ('bn', 'pain') => 'এই কাজের সময় ব্যথা',
      ('bn', 'stiffness') => 'এই সময় শক্তভাব',
      ('bn', _) => 'এই কাজে অসুবিধা',
      ('as', 'pain') => 'এই কামৰ সময়ত বিষ',
      ('as', 'stiffness') => 'এই সময়ত জঠৰতা',
      _ => 'এই কামত অসুবিধা',
    };
  }
}
