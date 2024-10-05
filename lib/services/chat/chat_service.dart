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

  // send message
  Future<void> sendMessage(String receiverID, String message) async {
    // get current user info
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    // create a new message
    Message newMessage = Message(
      senderID: currentUserID,
      senderEmail: currentUserEmail,
      receiverID: receiverID,
      message: message,
      timestamp: timestamp,
    );

    // construct chat room ID for the two
    List<String> ids = [currentUserID, receiverID];
    ids.sort();
    String chatRoomID = ids.join('_');

    // create or update the chat room with user IDs
    await _firestore.collection("chat_rooms").doc(chatRoomID).set({
      'UserIds': ids,
      'lastMessageTimestamp': timestamp, // Optional: Store the timestamp of the last message
    });

    // add new message to the chat room
    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .add(newMessage.toMap());
  }

  // get messages
  Stream<QuerySnapshot> getMessages(String userID, String otherUserID) {
    // construct a chat room ID for the two users
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  // delete chat room and messages
  Future<void> deleteChatRoom(String userID, String otherUserID) async {
    // construct a chat room ID for the two users
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');

    // Delete all messages in the chat room
    WriteBatch batch = _firestore.batch();  // Using batch to handle multiple deletes

    QuerySnapshot messagesSnapshot = await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .get();

    for (var doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);  // Delete each message
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
    } else if (tutorUid != null) {
      query = query.where("tutorUid", isEqualTo: tutorUid);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return TutoringSession.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }
}


