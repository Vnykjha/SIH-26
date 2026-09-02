import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('bn'),
    Locale('as'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _strings = {
    'en': {
      'appTitle': 'CREPISENSE',
      'homeHeadline': 'Offline OA risk screening',
      'homeSubtitle':
          'Health worker workflow: intake → questionnaire → mobility test → risk output',
      'homeMode': 'Mode: Standard Screening (Tier 1)',
      'startScreening': 'Start screening',
      'savedScreenings': 'Saved screenings',
      'patientIntake': 'Patient Intake',
      'patientName': 'Patient name',
      'required': 'Required',
      'age': 'Age',
      'sex': 'Sex',
      'occupation': 'Occupation',
      'heightCm': 'Height (cm)',
      'weightKg': 'Weight (kg)',
      'priorInjuryHistory': 'Prior injury history',
      'injuryNotes': 'Injury notes (optional)',
      'preferredLanguage': 'Preferred language',
      'campId': 'Camp ID',
      'district': 'District',
      'continueQuestionnaire': 'Continue to questionnaire',
      'womacQuestionnaire': 'WOMAC Questionnaire',
      'severityRating': 'Severity Rating',
      'continueMobility': 'Continue to Mobility Sensor Test',
      'language': 'Language',
      'loading': 'Preparing your screening workspace...',
      'loadingSubtitle': 'Securing local data and ML model',
      'selectLanguage': 'Select language',
    },
    'hi': {
      'appTitle': 'क्रेपिसेंस',
      'homeHeadline': 'ऑफलाइन OA जोखिम स्क्रीनिंग',
      'homeSubtitle':
          'स्वास्थ्य कार्यकर्ता की प्रक्रिया: intake → questionnaire → mobility test → risk output',
      'homeMode': 'मोड: स्टैंडर्ड स्क्रीनिंग (Tier 1)',
      'startScreening': 'स्क्रीनिंग शुरू करें',
      'savedScreenings': 'सहेजे गए स्क्रीनिंग',
      'patientIntake': 'रोगी विवरण',
      'patientName': 'रोगी का नाम',
      'required': 'आवश्यक',
      'age': 'उम्र',
      'sex': 'लिंग',
      'occupation': 'पेशा',
      'heightCm': 'ऊँचाई (cm)',
      'weightKg': 'वजन (kg)',
      'priorInjuryHistory': 'पिछली चोट का इतिहास',
      'injuryNotes': 'चोट का विवरण (वैकल्पिक)',
      'preferredLanguage': 'पसंदीदा भाषा',
      'campId': 'कैम्प ID',
      'district': 'जिला',
      'continueQuestionnaire': 'प्रश्नावली पर जारी रखें',
      'womacQuestionnaire': 'WOMAC प्रश्नावली',
      'severityRating': 'तीव्रता रेटिंग',
      'continueMobility': 'मोबिलिटी टेस्ट पर जारी रखें',
      'language': 'भाषा',
      'loading': 'आपका स्क्रीनिंग वर्कस्पेस तैयार किया जा रहा है...',
      'loadingSubtitle': 'लोकल डेटा और ML मॉडल को सुरक्षित किया जा रहा है',
      'selectLanguage': 'भाषा चुनें',
    },
    'bn': {
      'appTitle': 'ক্রেপিসেন্স',
      'homeHeadline': 'অফলাইন OA ঝুঁকি স্ক্রিনিং',
      'homeSubtitle':
          'স্বাস্থ্যকর্মীর কাজের প্রক্রিয়া: intake → questionnaire → mobility test → risk output',
      'homeMode': 'মোড: স্ট্যান্ডার্ড স্ক্রিনিং (Tier 1)',
      'startScreening': 'স্ক্রিনিং শুরু করুন',
      'savedScreenings': 'সংরক্ষিত স্ক্রিনিং',
      'patientIntake': 'রোগীর ডেটা',
      'patientName': 'রোগীর নাম',
      'required': 'প্রয়োজনীয়',
      'age': 'বয়স',
      'sex': 'লিঙ্গ',
      'occupation': 'পেশা',
      'heightCm': 'উচ্চতা (cm)',
      'weightKg': 'ওজন (kg)',
      'priorInjuryHistory': 'পূর্ববর্তী আঘাতের ইতিহাস',
      'injuryNotes': 'আঘাতের নোট (ঐচ্ছিক)',
      'preferredLanguage': 'পছন্দের ভাষা',
      'campId': 'ক্যাম্প ID',
      'district': 'জেলা',
      'continueQuestionnaire': 'প্রশ্নাবলীতে চালিয়ে যান',
      'womacQuestionnaire': 'WOMAC প্রশ্নাবলী',
      'severityRating': 'তীব্রতা রেটিং',
      'continueMobility': 'মোবিলিটি টেস্টে চালিয়ে যান',
      'language': 'ভাষা',
      'loading': 'আপনার স্ক্রিনিং ওয়ার্কস্পেস প্রস্তুত হচ্ছে...',
      'loadingSubtitle': 'লোকাল ডেটা ও ML মডেল নিরাপদ করা হচ্ছে',
      'selectLanguage': 'ভাষা নির্বাচন করুন',
    },
    'as': {
      'appTitle': 'ক্রেপিসেন্স',
      'homeHeadline': 'অফলাইন OA ঝুঁকি স্ক্ৰিনিং',
      'homeSubtitle':
          'স্বাস্থ্যকৰ্মীৰ প্ৰক্ৰিয়া: intake → questionnaire → mobility test → risk output',
      'homeMode': 'ম’ড: স্টেণ্ডার্ড স্ক্ৰিনিং (Tier 1)',
      'startScreening': 'স্ক্ৰিনিং আৰম্ভ কৰক',
      'savedScreenings': 'সংৰক্ষিত স্ক্ৰিনিং',
      'patientIntake': 'গ্ৰাহক তথ্য',
      'patientName': 'গ্ৰাহকৰ নাম',
      'required': 'আবশ্যক',
      'age': 'বয়স',
      'sex': 'লিংগ',
      'occupation': 'পেশা',
      'heightCm': 'উচ্চতা (cm)',
      'weightKg': 'ওজন (kg)',
      'priorInjuryHistory': 'পূৰ্বৱৰ্তী আঘাতৰ ইতিহাস',
      'injuryNotes': 'আঘাতৰ নোট (ঐচ্ছিক)',
      'preferredLanguage': 'পছন্দৰ ভাষা',
      'campId': 'কেম্প ID',
      'district': 'জিলা',
      'continueQuestionnaire': 'প্ৰশ্নাৱলীলৈ আগবাঢ়ক',
      'womacQuestionnaire': 'WOMAC প্ৰশ্নাৱলী',
      'severityRating': 'তীব্রতা ৰেটিং',
      'continueMobility': 'মোবিলিটি টেষ্টলৈ আগবাঢ়ক',
      'language': 'ভাষা',
      'loading': 'আপোনাৰ স্ক্ৰিনিংৰ ওয়ার্কস্পেস প্ৰস্তুত হৈছে...',
      'loadingSubtitle': 'লোকেল ডেটা আৰু ML মডেল সুৰক্ষিত কৰা হৈছে',
      'selectLanguage': 'ভাষা বাছনি কৰক',
    },
  };

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(localizations != null, 'No AppLocalizations found in context');
    return localizations!;
  }

  static String translate(BuildContext context, String key) {
    return AppLocalizations.of(context).tr(key);
  }

  String tr(String key) {
    final map = _strings[locale.languageCode] ?? _strings['en']!;
    return map[key] ?? _strings['en']![key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'hi', 'bn', 'as'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
