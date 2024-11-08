import 'package:flutter/material.dart';
import 'package:tutorias_estudiantes/pages/account_page.dart';
import 'package:tutorias_estudiantes/pages/alltutories_page.dart';
import 'package:tutorias_estudiantes/pages/chatrooms_page.dart';
import 'package:tutorias_estudiantes/pages/login_page.dart';
import 'package:tutorias_estudiantes/pages/tutoringsession_page.dart';
import 'package:tutorias_estudiantes/pages/userprofle_page.dart';
import 'package:tutorias_estudiantes/services/auth/auth_service.dart';
import 'package:tutorias_estudiantes/pages/setting_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Authservice _authService = Authservice();
  String? userRole;
  String? userUid;
  int _selectedIndex = 0;

  final List<Widget> _studentPages = [
    const TutoringSessionsPage(studentUid: 'userUid', userRole: 'Estudiante'),
    const ChatRoomsPage(),
    const UserProfilePage(userRole: "Estudiante"),
    const SettingsPage(),
  ];

  final List<Widget> _tutorPages = [
    TutoringSessionsPage(tutorUid: 'userUid', userRole: 'Tutor'),
    const ChatRoomsPage(),
    const UserProfilePage(userRole: "Tutor"),
    const SettingsPage(),
  ];

  final List<Widget> _adminPages = [
    const AllTutoringSessionsPage(),
    AccountPage(userRole: 'Admin'),
    const UserProfilePage(userRole: "Admin"),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    _fetchUserUid();
  }

  Future<void> _fetchUserRole() async {
    String? role = await _authService.getUserRole();
    setState(() {
      userRole = role;
    });
  }

  Future<void> _fetchUserUid() async {
    String? uid = _authService.getCurrentUserUid();
    setState(() {
      userUid = uid;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage(onTap: () {})),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userRole == null || userUid == null) {
      return const Center(child: CircularProgressIndicator());
    }

    List<Widget> pages;
    List<BottomNavigationBarItem> navItems;

    switch (userRole) {
      case 'Estudiante':
        pages = _studentPages;
        navItems = [
          const BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Tutorías'),
          const BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cuenta'),
          const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Configuración'),
        ];
        break;
      case 'Tutor':
        pages = _tutorPages;
        navItems = [
          const BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Tutorías'),
          const BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cuenta'),
          const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Configuración'),
        ];
        break;
      case 'Admin':
        pages = _adminPages;
        navItems = [
          const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Tutorías'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cuenta'),
          const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Configuración'),
        ];
        break;
      default:
        pages = [];
        navItems = [];
        break;
    }

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: navItems,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
      floatingActionButton: userRole != 'Admin'
          ? FloatingActionButton(
              onPressed: _logout,
              backgroundColor: Colors.red,
              child: const Icon(Icons.logout),
            )
          : null,
    );
  }
}
