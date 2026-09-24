part of 'doctors_screens.dart';

class DoctorDetailsScreen extends StatefulWidget {
  const DoctorDetailsScreen({super.key, required this.doctor});
  DoctorDetailsScreen.preview({
    super.key,
    required String initials,
    required String name,
    required String specialty,
    required String clinic,
    required String location,
    required String rating,
    required String reviews,
    required String experience,
    required String bio,
    required List<String> services,
    required Color color,
    required String doctorId,
  }) : doctor = DoctorData(id: doctorId, initials: initials, name: name, specialty: specialty, clinic: clinic, location: location, rating: rating, reviews: reviews, experience: experience, bio: bio, services: services, color: color);
  final DoctorData doctor;

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}
