import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      appBar: userRole == "Admin" ? AppBar(
              title: const Text('Todos los Usuarios'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            )
          : null,
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

          // Order sessions by timestamp (most recent first)
          sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];

              // Format the date and time
              final formattedDate = DateFormat.yMMMd().format(session.timestamp.toDate());
              final formattedTime = DateFormat.Hm().format(session.timestamp.toDate());

              return Card(
                color: const Color(0xFFF5CD84).withOpacity(0.6),
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name with icon
                      Row(
                        children: [
                           Icon(Icons.person, color: const Color(0xFF11254B).withOpacity(0.9)),
                          const SizedBox(width: 8),
                          Text(
                            session.studentName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Date with icon
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color:  const Color(0xFF11254B).withOpacity(0.9)),
                          const SizedBox(width: 8),
                          Text(
                            'Fecha: $formattedDate a las $formattedTime',
                            style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Tutor with icon
                      Row(
                        children: [
                          Icon(Icons.school, color:  const Color(0xFF11254B).withOpacity(0.9)),
                          const SizedBox(width: 8),
                          Text(
                            'Tutor: ${session.tutorName}',
                            style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: (userRole == 'Estudiante' || userRole == 'Tutor')
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          TutoringSessionDetailPage(session: session, userRole: userRole,),
                                    ),
                                  );
                                }
                              : null,
                          label: const Text("Detalles", style: TextStyle(color: Colors.white)),
                          icon: const Icon(Icons.arrow_forward_ios, size: 18),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            backgroundColor:const Color(0xFF11254B).withOpacity(0.9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
