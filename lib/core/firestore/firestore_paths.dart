class FirestorePaths {
  const FirestorePaths._();

  static const String organizations = 'organizations';
  static const String doctors = 'doctors';
  static const String patients = 'patients';
  static const String clinics = 'clinics';
  static const String appointments = 'appointments';
  static const String invitations = 'invitations';

  static String organization(String organizationId) => '$organizations/$organizationId';
  static String doctorForOrganization(String organizationId, String doctorId) => '$organizations/$organizationId/$doctors/$doctorId';
  static String patientForOrganization(String organizationId, String patientId) => '$organizations/$organizationId/$patients/$patientId';
  static String clinic(String organizationId, String clinicId) => '$organizations/$organizationId/$clinics/$clinicId';
  static String appointment(String organizationId, String appointmentId) => '$organizations/$organizationId/$appointments/$appointmentId';
  static String invitation(String organizationId, String invitationId) => '$organizations/$organizationId/$invitations/$invitationId';
}
