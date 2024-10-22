class TutoringSession {
  final String tutoringId; // Tutoring session ID
  final String scheduledDate;
  final String scheduledTime;
  final String studentCareer;
  final String studentName;
  final String studentUid;
  final String tutorName;
  final String tutorUid;
  final double? rating; // New field for the rating
  final bool isRated; // New field to check if rated

  TutoringSession({
    required this.tutoringId,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.studentCareer,
    required this.studentName,
    required this.studentUid,
    required this.tutorName,
    required this.tutorUid,
    this.rating, // Optional, can be null if not rated yet
    this.isRated = false, // Default to false
  });

  factory TutoringSession.fromMap(Map<String, dynamic> data) {
    return TutoringSession(
      tutoringId: data['tutoringId'],
      scheduledDate: data['scheduledDate'],
      scheduledTime: data['scheduledTime'],
      studentCareer: data['studentCareer'],
      studentName: data['studentName'],
      studentUid: data['studentUid'],
      tutorName: data['tutorName'],
      tutorUid: data['tutorUid'],
      rating: data['rating']?.toDouble(), // Convert to double if it exists
      isRated: data['isRated'] ?? false, // Default to false if not present
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tutoringId': tutoringId,
      'scheduledDate': scheduledDate,
      'scheduledTime': scheduledTime,
      'studentCareer': studentCareer,
      'studentName': studentName,
      'studentUid': studentUid,
      'tutorName': tutorName,
      'tutorUid': tutorUid,
      'rating': rating, // Add rating to map
      'isRated': isRated, // Add isRated to map
    };
  }
}

