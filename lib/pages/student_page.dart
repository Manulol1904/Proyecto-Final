import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tutorias_estudiantes/pages/user_page.dart';
import 'package:tutorias_estudiantes/services/auth/auth_service.dart';

class StudentPage extends StatefulWidget {
  final bool showAppBar;

  const StudentPage({Key? key, this.showAppBar = true}) : super(key: key);
  
  @override
  _StudentPageState createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> with AutomaticKeepAliveClientMixin {
  final Authservice _authservice = Authservice();
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String selectedSpecialty = 'All';
  List<DocumentSnapshot>? cachedTutors;
  bool isFirstLoad = true;

  @override
  bool get wantKeepAlive => true;

  // Simplificamos el stream para debug
  late final Stream<QuerySnapshot> _tutorsStream = FirebaseFirestore.instance
      .collection('Users')
      .snapshots();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Todos los Usuarios'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            )
          : null,
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
    return Column(
      children: [
        _buildSearchBar(),
        _buildFilterChips(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _tutorsStream,
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              // Debug information
              if (snapshot.hasError) {
                debugPrint("Stream error: ${snapshot.error}");
                return Center(
                  child: Text("Error al cargar los tutores: ${snapshot.error}"),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting && isFirstLoad) {
                return _buildLoadingShimmer();
              }

              if (!snapshot.hasData) {
                debugPrint("No data in snapshot");
                return const Center(
                  child: Text("No hay datos disponibles."),
                );
              }

              if (snapshot.data!.docs.isEmpty) {
                debugPrint("Empty docs list");
                return const Center(
                  child: Text("No hay tutores disponibles."),
                );
              }

              isFirstLoad = false;
              final tutorUsers = snapshot.data!.docs.where((doc) {
                try {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  
                  // Verificación básica de los campos requeridos
                  if (!data.containsKey('rol') || 
                      !data.containsKey('firstName') || 
                      !data.containsKey('lastName') ||
                      !data.containsKey('email') ||
                      !data.containsKey('subjectArea')) {
                    debugPrint("Document ${doc.id} missing required fields");
                    return false;
                  }

                  // Verificar si es tutor
                  if (data['rol'] != 'Tutor') {
                    return false;
                  }

                  // Verificar si el nombre está vacío
                  if (data['firstName'].toString().trim().isEmpty) {
                    return false;
                  }

                  // Búsqueda por nombre o apellido
                  bool matchesSearch = searchQuery.isEmpty ||
                      data['firstName'].toString().toLowerCase().contains(searchQuery) ||
                      data['lastName'].toString().toLowerCase().contains(searchQuery);

                  // Filtro por especialidad
                  bool matchesSpecialty = selectedSpecialty == 'All' ||
                      data['subjectArea'].toString() == selectedSpecialty;

                  return matchesSearch && matchesSpecialty;
                } catch (e) {
                  debugPrint("Error processing document ${doc.id}: $e");
                  return false;
                }
              }).toList();

              if (tutorUsers.isEmpty) {
                return const Center(
                  child: Text("No se encontraron tutores con los criterios seleccionados."),
                );
              }

              return ListView.builder(
                itemCount: tutorUsers.length,
                itemBuilder: (context, index) {
                  try {
                    return _buildUserListItem(
                      tutorUsers[index].data() as Map<String, dynamic>,
                      context,
                    );
                  } catch (e) {
                    debugPrint("Error building list item at index $index: $e");
                    return const SizedBox.shrink();
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF5CD84).withOpacity(0.6),
          hintText: 'Buscar tutor',
          prefixIcon:  Icon(Icons.search, color: Theme.of(context).colorScheme.inversePrimary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          _buildFilterChip('All'),
          _buildFilterChip('Matemáticas'),
          _buildFilterChip('Inglés'),
          _buildFilterChip('Física'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String specialty) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(
          specialty,
          style: TextStyle(
            color: selectedSpecialty == specialty 
              ? Colors.white 
              : Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        selected: selectedSpecialty == specialty,
        onSelected: (selected) {
          setState(() {
            selectedSpecialty = specialty;
          });
        },
        backgroundColor: const Color(0xFFF5CD84).withOpacity(0.6),
        selectedColor: const Color(0xFF11254B),
        checkmarkColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: const BorderSide(color: Colors.transparent),
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.tertiary,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 24.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8.0),
              Container(
                width: 200.0,
                height: 16.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserListItem(Map<String, dynamic> userData, BuildContext context) {
  if (userData["email"] != _authservice.getCurrentUser()!.email) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: const Color(0xFFF5CD84).withOpacity(0.6),
            borderRadius: BorderRadius.circular(15.0),
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
              borderRadius: BorderRadius.circular(15.0),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserDetailPage(
                      receiverEmail: userData["email"].toString(),
                      receiverID: userData["uid"].toString(),
                      firstName: userData["firstName"].toString(),
                      lastName: userData["lastName"].toString(),
                      role: userData["rol"].toString(),
                      subjectArea: userData["subjectArea"].toString(),
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar circular
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF11254B).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          "${userData["firstName"][0]}${userData["lastName"][0]}",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF11254B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Información del tutor
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${userData["firstName"]} ${userData["lastName"]}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 16,
                                color: Theme.of(context).colorScheme.inversePrimary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  userData['email'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF11254B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.school_outlined,
                                  size: 16,
                                  color: Color(0xFF11254B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  userData['subjectArea'],
                                  style: const TextStyle(
                                    color: Color(0xFF11254B),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
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
        ),
      ],
    );
  } else {
    return const SizedBox.shrink();
  }
}
}