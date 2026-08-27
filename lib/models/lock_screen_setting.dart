class LockScreenSetting {
  LockScreenSetting({
    required this.profileId,
    this.showName = true,
    this.showAge = true,
    this.showBloodType = true,
    this.showOrganDonor = true,
    this.showChronicConditions = true,
    this.showAllergies = true,
    this.showMedications = true,
    this.showContacts = true,
    this.showInsurance = true,
    this.isEnabled = false,
  });

  final String profileId;
  final bool showName;
  final bool showAge;
  final bool showBloodType;
  final bool showOrganDonor;
  final bool showChronicConditions;
  final bool showAllergies;
  final bool showMedications;
  final bool showContacts;
  final bool showInsurance;
  final bool isEnabled;

  LockScreenSetting copyWith({
    String? profileId,
    bool? showName,
    bool? showAge,
    bool? showBloodType,
    bool? showOrganDonor,
    bool? showChronicConditions,
    bool? showAllergies,
    bool? showMedications,
    bool? showContacts,
    bool? showInsurance,
    bool? isEnabled,
  }) {
    return LockScreenSetting(
      profileId: profileId ?? this.profileId,
      showName: showName ?? this.showName,
      showAge: showAge ?? this.showAge,
      showBloodType: showBloodType ?? this.showBloodType,
      showOrganDonor: showOrganDonor ?? this.showOrganDonor,
      showChronicConditions: showChronicConditions ?? this.showChronicConditions,
      showAllergies: showAllergies ?? this.showAllergies,
      showMedications: showMedications ?? this.showMedications,
      showContacts: showContacts ?? this.showContacts,
      showInsurance: showInsurance ?? this.showInsurance,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
