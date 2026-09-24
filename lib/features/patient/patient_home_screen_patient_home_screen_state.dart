part of 'patient_home_screen.dart';

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: _selectedTab,
            children: [
              _HomeContent(onBook: () => setState(() => _selectedTab = 1)),
              const AppointmentsScreen(),
              const DoctorsListScreen(),
              const PatientProfileScreen(),
            ],
          ),
        ),
        bottomNavigationBar: AppBottomNavigationBar(currentIndex: _selectedTab, onTap: (index) => setState(() => _selectedTab = index)),
      );
}
