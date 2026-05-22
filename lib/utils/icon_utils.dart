import 'package:flutter/material.dart';
import 'package:healthicons_flutter/healthicons_flutter.dart';
import 'package:open_cloud_health/models/history_event.dart';

IconData getCheckupIcon(String? iconName) {
  switch (iconName) {
    case 'medical_services':
      return Icons.medical_services;
    case 'remove_red_eye':
      return Icons.remove_red_eye;
    case 'monitor_heart':
      return Icons.monitor_heart;
    case 'woman':
      return Icons.woman;
    case 'science':
      return Icons.science;
    case 'man':
      return Icons.man;
    case 'biotech':
      return Icons.biotech;
    case 'event':
      return Icons.event;
    case 'health_and_safety':
      return Icons.health_and_safety;
    case 'bloodtype':
      return Icons.bloodtype;
    case 'hearing':
      return Icons.hearing;
    case 'accessibility':
      return Icons.accessibility;
    default:
      return Icons.health_and_safety;
  }
}

Widget getHistoryEventIcon(EventType type, {Color? color, double size = 24}) {
  switch (type) {
    case EventType.period:
      return BloodDropOutline(color: color, width: size, height: size);
    case EventType.checkup:
      return StethoscopeOutline(color: color, width: size, height: size);
    case EventType.procedure:
      return BandagedOutline(color: color, width: size, height: size);
    case EventType.labTest:
      return TestTubesOutline(color: color, width: size, height: size);
    case EventType.psychologistVisit:
      return MentalHealthOutline(color: color, width: size, height: size);
    case EventType.specialistConsultation:
      return DoctorOutline(color: color, width: size, height: size);
    case EventType.hospitalStay:
      return HospitalOutline(color: color, width: size, height: size);
    case EventType.therapy:
      return WalkingOutline(color: color, width: size, height: size);
    case EventType.vaccination:
      return SyringeOutline(color: color, width: size, height: size);
    case EventType.dentalTreatment:
      return ToothOutline(color: color, width: size, height: size);
    case EventType.imaging:
      return XrayOutline(color: color, width: size, height: size);
    case EventType.other:
      return DiagnosticsOutline(color: color, width: size, height: size);
  }
}

Widget getCheckupIconWidget(String? iconName, {String? checkupName, Color? color, double size = 28}) {
  if (checkupName != null) {
    final lowerName = checkupName.toLowerCase();
    if (lowerName.contains('physical')) {
      return StethoscopeOutline(color: color, width: size, height: size);
    } else if (lowerName.contains('blood pressure')) {
      return BloodPressureOutline(color: color, width: size, height: size);
    } else if (lowerName.contains('diabetes') || lowerName.contains('sugar')) {
      return SugarOutline(color: color, width: size, height: size);
    }
  }

  switch (iconName) {
    case 'stethoscope':
      return StethoscopeOutline(color: color, width: size, height: size);
    case 'blood_pressure':
      return BloodPressureOutline(color: color, width: size, height: size);
    case 'diabetes':
    case 'sugar':
      return SugarOutline(color: color, width: size, height: size);
    case 'monitor_heart':
      return HeartbeatOutline(color: color, width: size, height: size);
    case 'medical_services':
      return ToothOutline(color: color, width: size, height: size);
    case 'health_and_safety':
      return SkinCancerOutline(color: color, width: size, height: size);
    case 'bloodtype':
      return BloodDropOutline(color: color, width: size, height: size);
    case 'remove_red_eye':
      return EyeOutline(color: color, width: size, height: size);
    case 'hearing':
      return EarOutline(color: color, width: size, height: size);
    case 'science':
      return TestTubesOutline(color: color, width: size, height: size);
    case 'woman':
      return BreastsOutline(color: color, width: size, height: size);
    case 'accessibility':
      return SkeletonOutline(color: color, width: size, height: size);
    case 'man':
      return UrologyOutline(color: color, width: size, height: size);
    case 'biotech':
      return IntestineOutline(color: color, width: size, height: size);
    case 'event':
    default:
      return StethoscopeOutline(color: color, width: size, height: size);
  }
}

Widget getVitalIcon(String label, {Color? color, double size = 28}) {
  switch (label.toLowerCase()) {
    case 'period':
      return BloodDropOutline(color: color, width: size, height: size);
    case 'bp':
    case 'blood pressure':
      return BloodPressureOutline(color: color, width: size, height: size);
    case 'heart':
    case 'heart rate':
    case 'pulse':
      return HeartbeatOutline(color: color, width: size, height: size);
    case 'weight':
    case 'scale':
      return WeightOutline(color: color, width: size, height: size);
    case 'sugar':
    case 'blood sugar':
    case 'glucose':
      return SugarOutline(color: color, width: size, height: size);
    default:
      return StethoscopeOutline(color: color, width: size, height: size);
  }
}


