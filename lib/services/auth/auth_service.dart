import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Authservice {
  // instance of auth & firestore
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get the current user's UID
  String? getCurrentUserUid() {
    return _auth.currentUser?.uid; // Return current user's UID or null
  }

  // get user role
  Future<String?> getUserRole() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection('Users').doc(user.uid).get();
      return doc['rol'];
    }
    return null;
  }

  // Obtener las salas de chat para el usuario actual
  Stream<QuerySnapshot> getChatRoomsForCurrentUser() {
    // Obtener el ID del usuario actual
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      // Consultar las salas de chat en las que el usuario actual está presente
      return _firestore
          .collection('chat_rooms')
          .where('UserIds', arrayContains: currentUser.uid)
          .snapshots();
    } else {
      // Si no hay un usuario actual, retornar un stream vacío
      return const Stream.empty();
    }
  }

  // get requests for current user
  Stream<QuerySnapshot> getRequestsForCurrentUser() {
    User? user = _auth.currentUser;
    if (user != null) {
      return _firestore
          .collection('solicitudes')
          .where('receptor', isEqualTo: user.email)
          .snapshots();
    }
    throw Exception("No user is currently signed in");
  }

  // sign in
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    try {
      // sign user in 
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // sign up
  Future<UserCredential> signUpWithEmailPassword(String email, String password) async {
    try {
      // create user
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );

      // save user info a separate doc
      await _firestore.collection("Users").doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'rol': "Estudiante",
        'isProfileUpdated': false, // New field added
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // sign out
  Future<void> signOut() async {
    return await _auth.signOut();
  }

  // errors
}
