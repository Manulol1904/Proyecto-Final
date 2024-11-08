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
  String _tutorSubjectArea = ''; // Nueva variable para el área de especialización del tutor

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
          _tutorSubjectArea = tutorData['subjectArea'] ?? 'Área no disponible'; // Obtener el área de especialización
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
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes estar autenticado para agendar una tutoría.')),
        );
        return;
      }

       // Generar o obtener el ID de la sala de chat entre estudiante y tutor
      String chatRoomId = '${widget.solicitanteUid}_${widget.receptorUid}';

      DocumentReference newSessionRef = FirebaseFirestore.instance.collection('TutoringSessions').doc();

      await newSessionRef.set({
        'isRated': false,
        'rating': 0,
        'improvementRating' : 0,
        'feedback' : "",
        'tutoringId': newSessionRef.id,
        'studentName': _studentName,
        'studentUid': widget.solicitanteUid,
        'studentCareer': _studentCareer,
        'tutorName': _tutorName,
        'tutorUid': widget.receptorUid,
        'type': _tutorSubjectArea, // Añadir el área de especialización
        'scheduledDate': _dateController.text,
        'scheduledTime': _timeController.text,
        'timestamp': Timestamp.now(),
        'chatRoomId': chatRoomId, // Añadir el ID de la sala de chat
      });

      await FirebaseFirestore.instance.collection('notifications').add({
        'receiverID': widget.solicitanteUid,
        'type': 'tutoring',
        'isRead': false,
        'timestamp': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tutoría agendada correctamente')),
      );

      Navigator.pop(context);
    } catch (e, stackTrace) {
      print("Error: $e");
      print("StackTrace: $stackTrace");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agendar la tutoría: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Agendar Tutoría',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileCards(),
                      const SizedBox(height: 32),
                      _buildDateTimeSection(),
                      const SizedBox(height: 40),
                      _buildScheduleButton(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfileCards() {
    return Column(
      children: [
        // Tarjeta del Estudiante
        _buildProfileCard(
          title: 'Estudiante',
          name: _studentName,
          role: _studentCareer,
          icon: Icons.school,
          backgroundColor: const Color(0xFFF5CD84).withOpacity(0.6),
        ),
        const SizedBox(height: 16),
        // Tarjeta del Tutor
        _buildProfileCard(
          title: 'Tutor',
          name: _tutorName,
          role: _tutorSubjectArea,
          icon: Icons.psychology,
          backgroundColor: const Color(0xFFF5CD84).withOpacity(0.6),
        ),
      ],
    );
  }

  Widget _buildProfileCard({
    required String title,
    required String name,
    required String role,
    required IconData icon,
    required Color backgroundColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF11254B).withOpacity(0.9),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: TextStyle(
                    color:Theme.of(context).colorScheme.inversePrimary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalles de la Sesión',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        const SizedBox(height: 24),
        _buildDateTimeInput(
          'Fecha de Tutoría',
          _dateController,
          true,
          Icons.calendar_today,
        ),
        const SizedBox(height: 16),
        _buildDateTimeInput(
          'Hora de Tutoría',
          _timeController,
          false,
          Icons.access_time,
        ),
      ],
    );
  }

  Widget _buildDateTimeInput(
    String label,
    TextEditingController controller,
    bool isDate,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            readOnly: true,
            decoration: InputDecoration(
              hintText: isDate ? 'Seleccione la fecha' : 'Seleccione la hora',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
              filled: true,
              fillColor: const Color(0xFFF5CD84).withOpacity(0.6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(
                icon,
                color: const Color(0xFF11254B).withOpacity(0.9),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
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
                    controller.text =
                        "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
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
        ),
      ],
    );
  }

  Widget _buildScheduleButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: _scheduleTutoringSession,
        child: const Text(
          'Agendar Tutoría',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}