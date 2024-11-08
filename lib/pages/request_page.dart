import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutorias_estudiantes/pages/requestdetail_page.dart';
import 'package:tutorias_estudiantes/services/auth/auth_service.dart';

class RequestsPage extends StatelessWidget {
  final Authservice _authService = Authservice();
  final bool showAppBar;

  RequestsPage({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text("Solicitudes"),
              backgroundColor: Theme.of(context).primaryColor,
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: _authService.getRequestsForCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay solicitudes."));
          }

          final requests = snapshot.data!.docs;

          // Ordenar las solicitudes por fecha (timestamp)
          final sortedRequests = List.from(requests);
          sortedRequests.sort((a, b) {
            var dateA = (a['fecha'] as Timestamp).toDate();
            var dateB = (b['fecha'] as Timestamp).toDate();
            return dateB.compareTo(dateA); // Orden descendente (más reciente primero)
          });

          return ListView.builder(
            itemCount: sortedRequests.length,
            padding: const EdgeInsets.all(12.0),
            itemBuilder: (context, index) {
              var request = sortedRequests[index].data() as Map<String, dynamic>;
              var studentName = "${request['solicitanteNombre']}";
              var studentEmail = request['solicitante'];
              var studentCareer = request['solicitanteCarrera'];
              var date = (request['fecha'] as Timestamp).toDate();
              var necesidad = request['necesidadEspecifica'];
              var formattedDate = "${date.day}/${date.month}/${date.year}";
              var requestId = sortedRequests[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10.0),
                color: const Color(0xFFF5CD84).withOpacity(0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  title: Text(
                    studentName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.email, color: const Color(0xFF11254B).withOpacity(0.9), size: 16),
                            const SizedBox(width: 8),
                            Text(
                              studentEmail,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.inversePrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(Icons.school, color: const Color(0xFF11254B).withOpacity(0.9), size: 16),
                            const SizedBox(width: 8),
                            Text(
                              studentCareer,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.inversePrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: const Color(0xFF11254B).withOpacity(0.9), size: 16),
                            const SizedBox(width: 8),
                            Text(
                              "Fecha: $formattedDate",
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.inversePrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RequestDetailPage(
                          solicitante: studentName,
                          solicitanteUid: request['solicitanteuid'],
                          receptor: request['receptor'],
                          receptorUid: request['receptoruid'],
                          date: date,
                          requestId: requestId,
                          necesidad: necesidad
                        ),
                      ),
                    );
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
