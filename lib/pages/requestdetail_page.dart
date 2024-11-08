import 'package:flutter/material.dart';
import 'package:tutorias_estudiantes/pages/chat_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutorias_estudiantes/pages/schedule_page.dart';

class RequestDetailPage extends StatelessWidget {
  final String? solicitante;
  final String? solicitanteUid;
  final String? receptor;
  final String? receptorUid;
  final DateTime? date;
  final String requestId;
  final String necesidad;

  const RequestDetailPage({
    required this.solicitante,
    required this.solicitanteUid,
    required this.receptor,
    required this.receptorUid,
    required this.date,
    required this.requestId,
    required this.necesidad,
  });

  @override
  Widget build(BuildContext context) {
    var formattedDate = date != null ? "${date!.day}/${date!.month}/${date!.year}" : "Fecha no disponible";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalles de la Solicitud"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
      ),
      body: SingleChildScrollView( // Agregado para permitir el desplazamiento
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('Users').doc(solicitanteUid).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error al cargar los datos del estudiante: ${snapshot.error}"));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("Datos del estudiante no encontrados."));
            }

            var studentData = snapshot.data!.data() as Map<String, dynamic>;
            String studentName = "${studentData['firstName']} ${studentData['lastName']}";
            String studentEmail = studentData['email'];
            String studentCareer = studentData['career'];
            String studentId = studentData['studentId'];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(
                  icon: Icons.person,
                  label: "Nombre:",
                  value: studentName,
                ),
                _buildInfoCard(
                  icon: Icons.email,
                  label: "Correo:",
                  value: studentEmail,
                ),
                _buildInfoCard(
                  icon: Icons.school,
                  label: "Carrera:",
                  value: studentCareer,
                ),
                _buildInfoCard(
                  icon: Icons.badge,
                  label: "ID de estudiante:",
                  value: studentId,
                ),
                _buildInfoCard(
                  icon: Icons.question_answer,
                  label: "Duda:",
                  value: necesidad,
                ),
                _buildInfoCard(
                  icon: Icons.person_outline,
                  label: "Receptor:",
                  value: receptor ?? 'No disponible',
                ),
                _buildInfoCard(
                  icon: Icons.calendar_today,
                  label: "Fecha:",
                  value: formattedDate,
                ),
                const SizedBox(height: 20),
                _buildButton(
                  context,
                  label: "Redirigir a Chat",
                  color: Colors.grey.shade700,
                  onPressed: () {
                    if (solicitante != null && solicitanteUid != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            receiverEmail: studentEmail,
                            receiverID: solicitanteUid!,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No se puede redirigir al chat, datos incompletos")),
                      );
                    }
                  },
                ),
                _buildButton(
                  context,
                  label: "Agendar Tutoría",
                  color: Colors.grey.shade700,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScheduleTutoringPage(
                          solicitante: studentName,
                          solicitanteUid: solicitanteUid!,
                          receptor: receptor!,
                          receptorUid: receptorUid!,
                        ),
                      ),
                    );
                  },
                ),
                _buildButton(
                  context,
                  label: "Eliminar Solicitud",
                  color: Colors.red, // Color rojo para el botón de eliminar
                  onPressed: () async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('solicitudes')
                          .doc(requestId)
                          .delete();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Solicitud eliminada exitosamente")),
                      );
                    } catch (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error al eliminar la solicitud: $error")),
                      );
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String label, required String value}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: const Color(0xFFF5CD84).withOpacity(0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color:const Color(0xFF11254B).withOpacity(0.9)),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildButton(BuildContext context, {required String label, required VoidCallback onPressed, Color color = Colors.blue}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
