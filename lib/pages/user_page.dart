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
        'necesidadEspecifica': necesidadEspecifica,
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

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: const Color(0xFFF5CD84).withOpacity(0.6),
                      child: Text(
                        '${firstName[0]}${lastName[0]}',
                        style: TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).scaffoldBackgroundColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildInfoCard(
                    icon: Icons.person,
                    content: 'Nombre: $firstName $lastName',
                  ),
                  const SizedBox(height: 20),
                  _buildInfoCard(
                    icon: Icons.email,
                    content: 'Email: $receiverEmail',
                  ),
                  const SizedBox(height: 20),
                  _buildInfoCard(
                    icon: Icons.account_circle,
                    content: 'Rol: $role',
                  ),
                  const SizedBox(height: 20),
                  _buildInfoCard(
                    icon: Icons.school,
                    content: 'Especialidad: $subjectArea',
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: ElevatedButton(
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
                        backgroundColor: const Color(0xFFF5CD84).withOpacity(0.7),
                        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Solicitar Tutoría',
                        style: TextStyle(fontSize: 22, color: Theme.of(context).colorScheme.inversePrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String content}) {
    return Card(
      color: const Color(0xFFF5CD84).withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF11254B).withOpacity(0.9),
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                content,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
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
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 16,
          backgroundColor: Theme.of(context).colorScheme.background,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Especificar Necesidad',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: necesidadController,
                  decoration: const InputDecoration(
                    hintText: 'Describe tu necesidad específica...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(16),
                  ),
                  maxLines: 3,
                  maxLength: 200,
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (necesidadController.text.isNotEmpty) {
                      createSolicitud(
                        currentUserEmail: currentUserEmail,
                        currentUserID: currentUserID,
                        receiverEmail: receiverEmail,
                        receiverID: receiverID,
                        studentName: studentName,
                        studentEmail: studentEmail,
                        studentCareer: studentCareer,
                        studentId: studentId,
                        necesidadEspecifica: necesidadController.text,
                        context: context,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5CD84).withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Enviar',
                    style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.inversePrimary),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
