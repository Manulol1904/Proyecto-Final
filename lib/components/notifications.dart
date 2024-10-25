// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutorias_estudiantes/pages/chat_page.dart';
import 'package:tutorias_estudiantes/pages/tutoringsession_page.dart';

class NotificationIcon extends StatefulWidget {
  final String userRole;

  const NotificationIcon({super.key, required this.userRole});

  @override
  NotificationIconState createState() => NotificationIconState();
}

class NotificationIconState extends State<NotificationIcon> {
  int notificationCount = 0; // Unread notification counter
  Map<String, DocumentSnapshot> messageNotifications = {}; // Map to store one message notification per sender
  List<DocumentSnapshot> tutoringNotifications = []; // List of tutoring notifications
  String notificationType = ""; // Notification type, can be "message" or "tutoring"
  StreamSubscription<QuerySnapshot>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _checkNotifications(); // Check notifications on startup
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel(); // Cancel the stream when the widget is disposed
    super.dispose();
  }

  Future<void> _checkNotifications() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _notificationSubscription = FirebaseFirestore.instance
          .collection('notifications')
          .where('receiverID', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          if (!mounted) return; // Ensure widget is still mounted
          setState(() {
            messageNotifications.clear();
            tutoringNotifications.clear();

            for (var doc in snapshot.docs) {
              String type = doc.get('type');
              if (type == 'message') {
                String senderID = doc.get('senderID');
                messageNotifications[senderID] = doc;
              } else if (type == 'tutoring') {
                tutoringNotifications.add(doc);
              }
            }

            notificationCount = messageNotifications.length + tutoringNotifications.length;
            notificationType = messageNotifications.isNotEmpty ? 'message' : tutoringNotifications.isNotEmpty ? 'tutoring' : '';
          });
        } else {
          if (!mounted) return; // Ensure widget is still mounted
          setState(() {
            notificationCount = 0;
            messageNotifications.clear();
            tutoringNotifications.clear();
            notificationType = '';
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.grey),
          onPressed: _showNotificationPopup, // Show popup when pressed
        ),
        if (notificationCount > 0)
          Positioned(
            right: 11,
            top: 11,
            child: _buildNotificationIndicator(),
          ),
      ],
    );
  }

  Widget _buildNotificationIndicator() {
    Color indicatorColor;

    if (notificationType == 'message') {
      indicatorColor = Colors.red;
    } else if (widget.userRole == 'Estudiante' && notificationType == 'tutoring') {
      indicatorColor = Colors.green;
    } else {
      indicatorColor = Colors.transparent;
    }

    return CircleAvatar(
      radius: 8.0,
      backgroundColor: indicatorColor,
    );
  }

  void _showNotificationPopup() async {
    if (notificationCount == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No tienes notificaciones pendientes")),
      );
      return;
    }

    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    await showMenu(
      context: context,
      position: position,
      items: [
        ...messageNotifications.values.map((notification) {
          return PopupMenuItem(
            value: notification,
            child: ListTile(
              title: Text(_getNotificationText(notification)),
              onTap: () => _onNotificationTapped(notification),
            ),
          );
        }),
        ...tutoringNotifications.map((notification) {
          return PopupMenuItem(
            value: notification,
            child: ListTile(
              title: Text(_getNotificationText(notification)),
              onTap: () => _onNotificationTapped(notification),
            ),
          );
        }),
      ],
    );
  }

  String _getNotificationText(DocumentSnapshot notification) {
    String type = notification.get('type');
    return type == 'message'
        ? 'Nuevo mensaje de ${notification.get('senderName')}'
        : type == 'tutoring'
            ? 'Nueva tutoría asignada'
            : 'Notificación';
  }

  void _onNotificationTapped(DocumentSnapshot notification) async {
  if (!mounted) return;
  Navigator.pop(context);
  String type = notification.get('type');

  if (type == 'message') {
    String senderID = notification.get('senderID');

    // Retrieve and delete all unread messages from the sender
    QuerySnapshot unreadMessages = await FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverID', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .where('senderID', isEqualTo: senderID)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in unreadMessages.docs) {
      await FirebaseFirestore.instance.collection('notifications').doc(doc.id).delete();
    }

    String chatRoomID = notification.get('chatRoom');
    String receiverID = notification.get('senderID');
    String receiverEmail = notification.get('email');
    _navigateToChat(chatRoomID, receiverID, receiverEmail);
  } else if (type == 'tutoring') {
    String studentUID = notification.get('receiverID');

    // Delete the tutoring notification document
    await FirebaseFirestore.instance.collection('notifications').doc(notification.id).delete();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TutoringSessionsPage(
          userRole: "Estudiante",
          studentUid: studentUID,
        ),
      ),
    );
  }

  // Refresh notifications after deletion
  _checkNotifications();
}


  void _navigateToChat(String chatRoomID, String receiverID, String receiverEmail) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          receiverID: receiverID,
          receiverEmail: receiverEmail,
        ),
      ),
    );
  }
}
