import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutorias_estudiantes/components/notifications.dart';
import 'package:tutorias_estudiantes/pages/admin_page.dart';
import 'package:tutorias_estudiantes/pages/account_page.dart';
import 'package:tutorias_estudiantes/pages/adminactions_page.dart';
import 'package:tutorias_estudiantes/pages/alltutories_page.dart';
import 'package:tutorias_estudiantes/pages/chatrooms_page.dart';
import 'package:tutorias_estudiantes/pages/request_page.dart';
import 'package:tutorias_estudiantes/pages/setting_page.dart';
import 'package:tutorias_estudiantes/pages/student_page.dart';
import 'package:tutorias_estudiantes/pages/tutoringsession_page.dart';
import 'package:tutorias_estudiantes/pages/userprofle_page.dart';
import 'package:tutorias_estudiantes/services/auth/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Authservice _authservice = Authservice();
  int _selectedIndex = 0;
  String? userRole;
  String? userName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      userRole = await _authservice.getUserRole();
      
      User? user = _authservice.getCurrentUser();
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              userName = userData['firstName'] ?? 'Usuario';
              _isLoading = false;
            });

            if (userData['firstName'] == null || userData['firstName'].isEmpty) {
              _showUpdateDialog();
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showUpdateDialog() async {
    String userRole = (await _authservice.getUserRole()) ?? '';
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // ignore: deprecated_member_use
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: const Text("Actualiza tus datos"),
            content: const Text("Parece que no tienes tu nombre registrado. Por favor, actualiza tu información."),
            actions: <Widget>[
              TextButton(
                child: const Text("Actualizar"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AccountPage(userRole: userRole)),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<BottomNavigationBarItem> _getBottomNavItems() {
    if (userRole == 'Admin') {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school),
          label: 'Tutorías',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Cuenta',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Configuración',
        ),
      ];
    } else {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school),
          label: 'Tutorías',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Cuenta',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Configuración',
        ),
      ];
    }
  }

  Widget _getPageForRole() {
    if (userRole == 'Admin') {
      switch (_selectedIndex) {
        case 0:
          return const AllUsersPage(showAppBar: false);
        case 1:
          return const AllTutoringSessionsPage();
        case 2:
          return const UserProfilePage(userRole: "Admin");
        case 3:
          return const SettingsPage(showAppBar: false);
        default:
          return const AllUsersPage();
      }
    } else if (userRole == 'Tutor') {
      switch (_selectedIndex) {
        case 0:
          return RequestsPage(showAppBar: false);
        case 1:
          return const TutoringSessionsPage(userRole: "Tutor");
        case 2:
          return const ChatRoomsPage(showAppBar: false);
        case 3:
          return const UserProfilePage(userRole: "Tutor", showAppBar: false);
        case 4:
          return const SettingsPage(showAppBar: false);
        default:
          return RequestsPage(showAppBar: false);
      }
    } else {
      switch (_selectedIndex) {
        case 0:
          return const StudentPage(showAppBar: false);
        case 1:
          return const TutoringSessionsPage(userRole: "Estudiante");
        case 2:
          return const ChatRoomsPage(showAppBar: false);
        case 3:
          return const UserProfilePage(userRole: "Estudiante", showAppBar: false);
        case 4:
          return const SettingsPage(showAppBar: false);
        default:
          return const StudentPage(showAppBar: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
        actions: [
          if (userRole != null)
            if (userRole == 'Admin')
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminActionsPage()),
                  );
                },
              )
            else
              NotificationIcon(userRole: userRole ?? ''),
        ],
        leading: null,
        leadingWidth: 0,
        title: userName != null
            ? Row(
                children: [
                  const CircleAvatar(
                    backgroundImage: AssetImage('lib/assets/image.png'),
                    radius: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$userRole: $userName',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              )
            : const Icon(Icons.account_circle),
      ),
      body: _getPageForRole(),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: const Color(0xFF11254B),
          primaryColor: const Color(0xFFF5CD84),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: const Color(0xFFF5CD84),
          unselectedItemColor: Colors.white,
          items: _getBottomNavItems(),
        ),
      ),
    );
  }
}