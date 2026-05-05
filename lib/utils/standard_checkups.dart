import 'package:open_cloud_health/models/profile.dart';

class StandardCheckupTemplate {
  final String name;
  final int frequencyInMonths;
  final String iconName;
  final bool Function(Profile profile) appliesTo;

  StandardCheckupTemplate({
    required this.name,
    required this.frequencyInMonths,
    required this.iconName,
    required this.appliesTo,
  });
}

int calculateAge(DateTime birthDate) {
  final today = DateTime.now();
  int age = today.year - birthDate.year;
  if (today.month < birthDate.month ||
      (today.month == birthDate.month && today.day < birthDate.day)) {
    age--;
  }
  return age;
}

final List<StandardCheckupTemplate> standardCheckups = [
  StandardCheckupTemplate(
    name: 'Annual Physical Exam',
    frequencyInMonths: 12,
    iconName: 'monitor_heart',
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
    iconName: 'monitor_heart',
    appliesTo: (profile) => calculateAge(profile.dateOfBirth) >= 18,
  ),
  StandardCheckupTemplate(
    name: 'Skin Exam',
    frequencyInMonths: 12,
    iconName: 'health_and_safety',
    appliesTo: (profile) => calculateAge(profile.dateOfBirth) >= 18,
  ),
  StandardCheckupTemplate(
    name: 'Cholesterol Screening',
    frequencyInMonths: 60,
    iconName: 'bloodtype',
    appliesTo: (profile) => calculateAge(profile.dateOfBirth) >= 20,
  ),
  StandardCheckupTemplate(
    name: 'Diabetes Screening',
    frequencyInMonths: 36,
    iconName: 'bloodtype',
    appliesTo: (profile) => calculateAge(profile.dateOfBirth) >= 35,
  ),
  StandardCheckupTemplate(
    name: 'Comprehensive Eye Exam',
    frequencyInMonths: 24,
    iconName: 'remove_red_eye',
    appliesTo: (profile) => calculateAge(profile.dateOfBirth) < 65,
  ),
  StandardCheckupTemplate(
    name: 'Senior Eye Exam',
    frequencyInMonths: 12,
    iconName: 'remove_red_eye',
    appliesTo: (profile) => calculateAge(profile.dateOfBirth) >= 65,
  ),
  StandardCheckupTemplate(
    name: 'Hearing Test',
    frequencyInMonths: 12,
    iconName: 'hearing',
    appliesTo: (profile) => calculateAge(profile.dateOfBirth) >= 65,
  ),
  StandardCheckupTemplate(
    name: 'Pap Smear (Cervical Cancer Screening)',
    frequencyInMonths: 36,
    iconName: 'science',
    appliesTo: (profile) =>
        profile.gender == Gender.female &&
        calculateAge(profile.dateOfBirth) >= 21 &&
        calculateAge(profile.dateOfBirth) <= 65,
  ),
  StandardCheckupTemplate(
    name: 'Mammogram (Breast Cancer Screening)',
    frequencyInMonths: 24,
    iconName: 'woman',
    appliesTo: (profile) =>
        profile.gender == Gender.female && calculateAge(profile.dateOfBirth) >= 40,
  ),
  StandardCheckupTemplate(
    name: 'Bone Density (DEXA) Scan',
    frequencyInMonths: 24,
    iconName: 'accessibility',
    appliesTo: (profile) =>
        (profile.gender == Gender.female && calculateAge(profile.dateOfBirth) >= 65) ||
        (profile.gender == Gender.male && calculateAge(profile.dateOfBirth) >= 70),
  ),
  StandardCheckupTemplate(
    name: 'Prostate Exam & PSA Test',
    frequencyInMonths: 12,
    iconName: 'man',
    appliesTo: (profile) =>
        profile.gender == Gender.male && calculateAge(profile.dateOfBirth) >= 50,
  ),
  StandardCheckupTemplate(
    name: 'Colonoscopy (Colorectal Cancer Screening)',
    frequencyInMonths: 120,
    iconName: 'biotech',
    appliesTo: (profile) => calculateAge(profile.dateOfBirth) >= 45,
  ),
];
