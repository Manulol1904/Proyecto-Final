import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:tutorias_estudiantes/components/my_drawer.dart';
import 'package:tutorias_estudiantes/pages/account_page.dart';
import 'package:tutorias_estudiantes/pages/chat_page.dart';
import 'package:tutorias_estudiantes/pages/request_page.dart'; // Importar RequestsPage
import 'package:tutorias_estudiantes/pages/user_page.dart';
import 'package:tutorias_estudiantes/services/auth/auth_service.dart';
import 'package:tutorias_estudiantes/services/chat/chat_service.dart';
import 'package:tutorias_estudiantes/themes/dark_mode.dart';
import 'package:tutorias_estudiantes/themes/light_mode.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ChatService _chatService = ChatService();
  final Authservice _authservice = Authservice();

  // Para la búsqueda y el filtro
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String selectedSpecialty = 'All'; // Inicialmente, selecciona "All"

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
  String userRole = (await _authservice.getUserRole()) as String? ?? ''; // Usamos await para esperar el valor de getUserRole
  showDialog(
    context: context,
    barrierDismissible: false, // Eliminar la opción de cerrar tocando fuera
    builder: (BuildContext context) {
      return AlertDialog(
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

          if (snapshot.data == 'Tutor') {
            return RequestsPage(showAppBar: false); // Pasar showAppBar como false para ocultar el AppBar
          } else {
            return _buildUserList(); // Mostrar la lista de usuarios en caso contrario
          }
        },
      ),
    );
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Divider(
        color: Theme.of(context).colorScheme.primary,
        thickness: 1,
      ),
    );
  }

  // Construir una lista de usuarios, excluyendo al usuario conectado y mostrando solo tutores
  Widget _buildUserList() {
    return Column(
      children: [
        // Barra de búsqueda
        // Barra de búsqueda
Padding(
  padding: const EdgeInsets.all(8.0),
  child: TextField(
    controller: _searchController,
    decoration: InputDecoration(
      filled: true,
      fillColor: Theme.of(context).primaryColor,
      hintText: 'Buscar tutor',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
    ),
    onSubmitted: (value) {
      setState(() {
        searchQuery = value.toLowerCase(); // Actualiza searchQuery cuando se presiona Enter
      });
    },
  ),
),

        // Filtros de especialidad
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFilterChip('All'),
              _buildFilterChip('Matemáticas'),
              _buildFilterChip('Inglés'),
              _buildFilterChip('Física'),
              // Agrega más chips según sea necesario
            ],
          ),
        ),
        // Línea separadora
        _buildSeparator(),
        // Lista de usuarios
        Expanded(
          child: StreamBuilder(
            stream: FirebaseFirestore.instance.collection('Users').snapshots(), // Acceso a la colección "Users"
            builder: (context, snapshot) {
              // error
              if (snapshot.hasError) {
                return const Text("Error");
              }

              // loading..
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // No hay datos
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text("No hay tutores disponibles.");
              }

              // Filtrar solo los usuarios con rol de "Tutor"
              final tutorUsers = snapshot.data!.docs
                  .where((doc) => doc['rol'] == 'Tutor') // Filtra por rol
                  .where((doc) {
                    final userData = doc.data() as Map<String, dynamic>;
                    final matchesSearchQuery = userData['firstName'].toString().toLowerCase().contains(searchQuery) ||
                                                 userData['lastName'].toString().toLowerCase().contains(searchQuery);
                    final matchesSpecialty = selectedSpecialty == 'All' || userData['subjectArea'] == selectedSpecialty;
                    return matchesSearchQuery && matchesSpecialty; // Filtra por nombre y especialidad
                  })
                  .toList();

              // return list view for only tutors
              return ListView(
                children: tutorUsers
                    .map<Widget>((doc) => _buildUserListItem(doc.data(), context)) // Pasar los datos de cada tutor
                    .toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  // Construir un chip de filtro
  Widget _buildFilterChip(String specialty) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(
          specialty,
          style: TextStyle(
            color: selectedSpecialty == specialty 
              ? Colors.white 
              : Theme.of(context).textTheme.bodyMedium?.color
          ),
        ),
        selected: selectedSpecialty == specialty,
        onSelected: (selected) {
          setState(() {
            selectedSpecialty = specialty;
          });
        },
        backgroundColor: Theme.of(context).primaryColor,
        selectedColor: Colors.black87,
        checkmarkColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: const BorderSide(color: Colors.transparent),
        ),
      ),
    );
  }

  // construir el ListTile para cada tutor
  Widget _buildUserListItem(Map<String, dynamic> userData, BuildContext context) {
    // display all tutors except the current user
    if (userData["email"] != _authservice.getCurrentUser()!.email) {
      return Column(
        children: [
          ListTile(
            title: Text("${userData["firstName"]} ${userData["lastName"]}"), // Muestra el nombre del tutor
            subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Email: ${userData['email']}"), // Email
              Text("Especialidad: ${userData['subjectArea']}"),
             ],
             ), // Área de especialidad (subjectArea), // Muestra la especialidad del tutor// Ícono para navegar
            onTap: () {
              // Navegar a UserDetailPage con más información
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserDetailPage(
                    receiverEmail: userData["email"].toString(), // Convertir a String
                    receiverID: userData["uid"].toString(), // Convertir a String
                    firstName: userData["firstName"].toString(), // Convertir a String
                    lastName: userData["lastName"].toString(), // Convertir a String
                    role: userData["rol"].toString(), // Convertir a String
                    subjectArea: userData["subjectArea"].toString(), // Convertir a String
                  ),
                ),
              );
            },
          ),
          // Línea separadora entre tutores
          _buildSeparator()
        ],
      );
    } else {
      return Container(); // No mostrar el usuario actual
    }
  }
}
