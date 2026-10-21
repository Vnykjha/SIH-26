import 'dart:async';

import 'package:flutter/material.dart';

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
      'healthWorkerSignIn': 'Health worker sign in',
      'email': 'Email',
      'password': 'Password',
      'enterEmail': 'Enter email',
      'enterPassword': 'Enter password',
      'signIn': 'Sign in',
      'invalidCredentials': 'Invalid credentials. Please try again.',
      'registerHealthWorker': 'Register health worker',
      'registrationHint':
          'Creates a health-worker account in Firebase Authentication. Admin accounts are managed separately.',
      'fullName': 'Full name',
      'enterName': 'Enter your name',
      'confirmPassword': 'Confirm password',
      'passwordsDoNotMatch': 'Passwords do not match',
      'createAccount': 'Create account',
      'needAccount': 'New health worker? Register',
      'alreadyHaveAccount': 'Already registered? Sign in',
      'emailAlreadyInUse': 'An account already exists for this email.',
      'invalidEmail': 'Enter a valid email address.',
      'weakPassword': 'Use a password with at least 6 characters.',
      'registrationDisabled':
          'Email/password registration is disabled in Firebase.',
      'networkError': 'Check your internet connection and try again.',
      'tooManyRequests': 'Too many attempts. Wait a moment and try again.',
      'authFailed': 'Authentication failed. Please try again.',
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
      'healthWorkerSignIn': 'स्वास्थ्य कार्यकर्ता लॉगिन',
      'email': 'ईमेल',
      'password': 'पासवर्ड',
      'enterEmail': 'ईमेल दर्ज करें',
      'enterPassword': 'पासवर्ड दर्ज करें',
      'signIn': 'लॉग इन करें',
      'invalidCredentials': 'लॉगिन विवरण गलत हैं। फिर से प्रयास करें।',
      'registerHealthWorker': 'स्वास्थ्य कार्यकर्ता पंजीकरण',
      'registrationHint':
          'Firebase Authentication में स्वास्थ्य कार्यकर्ता का खाता बनेगा। एडमिन खाते अलग से बनाए जाते हैं।',
      'fullName': 'पूरा नाम',
      'enterName': 'अपना नाम दर्ज करें',
      'confirmPassword': 'पासवर्ड की पुष्टि करें',
      'passwordsDoNotMatch': 'पासवर्ड मेल नहीं खाते',
      'createAccount': 'खाता बनाएं',
      'needAccount': 'नए स्वास्थ्य कार्यकर्ता? पंजीकरण करें',
      'alreadyHaveAccount': 'पहले से पंजीकृत? साइन इन करें',
      'emailAlreadyInUse': 'इस ईमेल का खाता पहले से मौजूद है।',
      'invalidEmail': 'सही ईमेल पता दर्ज करें।',
      'weakPassword': 'कम से कम 6 अक्षरों का पासवर्ड रखें।',
      'registrationDisabled': 'Firebase में ईमेल/पासवर्ड पंजीकरण बंद है।',
      'networkError': 'इंटरनेट कनेक्शन जांचें और फिर प्रयास करें।',
      'tooManyRequests': 'बहुत अधिक प्रयास हुए। थोड़ी देर बाद फिर प्रयास करें।',
      'authFailed': 'प्रमाणीकरण विफल हुआ। फिर से प्रयास करें।',
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
      'healthWorkerSignIn': 'স্বাস্থ্যকর্মীর সাইন ইন',
      'email': 'ইমেল',
      'password': 'পাসওয়ার্ড',
      'enterEmail': 'ইমেল লিখুন',
      'enterPassword': 'পাসওয়ার্ড লিখুন',
      'signIn': 'সাইন ইন',
      'invalidCredentials': 'লগইন তথ্য সঠিক নয়। আবার চেষ্টা করুন।',
      'registerHealthWorker': 'স্বাস্থ্যকর্মী নিবন্ধন',
      'registrationHint':
          'Firebase Authentication-এ স্বাস্থ্যকর্মীর অ্যাকাউন্ট তৈরি হবে। অ্যাডমিন অ্যাকাউন্ট আলাদাভাবে পরিচালিত হয়।',
      'fullName': 'পুরো নাম',
      'enterName': 'আপনার নাম লিখুন',
      'confirmPassword': 'পাসওয়ার্ড নিশ্চিত করুন',
      'passwordsDoNotMatch': 'পাসওয়ার্ড মিলছে না',
      'createAccount': 'অ্যাকাউন্ট তৈরি করুন',
      'needAccount': 'নতুন স্বাস্থ্যকর্মী? নিবন্ধন করুন',
      'alreadyHaveAccount': 'আগে নিবন্ধিত? সাইন ইন করুন',
      'emailAlreadyInUse': 'এই ইমেলের জন্য অ্যাকাউন্ট আগে থেকেই আছে।',
      'invalidEmail': 'সঠিক ইমেল ঠিকানা লিখুন।',
      'weakPassword': 'কমপক্ষে ৬ অক্ষরের পাসওয়ার্ড দিন।',
      'registrationDisabled': 'Firebase-এ ইমেল/পাসওয়ার্ড নিবন্ধন বন্ধ আছে।',
      'networkError': 'ইন্টারনেট সংযোগ পরীক্ষা করে আবার চেষ্টা করুন।',
      'tooManyRequests':
          'অনেকবার চেষ্টা হয়েছে। কিছুক্ষণ পরে আবার চেষ্টা করুন।',
      'authFailed': 'প্রমাণীকরণ ব্যর্থ হয়েছে। আবার চেষ্টা করুন।',
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
      'healthWorkerSignIn': 'স্বাস্থ্যকৰ্মীৰ ছাইন ইন',
      'email': 'ইমেইল',
      'password': 'পাছৱৰ্ড',
      'enterEmail': 'ইমেইল লিখক',
      'enterPassword': 'পাছৱৰ্ড লিখক',
      'signIn': 'ছাইন ইন',
      'invalidCredentials': 'লগইনৰ তথ্য ভুল। পুনৰ চেষ্টা কৰক।',
      'registerHealthWorker': 'স্বাস্থ্যকৰ্মীৰ পঞ্জীয়ন',
      'registrationHint':
          'Firebase Authentication-ত স্বাস্থ্যকৰ্মীৰ একাউণ্ট সৃষ্টি হ’ব। এডমিন একাউণ্ট পৃথকে পৰিচালনা কৰা হয়।',
      'fullName': 'সম্পূৰ্ণ নাম',
      'enterName': 'আপোনাৰ নাম লিখক',
      'confirmPassword': 'পাছৱৰ্ড নিশ্চিত কৰক',
      'passwordsDoNotMatch': 'পাছৱৰ্ড মিল নাই',
      'createAccount': 'একাউণ্ট সৃষ্টি কৰক',
      'needAccount': 'নতুন স্বাস্থ্যকৰ্মী? পঞ্জীয়ন কৰক',
      'alreadyHaveAccount': 'আগতে পঞ্জীয়ন কৰিছে? ছাইন ইন কৰক',
      'emailAlreadyInUse': 'এই ইমেইলৰ একাউণ্ট ইতিমধ্যে আছে।',
      'invalidEmail': 'সঠিক ইমেইল ঠিকনা লিখক।',
      'weakPassword': 'কমেও ৬টা আখৰৰ পাছৱৰ্ড দিয়ক।',
      'registrationDisabled': 'Firebase-ত ইমেইল/পাছৱৰ্ড পঞ্জীয়ন বন্ধ আছে।',
      'networkError': 'ইণ্টাৰনেট সংযোগ পৰীক্ষা কৰি পুনৰ চেষ্টা কৰক।',
      'tooManyRequests': 'বহুত চেষ্টা হৈছে। অলপ পাছত পুনৰ চেষ্টা কৰক।',
      'authFailed': 'প্ৰমাণীকৰণ বিফল হৈছে। পুনৰ চেষ্টা কৰক।',
    },
  };

  static AppLocalizations of(BuildContext context) {
    final localizations =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
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

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'hi', 'bn', 'as'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
