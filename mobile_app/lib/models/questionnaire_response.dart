import 'dart:convert';

class WomacQuestion {
  final String id;
  final String category; // 'pain', 'stiffness', 'function'
  final String title;
  final String description;

  const WomacQuestion({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
  });
}

class QuestionnaireResponse {
  /// Standard 24 WOMAC questions definitions
  static const List<WomacQuestion> standardWomacQuestions = [
    // Pain Subscale (5 questions, 0-4 scale, max 20)
    WomacQuestion(id: 'P1', category: 'pain', title: 'Walking on Flat Surface', description: 'Pain when walking on a flat surface'),
    WomacQuestion(id: 'P2', category: 'pain', title: 'Going Up/Down Stairs', description: 'Pain when going up or down stairs'),
    WomacQuestion(id: 'P3', category: 'pain', title: 'At Night in Bed', description: 'Pain at night while in bed'),
    WomacQuestion(id: 'P4', category: 'pain', title: 'Sitting or Lying Down', description: 'Pain when sitting or lying down'),
    WomacQuestion(id: 'P5', category: 'pain', title: 'Standing Upright', description: 'Pain when standing upright'),

    // Stiffness Subscale (2 questions, 0-4 scale, max 8)
    WomacQuestion(id: 'S1', category: 'stiffness', title: 'Morning Stiffness', description: 'Stiffness after first waking in the morning'),
    WomacQuestion(id: 'S2', category: 'stiffness', title: 'Resting Stiffness', description: 'Stiffness after sitting, lying, or resting later in the day'),

    // Physical Function Subscale (17 questions, 0-4 scale, max 68)
    WomacQuestion(id: 'F1', category: 'function', title: 'Descending Stairs', description: 'Difficulty descending stairs'),
    WomacQuestion(id: 'F2', category: 'function', title: 'Ascending Stairs', description: 'Difficulty ascending stairs'),
    WomacQuestion(id: 'F3', category: 'function', title: 'Rising from Sitting', description: 'Difficulty rising from sitting'),
    WomacQuestion(id: 'F4', category: 'function', title: 'Standing', description: 'Difficulty standing'),
    WomacQuestion(id: 'F5', category: 'function', title: 'Bending to Floor', description: 'Difficulty bending to floor / picking up an object'),
    WomacQuestion(id: 'F6', category: 'function', title: 'Walking on Flat Surface', description: 'Difficulty walking on a flat surface'),
    WomacQuestion(id: 'F7', category: 'function', title: 'Getting In/Out of Car', description: 'Difficulty getting in or out of a vehicle'),
    WomacQuestion(id: 'F8', category: 'function', title: 'Going Shopping', description: 'Difficulty going shopping'),
    WomacQuestion(id: 'F9', category: 'function', title: 'Putting On Socks', description: 'Difficulty putting on socks or stockings'),
    WomacQuestion(id: 'F10', category: 'function', title: 'Rising from Bed', description: 'Difficulty rising from bed'),
    WomacQuestion(id: 'F11', category: 'function', title: 'Taking Off Socks', description: 'Difficulty taking off socks or stockings'),
    WomacQuestion(id: 'F12', category: 'function', title: 'Lying in Bed', description: 'Difficulty lying in bed'),
    WomacQuestion(id: 'F13', category: 'function', title: 'Getting In/Out of Bath', description: 'Difficulty getting in or out of bath / shower'),
    WomacQuestion(id: 'F14', category: 'function', title: 'Sitting', description: 'Difficulty sitting'),
    WomacQuestion(id: 'F15', category: 'function', title: 'Getting On/Off Toilet', description: 'Difficulty getting on or off toilet'),
    WomacQuestion(id: 'F16', category: 'function', title: 'Heavy Domestic Duties', description: 'Difficulty with heavy domestic duties (scrubbing, lifting)'),
    WomacQuestion(id: 'F17', category: 'function', title: 'Light Domestic Duties', description: 'Difficulty with light domestic duties (cooking, dusting)'),
  ];

  final List<int> responsesRaw; // 24 item scores (0 to 4 each)
  final int painScore; // 0-20
  final int stiffnessScore; // 0-8
  final int functionScore; // 0-68
  final int totalWomacScore; // 0-96

  QuestionnaireResponse({
    required this.responsesRaw,
  })  : assert(responsesRaw.length == 24, 'WOMAC questionnaire requires exactly 24 item responses.'),
        painScore = responsesRaw.sublist(0, 5).reduce((a, b) => a + b),
        stiffnessScore = responsesRaw.sublist(5, 7).reduce((a, b) => a + b),
        functionScore = responsesRaw.sublist(7, 24).reduce((a, b) => a + b),
        totalWomacScore = responsesRaw.reduce((a, b) => a + b);

  Map<String, dynamic> toMap() {
    return {
      'pain_score': painScore,
      'stiffness_score': stiffnessScore,
      'function_score': functionScore,
      'total_womac_score': totalWomacScore,
      'responses_raw_json': jsonEncode(responsesRaw),
    };
  }

  factory QuestionnaireResponse.fromMap(Map<String, dynamic> map) {
    final rawJson = map['responses_raw_json'] as String;
    final List<dynamic> parsed = jsonDecode(rawJson);
    final List<int> responses = parsed.map((e) => e as int).toList();
    return QuestionnaireResponse(responsesRaw: responses);
  }
}
