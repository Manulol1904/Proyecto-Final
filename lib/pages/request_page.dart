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

          return ListView.builder(
            itemCount: requests.length,
            padding: const EdgeInsets.all(12.0),
            itemBuilder: (context, index) {
              var request = requests[index].data() as Map<String, dynamic>;
              var studentName = "${request['solicitanteNombre']}";
              var studentEmail = request['solicitante'];
              var studentCareer = request['solicitanteCarrera'];
              var date = (request['fecha'] as Timestamp).toDate();
              var formattedDate = "${date.day}/${date.month}/${date.year}";
              var requestId = requests[index].id;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 10.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  title: Text(
                    studentName,
                    style:  TextStyle(
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
                          "Correo: $studentEmail",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Carrera: $studentCareer",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Fecha: $formattedDate",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
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
