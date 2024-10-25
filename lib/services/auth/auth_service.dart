import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Authservice {
  // Instancia de auth & firestore
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener el usuario actual
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Obtener el UID del usuario actual
  String? getCurrentUserUid() {
    return _auth.currentUser?.uid; // Devuelve el UID del usuario actual o null
  }

  // Obtener el rol del usuario
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
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      return _firestore
          .collection('chat_rooms')
          .where('UserIds', arrayContains: currentUser.uid)
          .snapshots();
    } else {
      return const Stream.empty();
    }
  }

  // Obtener solicitudes para el usuario actual
  Stream<QuerySnapshot> getRequestsForCurrentUser() {
    User? user = _auth.currentUser;
    if (user != null) {
      return _firestore
          .collection('solicitudes')
          .where('receptor', isEqualTo: user.email)
          .snapshots();
    }
    throw Exception("No hay usuario actualmente autenticado");
  }

  // Iniciar sesión
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // Registrarse y iniciar sesión
  Future<UserCredential> signUpWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );

      // Guardar la información del usuario en Firestore
      await _firestore.collection("Users").doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'rol': "Estudiante",
        'isProfileUpdated': false,
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // Crear usuario sin iniciar sesión
  Future<void> createUserWithoutSignIn({
  required String email,
  required String password,
  required String role,
}) async {
  try {
    // Crear un nuevo usuario en Firebase Authentication sin iniciar sesión
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Obtener el usuario actual (que es el nuevo usuario)
    User? newUser  = _auth.currentUser ;

    // Asegurarte de que el usuario no sea nulo
    if (newUser  != null) {
      // Guardar la información del usuario en Firestore
      await _firestore.collection('Users').doc(newUser .uid).set({
        'uid': newUser .uid,
        'email': email,
        'rol': role,
        'isProfileUpdated': false,
      });

      // Desconectar el nuevo usuario
      await _auth.signOut();
    }
  } on FirebaseAuthException catch (e) {
    throw Exception(e.code);
  }
}

  // Restablecer contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // Cerrar sesión
  // Cerrar sesión
Future<void> signOut() async {
  try {
    print("Intentando cerrar sesión...");
    await _auth.signOut();
    print("Sesión cerrada con éxito.");
  } catch (e) {
    print("Error al cerrar sesión: $e");
    throw Exception("Error al cerrar sesión: $e");
  }
}

  // Eliminar usuario de Firestore y autenticación
  Future<void> deleteUser(String uid) async {
    try {
      // Eliminar usuario de Firestore
      await _firestore.collection('Users').doc(uid).delete();

      // Eliminar usuario de Firebase Authentication
      User? user = await _auth.currentUser;
      if (user != null && user.uid == uid) {
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    } catch (e) {
      throw Exception("Error al eliminar usuario: $e");
    }
  }
}
