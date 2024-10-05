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
      // Obtener los datos del estudiante y tutor desde Firestore
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
      // Create a reference to the new document
      DocumentReference newSessionRef = FirebaseFirestore.instance.collection('TutoringSessions').doc();

      // Crear la tutoría en Firestore con los datos de la sesión, incluyendo tutoringId
      await newSessionRef.set({
        'tutoringId': newSessionRef.id, // Generate a unique ID for the tutoring session
        'studentName': _studentName,
        'studentUid': widget.solicitanteUid,
        'studentCareer': _studentCareer,
        'tutorName': _tutorName,
        'tutorUid': widget.receptorUid,
        'scheduledDate': _dateController.text,
        'scheduledTime': _timeController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tutoría agendada correctamente')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agendar la tutoría: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar Tutoría'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estudiante: $_studentName'),
                  Text('Carrera: $_studentCareer'),
                  const SizedBox(height: 20),
                  Text('Tutor: $_tutorName'),
                  const SizedBox(height: 20),
                  const Text('Fecha de Tutoría'),
                  TextField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      hintText: 'Seleccione la fecha',
                    ),
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _dateController.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Hora de Tutoría'),
                  TextField(
                    controller: _timeController,
                    decoration: const InputDecoration(
                      hintText: 'Seleccione la hora',
                    ),
                    onTap: () async {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          _timeController.text = pickedTime.format(context);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _scheduleTutoringSession,
                    child: const Text('Agendar Tutoría'),
                  ),
                ],
              ),
            ),
    );
  }
}
