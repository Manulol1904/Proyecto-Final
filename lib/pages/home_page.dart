import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutorias_estudiantes/components/my_drawer.dart';
import 'package:tutorias_estudiantes/components/notifications.dart';
import 'package:tutorias_estudiantes/pages/admin_page.dart';
import 'package:tutorias_estudiantes/pages/account_page.dart';
import 'package:tutorias_estudiantes/pages/adminactions_page.dart';
import 'package:tutorias_estudiantes/pages/request_page.dart';
import 'package:tutorias_estudiantes/pages/student_page.dart';
import 'package:tutorias_estudiantes/services/auth/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Authservice _authservice = Authservice();

  @override
  void initState() {
    super.initState();
    _checkUserInfo();
  }

  Future<String?> _getUserRole() async {
    return await _authservice.getUserRole();
  }

  Future<void> _checkUserInfo() async {
    await Future.delayed(const Duration(milliseconds: 500));
  
    if (!mounted) return;

    User? user = _authservice.getCurrentUser();
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();
            
        if (!mounted) return;

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          if (userData['firstName'] == null || userData['firstName'].isEmpty) {
            if (mounted && context.mounted) {
              _showUpdateDialog();
            }
          }
        }
      } catch (e) {
        debugPrint("Error checking user info: $e");
      }
    }
  }

  void _showUpdateDialog() async {
    String userRole = (await _authservice.getUserRole()) ?? '';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            return false;
          },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("Home"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
        actions: [
          FutureBuilder<String?>(
            future: _getUserRole(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox();
              }
              if (snapshot.hasData) {
                if (snapshot.data == 'Admin') {
                  // Botón para AdminActionsPage si el usuario es admin
                  return IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AdminActionsPage()),
                      );
                    },
                  );
                } else {
                  // Icono de notificaciones para otros roles
                  return NotificationIcon(userRole: snapshot.data ?? '');
                }
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: FutureBuilder<String?>(
        future: _getUserRole(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.data == 'Admin') {
            return const AllUsersPage(showAppBar: false);
          } if (snapshot.data == 'Tutor') {
            return RequestsPage(showAppBar: false);
          } if (snapshot.data == 'Estudiante') {
            return const StudentPage(showAppBar: false);
          } else {
            return const StudentPage(showAppBar: false);
          }
        },
      ),
    );
  }
}
