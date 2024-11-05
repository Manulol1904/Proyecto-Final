import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutorias_estudiantes/pages/chatroom_page.dart';
import 'package:tutorias_estudiantes/pages/pdfreport_page.dart';

class AllTutoringSessionsPage extends StatefulWidget {
  const AllTutoringSessionsPage({Key? key}) : super(key: key);

  @override
  _AllTutoringSessionsPageState createState() => _AllTutoringSessionsPageState();
}

class _AllTutoringSessionsPageState extends State<AllTutoringSessionsPage> {
  bool _isLoadingChat = false; // Estado de carga para el chat

  // Método para eliminar la tutoría
  Future<void> _deleteTutoringSession(String sessionId) async {
    try {
      await FirebaseFirestore.instance.collection('TutoringSessions').doc(sessionId).delete();

      // Registrar el evento en Firestore
      await FirebaseFirestore.instance.collection('AdminActions').add({
        'actionType': 'Eliminación de Tutoría',
        'targetId': sessionId,
        'timestamp': FieldValue.serverTimestamp(),
      });

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Estudiante: ${session['studentName'] ?? 'Sin título'}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Tutor: ${session['tutorName'] ?? 'Desconocido'}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Fecha: ${session['scheduledDate'] ?? 'Sin fecha'}'),
              Text('Hora: ${session['scheduledTime'] ?? 'Sin hora'}'),
              const SizedBox(height: 10),
              if (session['rating'] != null) 
                Text('Valoración de la Tutoría: ${session['rating']}'),
              const SizedBox(height: 10),
              if (session['improvementRating'] != null)
                Text('Calificación de Mejoría: ${session['improvementRating']}'),
              const SizedBox(height: 10),
              if (session['feedback'] != null)
                Text(
                  'Comentario: ${session['feedback']}',
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Eliminar'),
              onPressed: () {
                _deleteTutoringSession(session.id);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Abrir Chat'),
              onPressed: () async {
                setState(() {
                  _isLoadingChat = true; // Activar estado de carga
                });

                String chatRoomId = session['chatRoomId'];
                
                // Navegar a ChatRoomPage y esperar a que se cargue
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatRoomPage(chatRoomID: chatRoomId),
                  ),
                );

                // Desactivar el estado de carga una vez que el chat se ha abierto
                setState(() {
                  _isLoadingChat = false;
                });

                Navigator.of(context).pop(); // Cerrar el diálogo después de regresar
              },
            ),
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop();
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
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              // Navegar a MonthlyReportPage cuando se presione el botón
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MonthlyReportPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack( // Usar Stack para superponer el indicador de carga
        children: [
          StreamBuilder<QuerySnapshot>(
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
          // Indicador de carga
          if (_isLoadingChat) 
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
