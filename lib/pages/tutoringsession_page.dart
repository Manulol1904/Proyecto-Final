import 'package:flutter/material.dart';
import 'package:tutorias_estudiantes/models/tutoring_session.dart';
import 'package:tutorias_estudiantes/pages/tutoringsessiondetail_page.dart';
import 'package:tutorias_estudiantes/services/chat/chat_service.dart';

class TutoringSessionsPage extends StatelessWidget {
  final String? studentUid;
  final String? tutorUid;
  final String userRole;

  const TutoringSessionsPage({
    super.key,
    this.studentUid,
    this.tutorUid,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final TutoringService tutoringService = TutoringService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tutorías'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
      ),
      body: StreamBuilder<List<TutoringSession>>(
        stream: tutoringService.getTutoringSessions(studentUid, tutorUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final sessions = snapshot.data;

          if (sessions == null || sessions.isEmpty) {
            return const Center(child: Text('No tienes tutorías asignadas.'));
          }

          // Ordenar las sesiones por timestamp (suponiendo que 'timestamp' es un campo de tipo DateTime)
          sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    session.studentName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fecha: ${session.scheduledDate} a las ${session.scheduledTime}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Tutor: ${session.tutorName}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: Theme.of(context).primaryColor,
                  ),
                  onTap: userRole == 'Estudiante'
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TutoringSessionDetailPage(session: session),
                            ),
                          );
                        }
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
