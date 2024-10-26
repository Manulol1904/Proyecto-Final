import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutorias_estudiantes/pages/chat_page.dart';
import 'package:tutorias_estudiantes/services/auth/auth_service.dart';

class ChatRoomsPage extends StatefulWidget {
  const ChatRoomsPage({super.key});

  @override
  _ChatRoomsPageState createState() => _ChatRoomsPageState();
}

class _ChatRoomsPageState extends State<ChatRoomsPage> {
  final Authservice _authService = Authservice();
  String _searchQuery = '';
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Fetch users when the widget is initialized
  }

  Future<void> _fetchUsers() async {
    final userSnapshots = await FirebaseFirestore.instance.collection('Users').get();
    setState(() {
      _users = userSnapshots.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Divider(
        color: Theme.of(context).colorScheme.primary,
        thickness: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Chats"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar chat...',
                filled: true,
                fillColor: Theme.of(context).primaryColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          _buildSeparator(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _authService.getChatRoomsForCurrentUser(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No hay chats."));
                }

                final chatRooms = snapshot.data!.docs;
                final filteredChatRooms = chatRooms.where((doc) {
                  var chatRoom = doc.data() as Map<String, dynamic>;
                  var userIds = chatRoom['UserIds'] as List<dynamic>;
                  var receiverId = userIds.firstWhere((id) => id != _authService.getCurrentUser()!.uid);
                  var userData = _users.firstWhere((user) => user['uid'] == receiverId, orElse: () => {});
                  return _isMatch(userData);
                }).toList();

                return ListView.separated(
                  itemCount: filteredChatRooms.length,
                  itemBuilder: (context, index) {
                    var chatRoom = filteredChatRooms[index].data() as Map<String, dynamic>;
                    var userIds = chatRoom['UserIds'] as List<dynamic>;
                    var receiverId = userIds.firstWhere((id) => id != _authService.getCurrentUser()!.uid);
                    var userData = _users.firstWhere(
                      (user) => user['uid'] == receiverId,
                      orElse: () => {},
                    );

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: userData.isNotEmpty
                            ? Text('${userData['firstName']} ${userData['lastName']}')
                            : const Text('Usuario no encontrado'),
                        onTap: () {
                          if (userData.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatPage(
                                  receiverEmail: userData['email'],
                                  receiverID: receiverId,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _isMatch(Map<String, dynamic> userData) {
    if (_searchQuery.isEmpty) return true;
    var firstName = userData['firstName']?.toLowerCase() ?? '';
    var lastName = userData['lastName']?.toLowerCase() ?? '';
    return firstName.contains(_searchQuery.toLowerCase()) || lastName.contains(_searchQuery.toLowerCase());
  }
}
