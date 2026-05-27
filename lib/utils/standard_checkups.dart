import 'package:open_cloud_health/models/profile.dart';

class StandardCheckupTemplate {
  final String name;
  final int frequencyInMonths;
  final String iconName;
  final bool Function(Profile profile) appliesTo;
  final int Function(Profile profile)? customFrequency;

  StandardCheckupTemplate({
    required this.name,
    required this.frequencyInMonths,
    required this.iconName,
    required this.appliesTo,
    this.customFrequency,
  });

  int getFrequency(Profile profile) {
    if (customFrequency != null) {
      return customFrequency!(profile);
    }
    return frequencyInMonths;
  }
}

final List<StandardCheckupTemplate> standardCheckups = [
  StandardCheckupTemplate(
    name: 'Annual Physical Exam',
    frequencyInMonths: 12,
    iconName: 'stethoscope',
    appliesTo: (profile) => true,
  ),
  StandardCheckupTemplate(
    name: 'Dental Exam & Cleaning',
    frequencyInMonths: 6,
    iconName: 'medical_services',
    appliesTo: (profile) => true,
  ),
  StandardCheckupTemplate(
    name: 'Blood Pressure Screening',
    frequencyInMonths: 12,
    iconName: 'blood_pressure',
    appliesTo: (profile) =>
        profile.age >= 18 ||
        profile.chronicConditions.contains('Hypertension') ||
        profile.chronicConditions.contains('Coronary Artery Disease'),
    customFrequency: (profile) {
      if (profile.chronicConditions.contains('Hypertension')) {
        return 3;
      }
      if (profile.chronicConditions.contains('Coronary Artery Disease')) {
        return 6;
      }
      return 12;
    },
  ),
  StandardCheckupTemplate(
    name: 'Skin Exam',
    frequencyInMonths: 12,
    iconName: 'health_and_safety',
    appliesTo: (profile) => profile.age >= 18,
  ),
  StandardCheckupTemplate(
    name: 'Cholesterol Screening',
    frequencyInMonths: 60,
    iconName: 'bloodtype',
    appliesTo: (profile) =>
        profile.age >= 20 ||
        profile.chronicConditions.contains('Hypercholesterolemia') ||
        profile.chronicConditions.contains('Coronary Artery Disease') ||
        profile.chronicConditions.contains('Polycystic Ovary Syndrome (PCOS)'),
    customFrequency: (profile) {
      if (profile.chronicConditions.contains('Hypercholesterolemia') ||
          profile.chronicConditions.contains('Coronary Artery Disease') ||
          profile.chronicConditions.contains('Polycystic Ovary Syndrome (PCOS)')) {
        return 12;
      }
      return 60;
    },
  ),
  StandardCheckupTemplate(
    name: 'Diabetes Screening',
    frequencyInMonths: 36,
    iconName: 'diabetes',
    appliesTo: (profile) =>
        profile.age >= 35 ||
        profile.chronicConditions.contains('Diabetes') ||
        profile.chronicConditions.contains('Polycystic Ovary Syndrome (PCOS)'),
    customFrequency: (profile) {
      if (profile.chronicConditions.contains('Diabetes')) {
        return 6;
      }
      if (profile.chronicConditions.contains('Polycystic Ovary Syndrome (PCOS)')) {
        return 12;
      }
      return 36;
    },
  ),
  StandardCheckupTemplate(
    name: 'Comprehensive Eye Exam',
    frequencyInMonths: 24,
    iconName: 'remove_red_eye',
    appliesTo: (profile) => profile.age < 65,
  ),
  StandardCheckupTemplate(
    name: 'Senior Eye Exam',
    frequencyInMonths: 12,
    iconName: 'remove_red_eye',
    appliesTo: (profile) => profile.age >= 65,
  ),
  StandardCheckupTemplate(
    name: 'Hearing Test',
    frequencyInMonths: 12,
    iconName: 'hearing',
    appliesTo: (profile) => profile.age >= 65,
  ),
  StandardCheckupTemplate(
    name: 'Pap Smear (Cervical Cancer Screening)',
    frequencyInMonths: 36,
    iconName: 'science',
    appliesTo: (profile) =>
        profile.gender == Gender.female &&
        profile.age >= 21 &&
        profile.age <= 65,
  ),
  StandardCheckupTemplate(
    name: 'Mammogram (Breast Cancer Screening)',
    frequencyInMonths: 24,
    iconName: 'woman',
    appliesTo: (profile) =>
        profile.gender == Gender.female && profile.age >= 40,
  ),
  StandardCheckupTemplate(
    name: 'Bone Density (DEXA) Scan',
    frequencyInMonths: 24,
    iconName: 'accessibility',
    appliesTo: (profile) =>
        (profile.gender == Gender.female && profile.age >= 65) ||
        (profile.gender == Gender.male && profile.age >= 70) ||
        profile.chronicConditions.contains('Osteoporosis'),
    customFrequency: (profile) {
      if (profile.chronicConditions.contains('Osteoporosis')) {
        return 12;
      }
      return 24;
    },
  ),
  StandardCheckupTemplate(
    name: 'Prostate Exam & PSA Test',
    frequencyInMonths: 12,
    iconName: 'man',
    appliesTo: (profile) =>
        profile.gender == Gender.male && profile.age >= 50,
  ),
  StandardCheckupTemplate(
    name: 'Colonoscopy (Colorectal Cancer Screening)',
    frequencyInMonths: 120,
    iconName: 'biotech',
    appliesTo: (profile) => profile.age >= 45,
  ),
  // New chronic condition-specific checkups:
  StandardCheckupTemplate(
    name: 'Diabetic Foot Exam',
    frequencyInMonths: 12,
    iconName: 'foot',
    appliesTo: (profile) => profile.chronicConditions.contains('Diabetes'),
  ),
  StandardCheckupTemplate(
    name: 'Diabetic Eye Exam',
    frequencyInMonths: 12,
    iconName: 'remove_red_eye',
    appliesTo: (profile) => profile.chronicConditions.contains('Diabetes'),
  ),
  StandardCheckupTemplate(
    name: 'Kidney Function Test (eGFR/Urine Albumin)',
    frequencyInMonths: 6,
    iconName: 'kidneys',
    appliesTo: (profile) => profile.chronicConditions.contains('Chronic Kidney Disease'),
  ),
  StandardCheckupTemplate(
    name: 'Cardiology Exam',
    frequencyInMonths: 12,
    iconName: 'monitor_heart',
    appliesTo: (profile) => profile.chronicConditions.contains('Coronary Artery Disease'),
  ),
  StandardCheckupTemplate(
    name: 'Asthma/COPD Review',
    frequencyInMonths: 12,
    iconName: 'lungs',
    appliesTo: (profile) =>
        profile.chronicConditions.contains('Asthma') ||
        profile.chronicConditions.contains('COPD'),
  ),
  StandardCheckupTemplate(
    name: 'Mental Health Wellness Check',
    frequencyInMonths: 6,
    iconName: 'psychology',
    appliesTo: (profile) => profile.chronicConditions.contains('Depression'),
  ),
  StandardCheckupTemplate(
    name: 'Joint Health / Rheumatology Exam',
    frequencyInMonths: 12,
    iconName: 'accessibility',
    appliesTo: (profile) => profile.chronicConditions.contains('Arthritis'),
  ),
  StandardCheckupTemplate(
    name: 'Gynecological/Endometriosis Review',
    frequencyInMonths: 12,
    iconName: 'gynecology',
    appliesTo: (profile) => profile.chronicConditions.contains('Endometriosis'),
  ),
  StandardCheckupTemplate(
    name: 'PCOS/Metabolic Review',
    frequencyInMonths: 12,
    iconName: 'female',
    appliesTo: (profile) => profile.chronicConditions.contains('Polycystic Ovary Syndrome (PCOS)'),
  ),
  StandardCheckupTemplate(
    name: 'Thyroid Function Test (TSH)',
    frequencyInMonths: 12,
    iconName: 'thyroid',
    appliesTo: (profile) => profile.chronicConditions.contains('Hypothyroidism'),
  ),
];
