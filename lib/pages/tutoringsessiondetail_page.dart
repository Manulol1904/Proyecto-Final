import 'package:flutter/material.dart';
import 'package:tutorias_estudiantes/models/tutoring_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TutoringSessionDetailPage extends StatefulWidget {
  final TutoringSession session;

  const TutoringSessionDetailPage({super.key, required this.session});

  @override
  _TutoringSessionDetailPageState createState() => _TutoringSessionDetailPageState();
}

class _TutoringSessionDetailPageState extends State<TutoringSessionDetailPage> {
  double? _rating;

  Future<void> _submitRating() async {
    if (_rating != null) {
      try {
        await FirebaseFirestore.instance
            .collection('TutoringSessions')
            .doc(widget.session.tutoringId)
            .update({
          'rating': _rating,
          'isRated': true, // Update isRated to true after submitting rating
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Calificación enviada: $_rating')),
        );
        Navigator.pop(context); // Go back after rating
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar la calificación: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize _rating with the current session rating
    _rating = widget.session.rating;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de la Tutoría'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estudiante Name
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  'Estudiante: ${widget.session.studentName}',
                  style: Theme.of(context).textTheme.headline6?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                ),
              ),
              // Fecha (independiente)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  'Fecha: ${widget.session.scheduledDate}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 18,
                  ),
                ),
              ),
              // Hora (independiente)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  'Hora: ${widget.session.scheduledTime}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 18,
                  ),
                ),
              ),
              // Tutor Name
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  'Tutor: ${widget.session.tutorName}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Calificación label
              const Text(
                'Calificación:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              // Check if the session is already rated
              if (widget.session.isRated) ...[
                // Show the existing rating
                Text(
                  'Calificación actual: ${widget.session.rating}',
                  style: const TextStyle(fontSize: 18, color: Colors.green),
                ),
              ] else ...[
                // Slider
                Slider(
                  value: _rating ?? 1,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: Theme.of(context).primaryColor,
                  label: _rating?.toString(),
                  onChanged: (value) {
                    setState(() {
                      _rating = value;
                    });
                  },
                ),
              ],
              const SizedBox(height: 30),
              // Calificar button
              if (!widget.session.isRated) ...[
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _submitRating,
                    icon: Icon(Icons.rate_review, color: Theme.of(context).colorScheme.inversePrimary),
                    label: const Text(
                      'Calificar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 50), // Spacer at the bottom for larger screens
            ],
          ),
        ),
      ),
    );
  }
}
