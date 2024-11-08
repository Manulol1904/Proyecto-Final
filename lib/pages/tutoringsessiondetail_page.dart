import 'package:flutter/material.dart';
import 'package:tutorias_estudiantes/models/tutoring_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TutoringSessionDetailPage extends StatefulWidget {
  final TutoringSession session;
  final String userRole; // 'Estudiante' or 'Tutor'

  const TutoringSessionDetailPage({super.key, required this.session, required this.userRole});

  @override
  _TutoringSessionDetailPageState createState() => _TutoringSessionDetailPageState();
}

class _TutoringSessionDetailPageState extends State<TutoringSessionDetailPage> {
  double? _rating;
  double? _improvementRating;
  String _feedbackText = "";

  // Cambié esta propiedad para que considere el rol y el estado de calificación
  bool get isRatingEnabled {
    // Solo los estudiantes pueden calificar y si la tutoría no ha sido calificada aún
    return widget.userRole == 'Estudiante' && !widget.session.isRated;
  }

  // Método para actualizar Firestore con la calificación
  Future<void> _submitRating() async {
    if (_rating != null && _rating! > 0 && _improvementRating != null && _improvementRating! > 0) {
      try {
        await FirebaseFirestore.instance.collection('TutoringSessions').doc(widget.session.tutoringId).update({
          'rating': _rating,
          'improvementRating': _improvementRating,
          'feedback': _feedbackText,
          'isRated': true,  // Cambiar el estado de isRated a true
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Calificación enviada con éxito.')),
        );
        Navigator.pop(context); // Regresar a la página anterior
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar la calificación: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, califique correctamente.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Inicializar los valores de la calificación y los comentarios
    _rating = widget.session.rating;
    _improvementRating = widget.session.improvementRating;
    _feedbackText = widget.session.feedback;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de la Tutoría'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información de Estudiante
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 4,
              color: const Color(0xFFF5CD84).withOpacity(0.6),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Icon(Icons.person, color: const Color(0xFF11254B).withOpacity(0.9)),
                title: Text('Estudiante: ${widget.session.studentName}', style: const TextStyle(fontSize: 18)),
              ),
            ),
            // Información de Tutor
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 4,
              color: const Color(0xFFF5CD84).withOpacity(0.6),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Icon(Icons.person, color: const Color(0xFF11254B).withOpacity(0.9)),
                title: Text('Tutor: ${widget.session.tutorName}', style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 16),
            // Fecha y Hora de la Tutoría
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 4,
              color: const Color(0xFFF5CD84).withOpacity(0.6),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Icon(Icons.date_range, color: const Color(0xFF11254B).withOpacity(0.9)),
                title: Text('Fecha: ${widget.session.scheduledDate}', style: const TextStyle(fontSize: 18)),
                subtitle: Text('Hora: ${widget.session.scheduledTime}', style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            // Calificación de la sesión
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 4,
              color: const Color(0xFFF5CD84).withOpacity(0.6),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Icon(Icons.star, color: const Color(0xFF11254B).withOpacity(0.9)),
                title: const Text('Calificación de la sesión:'),
                subtitle: widget.session.isRated
                    ? Text(
                        'Calificación actual: ${widget.session.rating}',
                        style: TextStyle(fontSize: 18, color:const Color(0xFF11254B).withOpacity(0.9)),
                      )
                    : (isRatingEnabled
                        ? Slider(
                            value: _rating ?? 1,
                            min: 0,
                            max: 5,
                            divisions: 5,
                            activeColor: const Color(0xFF11254B).withOpacity(0.9),
                            label: _rating?.toString(),
                            onChanged: isRatingEnabled ? (value) => setState(() => _rating = value) : null,
                          )
                        : const SizedBox.shrink()),
              ),
            ),
            const SizedBox(height: 10),
            // Calificación de mejora
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 4,
              color: const Color(0xFFF5CD84).withOpacity(0.6),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Icon(Icons.thumb_up, color: const Color(0xFF11254B).withOpacity(0.9)),
                title: const Text('Mejora de la duda:'),
                subtitle: widget.session.isRated
                    ? Text(
                        'Mejora actual: ${widget.session.improvementRating}',
                        style: TextStyle(fontSize: 18, color: const Color(0xFF11254B).withOpacity(0.9)),
                      )
                    : (isRatingEnabled
                        ? Slider(
                            value: _improvementRating ?? 1,
                            min: 0,
                            max: 5,
                            divisions: 5,
                            activeColor: const Color(0xFF11254B).withOpacity(0.9),
                            label: _improvementRating?.toString(),
                            onChanged: isRatingEnabled ? (value) => setState(() => _improvementRating = value) : null,
                          )
                        : const SizedBox.shrink()),
              ),
            ),
            const SizedBox(height: 16),
            // Comentarios adicionales
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 4,
              color: const Color(0xFFF5CD84).withOpacity(0.6),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Icon(Icons.comment, color: const Color(0xFF11254B).withOpacity(0.9)),
                title: const Text('Comentarios adicionales:'),
                subtitle: widget.session.isRated
                    ? Text(
                        'Comentarios: ${widget.session.feedback}',
                        style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.inversePrimary),
                      )
                    : (isRatingEnabled
                        ? TextField(
                            maxLength: 200,
                            maxLines: 3,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText: 'Escribe tus comentarios (máximo 200 caracteres)',
                              counterText: '', // Hide the default counter text
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Theme.of(context).primaryColor),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            enabled: isRatingEnabled,
                            onChanged: isRatingEnabled ? (value) => setState(() => _feedbackText = value) : null,
                          )
                        : const SizedBox.shrink()),
              ),
            ),
            const SizedBox(height: 20),
            // Botón para enviar la calificación
            if (isRatingEnabled)
  Center( // Añadido Center widget para centrar el botón
    child: ElevatedButton(
      onPressed: _submitRating,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF5CD84).withOpacity(0.6),
        padding: const EdgeInsets.symmetric(vertical: 15), // Padding para el botón
      ),
      child: const Padding( // Padding para el texto
        padding: EdgeInsets.symmetric(horizontal: 20), // Ajusta el padding horizontal para que el texto no toque los bordes
        child: Text(
          'Enviar calificación',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16, // Puedes ajustar el tamaño de la fuente si es necesario
          ),
        ),
      ),
    ),
  ),
          ],
        ),
      ),
    );
  }
}
