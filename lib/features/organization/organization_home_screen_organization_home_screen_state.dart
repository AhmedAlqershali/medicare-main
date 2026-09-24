part of 'organization_home_screen.dart';

class _OrganizationHomeScreenState extends State<OrganizationHomeScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: _selectedTab,
            children: [
              _OrganizationDashboard(onTabSelected: (index) => setState(() => _selectedTab = index)),
              const OrganizationClinicsScreen(),
              const OrganizationDoctorsScreen(),
              const OrganizationProfileScreen(),
            ],
          ),
        ),
        bottomNavigationBar: RoleBottomNavigationBar(
          currentIndex: _selectedTab,
          onTap: (index) => setState(() => _selectedTab = index),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
            NavigationDestination(icon: Icon(Icons.local_hospital_outlined), selectedIcon: Icon(Icons.local_hospital), label: 'العيادات'),
            NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'الأطباء'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'الملف الشخصي'),
          ],
        ),
      );
}
