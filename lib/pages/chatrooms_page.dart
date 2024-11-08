import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutorias_estudiantes/pages/chat_page.dart';
import 'package:tutorias_estudiantes/services/auth/auth_service.dart';
import 'package:shimmer/shimmer.dart'; // Asegúrate de añadir shimmer a tus dependencias

class ChatRoomsPage extends StatefulWidget {
  final bool showAppBar;

  const ChatRoomsPage({Key? key, this.showAppBar = true}) : super(key: key);

  @override
  _ChatRoomsPageState createState() => _ChatRoomsPageState();
}

class _ChatRoomsPageState extends State<ChatRoomsPage> with AutomaticKeepAliveClientMixin {
  final Authservice _authService = Authservice();
  final ValueNotifier<String> _searchQuery = ValueNotifier('');
  final Map<String, Map<String, dynamic>> _usersCache = {};
  bool _isLoadingUsers = true;

  @override
  bool get wantKeepAlive => true; // Mantiene el estado cuando se cambia de tab

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchUsers();
    if (mounted) {
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final userSnapshots = await FirebaseFirestore.instance
          .collection('Users')
          .get(const GetOptions(source: Source.serverAndCache)); // Utiliza caché

      for (var doc in userSnapshots.docs) {
        _usersCache[doc.id] = doc.data();
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
    }
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.tertiary,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 140,
                        height: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 180,
                        height: 12,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatRoomsList(List<QueryDocumentSnapshot> chatRooms) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: chatRooms.length,
      itemBuilder: (context, index) {
        return _buildChatRoomItem(chatRooms[index]);
      },
    );
  }

  Widget _buildChatRoomItem(QueryDocumentSnapshot doc) {
    final chatRoom = doc.data() as Map<String, dynamic>;
    final userIds = chatRoom['UserIds'] as List<dynamic>;
    final receiverId = userIds.firstWhere(
      (id) => id != _authService.getCurrentUser()!.uid,
      orElse: () => '',
    );
    final userData = _usersCache[receiverId] ?? {};

    if (!_matchesSearch(userData)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5CD84).withOpacity(0.6),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _navigateToChat(userData, receiverId),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Hero(
                  tag: 'avatar_${userData['uid'] ?? ''}',
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF11254B).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(userData),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF11254B).withOpacity(0.9),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'name_${userData['uid'] ?? ''}',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            _getUserName(userData),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userData['email'] ?? "Email no disponible",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(Map<String, dynamic> userData) {
    if (userData.isEmpty) return "??";
    final firstName = userData['firstName'] as String? ?? '';
    final lastName = userData['lastName'] as String? ?? '';
    return "${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}";
  }

  String _getUserName(Map<String, dynamic> userData) {
    if (userData.isEmpty) return "Usuario no encontrado";
    return "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}".trim();
  }

  bool _matchesSearch(Map<String, dynamic> userData) {
    if (_searchQuery.value.isEmpty) return true;
    final searchLower = _searchQuery.value.toLowerCase();
    final firstName = userData['firstName']?.toString().toLowerCase() ?? '';
    final lastName = userData['lastName']?.toString().toLowerCase() ?? '';
    return firstName.contains(searchLower) || lastName.contains(searchLower);
  }

  void _navigateToChat(Map<String, dynamic> userData, String receiverId) {
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
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Chats'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar conversación...',
                filled: true,
                fillColor: const Color(0xFFF5CD84).withOpacity(0.6),
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 15.0,
                  horizontal: 20.0,
                ),
              ),
              onChanged: (value) => _searchQuery.value = value,
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _authService.getChatRoomsForCurrentUser(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorState();
                }

                // Solo mostramos el shimmer durante la carga inicial
                if ((snapshot.connectionState == ConnectionState.waiting && 
                     snapshot.data == null) || _isLoadingUsers) {
                  return _buildLoadingShimmer();
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                return ValueListenableBuilder<String>(
                  valueListenable: _searchQuery,
                  builder: (context, searchQuery, _) {
                    final filteredDocs = snapshot.data!.docs.where((doc) {
                      final chatRoom = doc.data() as Map<String, dynamic>;
                      final userIds = chatRoom['UserIds'] as List<dynamic>;
                      final receiverId = userIds.firstWhere(
                        (id) => id != _authService.getCurrentUser()!.uid,
                        orElse: () => '',
                      );
                      final userData = _usersCache[receiverId] ?? {};
                      return _matchesSearch(userData);
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              searchQuery.isEmpty 
                                ? "No hay conversaciones activas"
                                : "No se encontraron resultados para '$searchQuery'",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return _buildChatRoomsList(filteredDocs);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            "Error al cargar los chats",
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "No hay conversaciones activas",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}