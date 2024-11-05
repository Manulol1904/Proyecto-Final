// ignore_for_file: sort_child_properties_last, file_names, use_super_parameters, library_private_types_in_public_api, unnecessary_cast, unnecessary_to_list_in_spreads, use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutorias_estudiantes/pages/adduser_page.dart';
import 'package:tutorias_estudiantes/services/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AllUsersPage extends StatefulWidget {
  final bool showAppBar;

  const AllUsersPage({Key? key, this.showAppBar = true}) : super(key: key);

  @override
  _AllUsersPageState createState() => _AllUsersPageState();
}

class _AllUsersPageState extends State<AllUsersPage> {
  final Authservice _authservice = Authservice();
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String selectedRole = 'All';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final currentUserUid = _auth.currentUser?.uid;

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Todos los Usuarios'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            )
          : null,
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).primaryColor,
                hintText: 'Buscar usuario',
                hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          // Chips de filtro
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Estudiante'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Tutor'),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('Users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Error"));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No hay usuarios disponibles."));
                }

                final filteredUsers = snapshot.data!.docs.where((doc) {
                  final userData = doc.data() as Map<String, dynamic>;
                  final matchesSearchQuery = userData['firstName'].toString().toLowerCase().contains(searchQuery) ||
                      userData['lastName'].toString().toLowerCase().contains(searchQuery);
                  final matchesRole = selectedRole == 'All' || userData['rol'] == selectedRole;
                  final isNotCurrentUser = userData['uid'] != currentUserUid;
                  return matchesSearchQuery && matchesRole && isNotCurrentUser;
                }).toList();

                return ListView(
                  children: [
                    _buildAddUserCard(context), // Tarjeta "Agregar Usuario"
                    ...filteredUsers.map<Widget>((doc) => _buildUserCard(doc.data(), context)).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Crear la tarjeta de "Agregar Usuario"
  Widget _buildAddUserCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 4,
      child: ListTile(
        title: const Text("Agregar Usuario"),
        leading: const Icon(Icons.add, color: Colors.blue),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddUserPage()),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String role) {
    return FilterChip(
      label: Text(
        role,
        style: TextStyle(
          color: selectedRole == role ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
      selected: selectedRole == role,
      onSelected: (selected) {
        setState(() {
          selectedRole = role;
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
    );
  }

  Widget _buildUserCard(Map<String, dynamic> userData, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 4,
      child: ListTile(
        title: Text("${userData["firstName"]} ${userData["lastName"]}"),
        subtitle: Text("Email: ${userData['email']}"),
        trailing: Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.primary),
        onTap: () => _showUserInfoDialog(userData, context),
      ),
    );
  }

  // Mostrar el diálogo con la información del usuario
  void _showUserInfoDialog(Map<String, dynamic> userData, BuildContext context) {
    final TextEditingController firstNameController = TextEditingController(text: userData['firstName']);
    final TextEditingController lastNameController = TextEditingController(text: userData['lastName']);
    final TextEditingController emailController = TextEditingController(text: userData['email']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Información del Usuario"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: "Nombre"),
              ),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: "Apellido"),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _deleteUser(userData['uid']),
                child: const Text("Eliminar Cuenta"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                _updateUser(userData['uid'], firstNameController.text, lastNameController.text, emailController.text);
                Navigator.of(context).pop();
              },
              child: const Text("Guardar Cambios"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cerrar"),
            ),
          ],
        );
      },
    );
  }

  // Actualizar usuario y registrar acción en AdminActions
  Future<void> _updateUser(String uid, String firstName, String lastName, String email) async {
    try {
      await FirebaseFirestore.instance.collection('Users').doc(uid).update({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
      });

      // Registrar la acción en Firestore
      await FirebaseFirestore.instance.collection('AdminActions').add({
        'actionType': 'Actualización de Usuario',
        'targetId': uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error al actualizar usuario: $e");
    }
  }

  // Eliminar usuario
  Future<void> _deleteUser(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('Users').doc(uid).delete();
      await _authservice.deleteUser(uid);

      // Registrar el evento en Firestore
      await FirebaseFirestore.instance.collection('AdminActions').add({
        'actionType': 'Eliminación de Usuario',
        'targetId': uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pop();
    } catch (e) {
      print("Error al eliminar usuario: $e");
    }
  }
}
