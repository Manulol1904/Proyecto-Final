import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tutorias_estudiantes/pages/home_page.dart';

class AccountPage extends StatefulWidget {
  final String userRole;

  const AccountPage({super.key, required this.userRole});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();

  String? _selectedCareer; // Para el estudiante
  String? _selectedSubject; // Para el tutor

  bool _isLoading = true;

  // Lista de carreras para los estudiantes
  final List<String> _careers = [
    'Ingeniería de Sistemas',
    'Medicina',
    'Derecho',
    'Administración de Empresas',
    // Agrega más carreras según sea necesario
  ];

  // Lista de áreas de ciencias básicas para los tutores
  final List<String> _subjects = [
    'Matemáticas',
    'Física',
    'Inglés',
    'Química',
    // Agrega más áreas según sea necesario
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      String uid = user.uid;

      // Obtener los datos del usuario desde Firestore
      DocumentSnapshot userDoc = await _firestore.collection('Users').doc(uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        setState(() {
          _firstNameController.text = userData['firstName'] ?? '';
          _lastNameController.text = userData['lastName'] ?? '';
          
          if (widget.userRole == 'Tutor') {
            _selectedSubject = userData['subjectArea'];
          } else if (widget.userRole == 'Estudiante') {
            _studentIdController.text = userData['studentId'] ?? '';
            _selectedCareer = userData['career'];
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar la información: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserInfo() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      String uid = user.uid;

      Map<String, dynamic> updatedData = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'isProfileUpdated': true
      };

      if (widget.userRole == 'Tutor') {
        updatedData['subjectArea'] = _selectedSubject;
      } else if (widget.userRole == 'Estudiante') {
        updatedData['studentId'] = _studentIdController.text;
        updatedData['career'] = _selectedCareer;
      }

      await _firestore.collection('Users').doc(uid).update(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Información actualizada correctamente')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()), // Reemplazar con el HomePage actualizado
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar la información: $e')),
      );
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actualizar Información'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nombres', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      hintText: 'Ingrese su nombre',
                      filled: true,
                      fillColor: Theme.of(context).primaryColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Apellidos', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      hintText: 'Ingrese su apellido',
                      filled: true,
                      fillColor: Theme.of(context).primaryColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Campos específicos para estudiantes
                  if (widget.userRole == 'Estudiante') ...[
                    const Text('Código de Estudiante', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextField(
                      controller: _studentIdController,
                      decoration: InputDecoration(
                        hintText: 'Ingrese su código de estudiante',
                        filled: true,
                        fillColor: Theme.of(context).primaryColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Carrera', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField<String>(
                      value: _selectedCareer,
                      items: _careers.map((career) {
                        return DropdownMenuItem<String>(
                          value: career,
                          child: Text(career),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCareer = value; // Este valor debe ser uno de los elementos de la lista
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Seleccione su carrera',
                        filled: true,
                        fillColor: Theme.of(context).primaryColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],

                  // Campos específicos para tutores
                  if (widget.userRole == 'Tutor') ...[
                    const Text('Área de Ciencias Básicas', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField<String>(
                      value: _selectedSubject,
                      items: _subjects.map((subject) {
                        return DropdownMenuItem<String>(
                          value: subject,
                          child: Text(subject),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSubject = value; // Este valor debe ser uno de los elementos de la lista
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Seleccione el área de tutorías',
                        filled: true,
                        fillColor: Theme.of(context).primaryColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: _updateUserInfo,
                      child: const Text('Guardar', style: TextStyle(fontSize: 20, color: Colors.white),),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.grey,
                      ),
                    ),
                  ),  
                ],
              ),
            ),
    );
  }
}
