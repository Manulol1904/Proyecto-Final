import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleTutoringPage extends StatefulWidget {
  final String solicitante;
  final String solicitanteUid;
  final String receptor;
  final String receptorUid;

  const ScheduleTutoringPage({
    required this.solicitante,
    required this.solicitanteUid,
    required this.receptor,
    required this.receptorUid,
  });

  @override
  _ScheduleTutoringPageState createState() => _ScheduleTutoringPageState();
}

class _ScheduleTutoringPageState extends State<ScheduleTutoringPage> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  bool _isLoading = true;
  String _studentName = '';
  String _studentCareer = '';
  String _tutorName = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      DocumentSnapshot studentDoc = await FirebaseFirestore.instance.collection('Users').doc(widget.solicitanteUid).get();
      DocumentSnapshot tutorDoc = await FirebaseFirestore.instance.collection('Users').doc(widget.receptorUid).get();

      if (studentDoc.exists && tutorDoc.exists) {
        Map<String, dynamic> studentData = studentDoc.data() as Map<String, dynamic>;
        Map<String, dynamic> tutorData = tutorDoc.data() as Map<String, dynamic>;

        setState(() {
          _studentName = "${studentData['firstName']} ${studentData['lastName']}";
          _studentCareer = studentData['career'] ?? 'Carrera no disponible';
          _tutorName = "${tutorData['firstName']} ${tutorData['lastName']}";
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar la información: $e')),
      );
    }
  }

  Future<void> _scheduleTutoringSession() async {
  try {
    // Asegúrate de que el usuario esté autenticado
    User?  user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debes estar autenticado para agendar una tutoría.')),
      );
      return;
    }

    DocumentReference newSessionRef = FirebaseFirestore.instance.collection('TutoringSessions').doc();

    await newSessionRef.set({
      'tutoringId': newSessionRef.id,
      'studentName': _studentName,
      'studentUid': widget.solicitanteUid,
      'studentCareer': _studentCareer,
      'tutorName': _tutorName,
      'tutorUid': widget.receptorUid,
      'scheduledDate': _dateController.text,
      'scheduledTime': _timeController.text,
      'timestamp': Timestamp.now(),
    });

    await FirebaseFirestore.instance.collection('notifications').add({
      'receiverID': widget.solicitanteUid, // ID del estudiante que recibirá la notificación
      'type': 'tutoring', // Tipo de notificación
      'isRead': false, // No leída al crearse
      'timestamp': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tutoría agendada correctamente')),
    );

    Navigator.pop(context);
  } catch (e, stackTrace) {
    print("Error: $e"); // Imprimir el error
    print("StackTrace: $stackTrace"); // Imprimir la traza de pila
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al agendar la tutoría: ${e.toString()}')),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar Tutoría'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center( // Centrar la tarjeta
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 16.0), // Margen lateral
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoText('Estudiante:', _studentName),
                            _buildInfoText('Carrera:', _studentCareer),
                            const SizedBox(height: 20),
                            _buildInfoText('Tutor:', _tutorName),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDateTimeInput('Fecha de Tutoría', _dateController, true),
                  const SizedBox(height: 20),
                  _buildDateTimeInput('Hora de Tutoría', _timeController, false),
                  const SizedBox(height: 30),
                  Center( // Centrando el botón
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                        backgroundColor: Theme.of(context).primaryColor, // Color de fondo del botón
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                        elevation: 0, // Sin sombra para un look más limpio
                      ),
                      onPressed: _scheduleTutoringSession,
                      child: const Text(
                        'Agendar Tutoría',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoText(String title, String info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          info,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildDateTimeInput(String label, TextEditingController controller, bool isDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        TextField(
          controller: controller,
          readOnly: true, // Hacer el campo solo lectura para evitar edición directa
          decoration: InputDecoration(
            hintText: isDate ? 'Seleccione la fecha' : 'Seleccione la hora',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Theme.of(context).primaryColor), // Borde del campo
            ),
            suffixIcon: Icon(isDate ? Icons.calendar_today : Icons.access_time, color: Theme.of(context).primaryColor),
          ),
          onTap: () async {
            if (isDate) {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
              );
              if (pickedDate != null) {
                setState(() {
                  controller.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                });
              }
            } else {
              TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (pickedTime != null) {
                setState(() {
                  controller.text = pickedTime.format(context);
                });
              }
            }
          },
        ),
      ],
    );
  }
}
