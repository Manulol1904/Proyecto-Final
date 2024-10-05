class TutoringSession {
  final String tutoringId; // New field for the tutoring session ID
  final String scheduledDate;
  final String scheduledTime;
  final String studentCareer;
  final String studentName;
  final String studentUid;
  final String tutorName;
  final String tutorUid;

  TutoringSession({
    required this.tutoringId, // Add tutoringId to constructor
    required this.scheduledDate,
    required this.scheduledTime,
    required this.studentCareer,
    required this.studentName,
    required this.studentUid,
    required this.tutorName,
    required this.tutorUid,
  });

  factory TutoringSession.fromMap(Map<String, dynamic> data) {
    return TutoringSession(
      tutoringId: data['tutoringId'], // Initialize tutoringId from data
      scheduledDate: data['scheduledDate'],
      scheduledTime: data['scheduledTime'],
      studentCareer: data['studentCareer'],
      studentName: data['studentName'],
      studentUid: data['studentUid'],
      tutorName: data['tutorName'],
      tutorUid: data['tutorUid'],
    );
  }
}

