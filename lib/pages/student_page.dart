import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutorias_estudiantes/pages/user_page.dart';
import 'package:tutorias_estudiantes/services/auth/auth_service.dart';

class StudentPage extends StatefulWidget {
  final bool showAppBar; // Parámetro para controlar la visibilidad del AppBar

  const StudentPage({Key? key, this.showAppBar = true}) : super(key: key);
  
  @override
  _StudentPageState createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  final Authservice _authservice = Authservice();
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String selectedSpecialty = 'All';

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: widget.showAppBar // Mostrar o no el AppBar basado en el parámetro
          ? AppBar(
              title: const Text('Todos los Usuarios'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            )
          : null,
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
  return Column(
    children: [
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
          onChanged: (value) {
            setState(() {
              searchQuery = value.toLowerCase();
            });
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildFilterChip('All'),
            _buildFilterChip('Matemáticas'),
            _buildFilterChip('Inglés'),
            _buildFilterChip('Física'),
          ],
        ),
      ),
      Expanded(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('Users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text("Error");
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text("No hay tutores disponibles.");
            }

            final tutorUsers = snapshot.data!.docs.where((doc) {
              // Check if the user is a tutor and has the firstName field
              if (doc['rol'] != 'Tutor' || !doc.data().containsKey('firstName') || doc['firstName'].toString().trim().isEmpty) {
              return false;
                 }

              // Check if the user's name matches the search query
              final matchesSearchQuery = 
                  doc['firstName'].toString().toLowerCase().contains(searchQuery) ||
                  doc['lastName'].toString().toLowerCase().contains(searchQuery);

              // Check if the user's subject area matches the selected specialty
              final matchesSpecialty = selectedSpecialty == 'All' ||
                  doc['subjectArea'].toString() == selectedSpecialty;

              // Return true if both conditions are met
              return matchesSearchQuery && matchesSpecialty;
            }).toList();

            return ListView(
              children: tutorUsers.map<Widget>((doc) => _buildUserListItem(doc.data(), context)).toList(),
            );
          },
        ),
      ),
    ],
  );
}


  Widget _buildFilterChip(String specialty) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(
          specialty,
          style: TextStyle(
            color: selectedSpecialty == specialty 
              ? Colors.white 
              : Theme.of(context).textTheme.bodyMedium?.color,
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
  

  Widget _buildUserListItem(Map<String, dynamic> userData, BuildContext context) {
    if (userData["email"] != _authservice.getCurrentUser()!.email) {
      return Column(
        children: [
          ListTile(
            title: Text("${userData["firstName"]} ${userData["lastName"]}"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Email: ${userData['email']}"),
                Text("Especialidad: ${userData['subjectArea']}"),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserDetailPage(
                    receiverEmail: userData["email"].toString(),
                    receiverID: userData["uid"].toString(),
                    firstName: userData["firstName"].toString(),
                    lastName: userData["lastName"].toString(),
                    role: userData["rol"].toString(),
                    subjectArea: userData["subjectArea"].toString(),
                  ),
                ),
              );
            },
          ),
          _buildSeparator(),
        ],
      );
    } else {
      return Container();
    }
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
}
