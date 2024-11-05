import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tutorias_estudiantes/components/chat_bubble.dart';
import 'package:tutorias_estudiantes/services/chat/chat_service.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatRoomID;

  const ChatRoomPage({super.key, required this.chatRoomID});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  List<String> userIds = [];

  @override
  void initState() {
    super.initState();
    _loadUserIds();
  }

  Future<void> _loadUserIds() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(widget.chatRoomID)
        .get();

    if (doc.exists) {
      setState(() {
        userIds = List<String>.from(doc['UserIds']);
      });
    }
  }

  void scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat Room"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getMessagesByChatRoomID(widget.chatRoomID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading messages"));
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No messages yet."));
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollDown(); // Scroll down when new messages are loaded
        });

        return ListView(
          controller: _scrollController,
          children: snapshot.data!.docs.map((doc) => _buildMessageItem(doc)).toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Get senderID
    String senderId = data['senderID'];

    // Ensure userIds has at least two elements to avoid RangeError
    bool isFromUser1 = userIds.isNotEmpty && senderId == userIds[0];
    bool isFromUser2 = userIds.length > 1 && senderId == userIds[1];

    Alignment alignment;
    CrossAxisAlignment crossAxisAlignment;

    if (isFromUser1) {
      alignment = Alignment.centerRight;
      crossAxisAlignment = CrossAxisAlignment.end;
    } else if (isFromUser2) {
      alignment = Alignment.centerLeft;
      crossAxisAlignment = CrossAxisAlignment.start;
    } else {
      alignment = Alignment.centerLeft; 
      crossAxisAlignment = CrossAxisAlignment.start;
    }

    return Container(
      alignment: alignment,
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          ChatBubble(
            message: data['message'],
            isCurrentUser: isFromUser1, 
          ),
        ],
      ),
    );
  }
}
