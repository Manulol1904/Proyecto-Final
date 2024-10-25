import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutorias_estudiantes/pages/chat_page.dart';
import 'package:tutorias_estudiantes/pages/tutoringsession_page.dart';

class NotificationIcon extends StatefulWidget {
  final String userRole;

  const NotificationIcon({Key? key, required this.userRole}) : super(key: key);

  @override
  _NotificationIconState createState() => _NotificationIconState();
}

class _NotificationIconState extends State<NotificationIcon> {
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
          setState(() {
            // Clear current notifications
            messageNotifications.clear();
            tutoringNotifications.clear();

            for (var doc in snapshot.docs) {
              String type = doc.get('type');
              if (type == 'message') {
                String senderID = doc.get('senderID');
                // Keep only the latest message per sender
                messageNotifications[senderID] = doc;
              } else if (type == 'tutoring') {
                tutoringNotifications.add(doc);
              }
            }

            // Calculate the total notification count
            notificationCount = messageNotifications.length + tutoringNotifications.length;
            // Set the type to the first notification's type, just for display purposes
            if (messageNotifications.isNotEmpty) {
              notificationType = 'message';
            } else if (tutoringNotifications.isNotEmpty) {
              notificationType = 'tutoring';
            } else {
              notificationType = '';
            }
          });
        } else {
          setState(() {
            notificationCount = 0;
            messageNotifications.clear();
            tutoringNotifications.clear();
            notificationType = ''; // Reset notification type
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
          icon: Icon(Icons.notifications, color: Colors.grey),
          onPressed: _showNotificationPopup, // Show popup when pressed
        ),
        if (notificationCount > 0) ...[
          Positioned(
            right: 11,
            top: 11,
            child: _buildNotificationIndicator(),
          ),
        ],
      ],
    );
  }

  Widget _buildNotificationIndicator() {
    Color indicatorColor;

    if (notificationType == 'message') {
      indicatorColor = Colors.red; // Message notification
    } else if (widget.userRole == 'Estudiante' && notificationType == 'tutoring') {
      indicatorColor = Colors.green; // Assigned tutoring notification
    } else {
      indicatorColor = Colors.transparent; // No notifications
    }

    return CircleAvatar(
      radius: 8.0,
      backgroundColor: indicatorColor,
    );
  }

  // Show notification popup
  void _showNotificationPopup() async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    // Ensure there are notifications before showing the menu
    if (notificationCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No tienes notificaciones pendientes")),
      );
      return;
    }

    await showMenu(
      context: context,
      position: position,
      items: [
        // Add message notifications to the menu
        ...messageNotifications.values.map((notification) {
          return PopupMenuItem(
            value: notification,
            child: ListTile(
              title: Text(_getNotificationText(notification)),
              onTap: () => _onNotificationTapped(notification),
            ),
          );
        }).toList(),
        // Add tutoring notifications to the menu
        ...tutoringNotifications.map((notification) {
          return PopupMenuItem(
            value: notification,
            child: ListTile(
              title: Text(_getNotificationText(notification)),
              onTap: () => _onNotificationTapped(notification),
            ),
          );
        }).toList(),
      ],
    );
  }

  // Generate notification text
  String _getNotificationText(DocumentSnapshot notification) {
    String type = notification.get('type');
    if (type == 'message') {
      return 'Nuevo mensaje de ${notification.get('senderName')}';
    } else if (type == 'tutoring') {
      return 'Nueva tutoría asignada';
    } else {
      return 'Notificación';
    }
  }

  // Actions when a notification is tapped
  // Actions when a notification is tapped
void _onNotificationTapped(DocumentSnapshot notification) async {
  Navigator.pop(context); // Close the menu
  String type = notification.get('type');

  if (type == 'message') {
    String senderID = notification.get('senderID');

    // Mark all unread messages from this sender as read
    QuerySnapshot unreadMessages = await FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverID', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .where('senderID', isEqualTo: senderID)
        .where('isRead', isEqualTo: false)
        .get();

    // Update all unread notifications from this sender
    for (var doc in unreadMessages.docs) {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(doc.id)
          .update({'isRead': true});
    }

    // Navigate to chat
    String chatRoomID = notification.get('chatRoom');
    String receiverID = notification.get('senderID'); // Get receiver ID
    String receiverEmail = notification.get('email'); // Get receiver email
    _navigateToChat(chatRoomID, receiverID, receiverEmail);

  } else if (type == 'tutoring') {
    String studentUID = notification.get('receiverID');
    await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notification.id)
          .update({'isRead': true});
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

  // Refresh notifications to avoid showing those already read
  _checkNotifications();
}


  // Navigate to the corresponding chat screen
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
