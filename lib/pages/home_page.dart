import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutorias_estudiantes/components/my_drawer.dart';
import 'package:tutorias_estudiantes/components/notifications.dart';
import 'package:tutorias_estudiantes/pages/admin_page.dart';
import 'package:tutorias_estudiantes/pages/account_page.dart';
import 'package:tutorias_estudiantes/pages/request_page.dart'; // Importar RequestsPage
import 'package:tutorias_estudiantes/pages/student_page.dart';
import 'package:tutorias_estudiantes/services/auth/auth_service.dart';
 // Importar el widget de notificaciones

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
    _checkUserInfo(); // Verifica la información del usuario al iniciar
  }

  Future<String?> _getUserRole() async {
    return await _authservice.getUserRole();
  }

  // Verifica si el usuario tiene un nombre
  Future<void> _checkUserInfo() async {
    User? user = _authservice.getCurrentUser();
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        if (userData['firstName'] == null || userData['firstName'].isEmpty) {
          _showUpdateDialog(); // Muestra el popup si no tiene nombre
        }
      }
    }
  }

  // Muestra un popup para que el usuario actualice su información
  void _showUpdateDialog() async {
  String userRole = (await _authservice.getUserRole()) as String? ?? ''; // Wait for user role
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent dismissing by tapping outside
    builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async {
          return false; // Prevent dialog from being dismissed
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
                return const SizedBox(); // Si está cargando, mostrar nada
              }
              if (snapshot.hasData) {
                return NotificationIcon(userRole: snapshot.data ?? ''); // Pasar el rol del usuario al ícono de notificaciones
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
            return const AllUsersPage(showAppBar: false); // Pasar showAppBar como false para ocultar el AppBar
          } if (snapshot.data == 'Tutor') {
            return RequestsPage(showAppBar: false); // Pasar showAppBar como false para ocultar el AppBar
          } if (snapshot.data == 'Estudiante') {
            return const StudentPage(showAppBar: false); // Pasar showAppBar como false para ocultar el AppBar
          } else {
            return const StudentPage(showAppBar: false);
          }
        },
      ),
    );
  }
}
