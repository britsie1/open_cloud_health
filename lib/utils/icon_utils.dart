import 'package:flutter/material.dart';

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
