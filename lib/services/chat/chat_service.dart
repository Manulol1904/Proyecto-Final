import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutorias_estudiantes/models/message.dart';
import 'package:tutorias_estudiantes/models/tutoring_session.dart';

class ChatService {
  // get instance of firestore & auth
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // get user stream
  Stream<List<Map<String, dynamic>>> getUserStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // go through each individual user
        final user = doc.data();

        // return user
        return user;
      }).toList();
    });
  }

  // Función para generar ID de sala de chat
  String _getChatRoomID(String userID1, String userID2) {
    List<String> ids = [userID1, userID2];
    ids.sort();
    return ids.join('_');
  }

  // send message
  Future<void> sendMessage(String receiverID, String message) async {
    try {
      // Obtener información del usuario actual
      final String currentUserID = _auth.currentUser!.uid;
      final String currentUserEmail = _auth.currentUser!.email!;
      final Timestamp timestamp = Timestamp.now();

      // Obtener el nombre del remitente
      DocumentSnapshot senderSnapshot = await _firestore.collection("Users").doc(currentUserID).get();
      String senderName = currentUserEmail; // Usa el correo como fallback

      if (senderSnapshot.exists) {
        Map<String, dynamic>? senderData = senderSnapshot.data() as Map<String, dynamic>?;
        senderName = senderData?['firstName'] ?? currentUserEmail; // Usa el nombre si está disponible
      }

      // Crear un nuevo mensaje
      Message newMessage = Message(
        senderID: currentUserID,
        senderEmail: currentUserEmail,
        receiverID: receiverID,
        message: message,
        timestamp: timestamp,
      );

      // Crear o actualizar la sala de chat
      String chatRoomID = _getChatRoomID(currentUserID, receiverID);

      await _firestore.collection("chat_rooms").doc(chatRoomID).set({
        'UserIds': [currentUserID, receiverID],
        'lastMessageTimestamp': timestamp,
      });

      // Añadir el nuevo mensaje a la sala de chat
      await _firestore.collection("chat_rooms").doc(chatRoomID).collection("messages").add(newMessage.toMap());

      // Crear la notificación para el receptor
      await _sendNotification(senderName, receiverID, currentUserEmail, currentUserID, chatRoomID, timestamp);
      
    } catch (e) {
      print("Error al enviar el mensaje: $e");
      throw Exception("Error al enviar el mensaje: $e");
    }
  }

  // Función para enviar la notificación
  Future<void> _sendNotification(String senderName, String receiverID, String currentUserEmail, String currentUserID, String chatRoomID, Timestamp timestamp) async {
    await _firestore.collection("notifications").add({
      'senderName': senderName,
      'receiverID': receiverID,
      'email': currentUserEmail, // Añadir el correo del receptor
      'senderID': currentUserID,
      'chatRoom': chatRoomID,
      'type': 'message',
      'isRead': false,
      'timestamp': timestamp,
    });
  }



  // get messages
  Stream<QuerySnapshot> getMessages(String userID, String otherUserID) {
    String chatRoomID = _getChatRoomID(userID, otherUserID);

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  // delete chat room and messages
  Future<void> deleteChatRoom(String userID, String otherUserID) async {
    String chatRoomID = _getChatRoomID(userID, otherUserID);

    // Delete all messages in the chat room
    WriteBatch batch = _firestore.batch(); // Using batch to handle multiple deletes

    QuerySnapshot messagesSnapshot = await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .get();

    for (var doc in messagesSnapshot.docs) {
      batch.delete(doc.reference); // Delete each message
    }

    // Delete the chat room document after deleting messages
    batch.delete(_firestore.collection("chat_rooms").doc(chatRoomID));

    // Commit the batch
    await batch.commit();
  }
}

class TutoringService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<TutoringSession>> getTutoringSessions(String? studentUid, String? tutorUid) {
    Query query = _firestore.collection("TutoringSessions");
    

    if (studentUid != null) {
      query = query.where("studentUid", isEqualTo: studentUid);
    }
    if (tutorUid != null) {
      query = query.where("tutorUid", isEqualTo: tutorUid);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return TutoringSession.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }
}
