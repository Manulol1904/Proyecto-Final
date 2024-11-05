import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tutorias_estudiantes/services/auth/auth_service.dart';

class UserDetailPage extends StatelessWidget {
  final String receiverEmail;
  final String receiverID;
  final String firstName;
  final String lastName;
  final String role;
  final String subjectArea;

  UserDetailPage({
    Key? key,
    required this.receiverEmail,
    required this.receiverID,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.subjectArea,
  }) : super(key: key);

  final Authservice _authservice = Authservice();

  Future<void> createSolicitud({
    required String currentUserEmail,
    required String currentUserID,
    required String receiverEmail,
    required String receiverID,
    required String studentName,
    required String studentEmail,
    required String studentCareer,
    required String studentId,
    required String necesidadEspecifica,
    required BuildContext context,
  }) async {
    CollectionReference solicitudes = FirebaseFirestore.instance.collection('solicitudes');

    try {
      await solicitudes.add({
        'fecha': Timestamp.now(),
        'solicitante': studentEmail,
        'solicitanteuid': currentUserID,
        'solicitanteNombre': studentName,
        'solicitanteCarrera': studentCareer,
        'solicitanteCodigo': studentId,
        'receptor': receiverEmail,
        'receptoruid': receiverID,
        'tutorName': '$firstName $lastName',
        'tutorUid': receiverID,
        'necesidadEspecifica': necesidadEspecifica, // Añadir necesidad específica
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Solicitud de tutoría creada con éxito!')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear la solicitud: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserEmail = _authservice.getCurrentUser()!.email!;
    final String currentUserID = _authservice.getCurrentUser()!.uid;

    Future<DocumentSnapshot> fetchStudentData() {
      return FirebaseFirestore.instance.collection('Users').doc(currentUserID).get();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Detalles del Tutor'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: fetchStudentData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Datos de estudiante no encontrados.'));
          }

          var studentData = snapshot.data!.data() as Map<String, dynamic>;
          String studentName = '${studentData['firstName']} ${studentData['lastName']}';
          String studentEmail = studentData['email'];
          String studentCareer = studentData['career'];
          String studentId = studentData['studentId'];

          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person,
                      size: 150,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      color: Theme.of(context).primaryColor,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nombre: $firstName $lastName',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Text('Email: $receiverEmail', style: const TextStyle(fontSize: 18)),
                            const SizedBox(height: 10),
                            Text('Rol: $role', style: const TextStyle(fontSize: 18)),
                            const SizedBox(height: 10),
                            Text('Especialidad: $subjectArea', style: const TextStyle(fontSize: 18)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        _showSolicitudDialog(
                          context: context,
                          currentUserEmail: currentUserEmail,
                          currentUserID: currentUserID,
                          receiverEmail: receiverEmail,
                          receiverID: receiverID,
                          studentName: studentName,
                          studentEmail: studentEmail,
                          studentCareer: studentCareer,
                          studentId: studentId,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Solicitar Tutoría',
                        style: TextStyle(fontSize: 18, color: Theme.of(context).textTheme.bodyMedium?.color),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSolicitudDialog({
    required BuildContext context,
    required String currentUserEmail,
    required String currentUserID,
    required String receiverEmail,
    required String receiverID,
    required String studentName,
    required String studentEmail,
    required String studentCareer,
    required String studentId,
  }) {
    final TextEditingController necesidadController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Especificar Necesidad'),
          content: TextField(
            controller: necesidadController,
            decoration: const InputDecoration(hintText: 'Describe tu necesidad específica...'),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                String necesidadEspecifica = necesidadController.text;
                if (necesidadEspecifica.isNotEmpty) {
                  createSolicitud(
                    currentUserEmail: currentUserEmail,
                    currentUserID: currentUserID,
                    receiverEmail: receiverEmail,
                    receiverID: receiverID,
                    studentName: studentName,
                    studentEmail: studentEmail,
                    studentCareer: studentCareer,
                    studentId: studentId,
                    necesidadEspecifica: necesidadEspecifica, // Añadir necesidad específica
                    context: context,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, ingresa una necesidad específica.')),
                  );
                }
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }
}
