import 'package:flutter/material.dart';
import 'package:tutorias_estudiantes/pages/chatrooms_page.dart';
import 'package:tutorias_estudiantes/pages/tutoringsession_page.dart';
import 'package:tutorias_estudiantes/pages/userprofle_page.dart';
import 'package:tutorias_estudiantes/services/auth/auth_service.dart';
import 'package:tutorias_estudiantes/pages/setting_page.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  _MyDrawerState createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  String? userRole;
  String? userUid; // Define userUid
  final Authservice _authService = Authservice();

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    _fetchUserUid(); // Fetch user UID during initialization
  }

  Future<void> _fetchUserRole() async {
    String? role = await _authService.getUserRole();
    setState(() {
      userRole = role;
    });
  }

  Future<void> _fetchUserUid() async {
    String? uid = _authService.getCurrentUserUid(); // Method to get current user UID
    setState(() {
      userUid = uid;
    });
  }

  void logout() {
    _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (userRole == null || userUid == null) { // Check if userRole or userUid is null
      return Drawer(
        backgroundColor: Theme.of(context).colorScheme.background,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              // Logo
              DrawerHeader(
                child: Center(
                  child: Icon(
                    Icons.message,
                    color: Theme.of(context).colorScheme.primary,
                    size: 60,
                  ),
                ),
              ),

              // Home list tile
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                  title: const Text("I N I C I O"),
                  leading: const Icon(Icons.home),
                  onTap: () {
                    // pop the drawer
                    Navigator.pop(context);
                  },
                ),
              ),

              // Account option for all users
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                  title: const Text("C U E N T A"),
                  leading: const Icon(Icons.person),
                  onTap: () {
                    // pop the drawer
                    Navigator.pop(context);
                    
                    // navigate to account page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfilePage(userRole: userRole!),
                      ),
                    );
                  },
                ),
              ),

              // Chat option
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                  title: const Text("C H A T S"),
                  leading: const Icon(Icons.chat),
                  onTap: () {
                    // pop the drawer
                    Navigator.pop(context);
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomsPage(),
                      ),
                    );
                  },
                ),
              ),

              // Settings option
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                  title: const Text("C O N F I G U R A C I O N"),
                  leading: const Icon(Icons.settings),
                  onTap: () {
                    // pop the drawer
                    Navigator.pop(context);
                    
                    // navigate to settings page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),
              ),

              // Role-specific options
              if (userRole == 'Estudiante') ...[
                Padding(
                  padding: const EdgeInsets.only(left: 25.0),
                  child: ListTile(
                    title: const Text("T U T O R I A S"),
                    leading: const Icon(Icons.school),
                    onTap: () {
                      // Action for students
                      Navigator.pop(context);
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TutoringSessionsPage(
                            studentUid: userUid, // Pass the student UID
                            userRole: userRole!,  // Pass the user role
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ] else if (userRole == 'Tutor') ...[
                Padding(
                  padding: const EdgeInsets.only(left: 25.0),
                  child: ListTile(
                    title: const Text("T U T O R I A S"),
                    leading: const Icon(Icons.book),
                    onTap: () {
                      // Action for tutors
                      Navigator.pop(context);
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TutoringSessionsPage(
                            tutorUid: userUid, // Pass the tutor UID
                            userRole: userRole!, // Pass the user role
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
          // Logout list tile
          Padding(
            padding: const EdgeInsets.only(left: 25.0, bottom: 25),
            child: ListTile(
              title: const Text("S A L I R"),
              leading: const Icon(Icons.logout),
              onTap: logout,
            ),
          ),
        ],
      ),
    );
  }
}
