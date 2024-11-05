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
  double? _improvementRating;
  String _feedbackText = "";

  Future<void> _submitRating() async {
    // Check if the ratings are valid
    if (_rating != null && _rating! > 0 && _improvementRating != null && _improvementRating! > 0) {
      try {
        await FirebaseFirestore.instance
            .collection('TutoringSessions')
            .doc(widget.session.tutoringId)
            .update({
          'rating': _rating,
          'improvementRating': _improvementRating,
          'feedback': _feedbackText,
          'isRated': true, // Update isRated to true after submitting rating
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Calificación enviada: $_rating, Mejora: $_improvementRating')),
        );
        Navigator.pop(context); // Go back after rating
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar la calificación: $e')),
        );
      }
    } else {
      // Show a Snackbar if any rating is zero
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se puede enviar una calificación o mejora de cero.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _rating = widget.session.rating;
    _improvementRating = 1; // Initial value for improvement rating
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
              // Fecha y Hora
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  'Fecha: ${widget.session.scheduledDate}\nHora: ${widget.session.scheduledTime}',
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
              // Calificación de la sesión
              const Text(
                'Calificación de la sesión:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (widget.session.isRated) ...[
                Text(
                  'Calificación actual: ${widget.session.rating}',
                  style: const TextStyle(fontSize: 18, color: Colors.green),
                ),
              ] else ...[
                Slider(
                  value: _rating ?? 1,
                  min: 0,
                  max: 5,
                  divisions: 5,
                  activeColor: Theme.of(context).primaryColor,
                  label: _rating?.toString(),
                  onChanged: (value) {
                    setState(() {
                      _rating = value;
                    });
                  },
                ),
              ],
              const SizedBox(height: 20),
              // Calificación de la mejora de la duda
              const Text(
                'Mejora de la duda:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Slider(
                value: _improvementRating ?? 1,
                min: 0,
                max: 5,
                divisions: 5,
                activeColor: Theme.of(context).primaryColor,
                label: _improvementRating?.toString(),
                onChanged: (value) {
                  setState(() {
                    _improvementRating = value;
                  });
                },
              ),
              const SizedBox(height: 30),
              // Cuadro de texto de retroalimentación
              const Text(
                'Comentarios adicionales:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                maxLength: 200,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Escribe tus comentarios (máximo 200 caracteres)',
                  counterText: '', // Hide the default counter text
                ),
                onChanged: (value) {
                  setState(() {
                    _feedbackText = value;
                  });
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_feedbackText.length}/200',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Botón de Calificar
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
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
