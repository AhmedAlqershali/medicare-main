part of 'doctor_home_screen.dart';

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  int _selectedTab = 0;
  final _dashboardKey = GlobalKey<_DoctorDashboardState>();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: _selectedTab,
            children: [
              _DoctorDashboard(key: _dashboardKey, onTabSelected: (index) => setState(() => _selectedTab = index)),
              const DoctorAppointmentsScreen(),
              const DoctorPatientsScreen(),
              const DoctorProfileScreen(),
            ],
          ),
        ),
        bottomNavigationBar: RoleBottomNavigationBar(
          currentIndex: _selectedTab,
          onTap: (index) {
            setState(() => _selectedTab = index);
            if (index == 0) _dashboardKey.currentState?.reload();
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'المواعيد'),
            NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'المرضى'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'الملف الشخصي'),
          ],
        ),
      );
}
