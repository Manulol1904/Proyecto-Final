// ignore_for_file: file_names, use_super_parameters, avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AllTutoringSessionsPage extends StatelessWidget {
  const AllTutoringSessionsPage({Key? key}) : super(key: key);

  // Método para eliminar la tutoría
  Future<void> _deleteTutoringSession(String sessionId) async {
    try {
      await FirebaseFirestore.instance.collection('TutoringSessions').doc(sessionId).delete();
      print('Tutoría eliminada');
    } catch (e) {
      print('Error al eliminar la tutoría: $e');
    }
  }

  // Método para mostrar el diálogo de detalles de la tutoría
  void _showTutoringSessionDetails(BuildContext context, DocumentSnapshot session) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Detalles de la Tutoría'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Estudiante: ${session['studentName'] ?? 'Sin título'}', style: const TextStyle(fontWeight: FontWeight.bold)), // Nombre del estudiante 
              Text('Tutor: ${session['tutorName'] ?? 'Desconocido'}', style: const TextStyle(fontWeight: FontWeight.bold)), // Nombre del tutor
              Text('Fecha: ${session['scheduledDate'] ?? 'Sin fecha'}'),
              Text('Hora: ${session['scheduledTime'] ?? 'Sin hora'}'),
              Text('Valoracion: ${session['rating'] ?? 'Sin valoracion'}'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Eliminar'),
              onPressed: () {
                _deleteTutoringSession(session.id); // Llamar al método de eliminación
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
            ),
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
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
      appBar: AppBar(
        title: const Text('Todas las Tutorías'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('TutoringSessions').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar las tutorías'));
          }

          final sessions = snapshot.data!.docs;

          if (sessions.isEmpty) {
            return const Center(child: Text('No hay tutorías disponibles.'));
          }

          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  title: Text(
                    'Estudiante: ${session['studentName'] ?? 'Sin título'}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tutor: ${session['tutorName'] ?? 'Desconocido'}'),
                      Text('Fecha: ${session['scheduledDate'] ?? 'Sin fecha'}'),
                      Text('Hora: ${session['scheduledTime'] ?? 'Sin hora'}'),
                    ],
                  ),
                  onTap: () {
                    _showTutoringSessionDetails(context, session); // Mostrar detalles al hacer tap
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
