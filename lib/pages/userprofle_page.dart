import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tutorias_estudiantes/pages/account_page.dart';
import 'package:tutorias_estudiantes/pages/changepass_page.dart';
import 'package:tutorias_estudiantes/pages/login_page.dart';

class UserProfilePage extends StatefulWidget {
  final String userRole;

  final bool showAppBar;

  const UserProfilePage({super.key, required this.userRole, this.showAppBar = true});


  

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();

  String? _selectedCareer;
  String? _selectedSubject;
  bool _isLoading = true;

  String get _userInitials {
    final firstName = _firstNameController.text;
    final lastName = _lastNameController.text;
    return (firstName.isNotEmpty ? firstName[0] : '') + 
           (lastName.isNotEmpty ? lastName[0] : '');
  }

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('Users').doc(user.uid).get();

      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>;

      setState(() {
        _firstNameController.text = userData['firstName'] ?? '';
        _lastNameController.text = userData['lastName'] ?? '';

        if (widget.userRole == 'Tutor') {
          _selectedSubject = userData['subjectArea'];
        } else if (widget.userRole == 'Estudiante') {
          _studentIdController.text = userData['studentId'] ?? '';
          _selectedCareer = userData['career'];
        }
      });
    } catch (e) {
      _showErrorSnackBar('Error al cargar la información: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> logout() async {
    try {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Está seguro que desea cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _performLogout();
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Error al cerrar sesión: $e');
    }
  }

  Future<void> _performLogout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _auth.signOut();
      if (!mounted) return;
      
      Navigator.pop(context);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage(onTap: () {})),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorSnackBar('Error al cerrar sesión: $e');
    }
  }

  Widget _buildInitialsAvatar() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF5CD84),
            const Color(0xFFF5CD84).withOpacity(0.8),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _userInitials.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileButton({
    required String text,
    required VoidCallback onPressed,
    Color? backgroundColor,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 24),
              const SizedBox(width: 12),
            ],
            Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.background,
                const Color(0xFFF5CD84).withOpacity(0.1),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                'Nombre:',
                '${_firstNameController.text} ${_lastNameController.text}',
                Icons.person,
              ),
              const Divider(height: 24),
              if (widget.userRole == 'Estudiante') ...[
                _buildInfoRow(
                  'Código:',
                  _studentIdController.text,
                  Icons.assignment_ind,
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  'Carrera:',
                  _selectedCareer ?? '',
                  Icons.school,
                ),
              ] else if (widget.userRole == 'Tutor') ...[
                _buildInfoRow(
                  'Área:',
                  _selectedSubject ?? '',
                  Icons.subject,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5CD84).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 24,
            color: const Color(0xFFF5CD84),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Theme.of(context).colorScheme.background,
    appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Info'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            )
          : null,
    body: _isLoading
        ? _buildShimmerEffect() // Mostrar el shimmer mientras se carga
        : SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 30),
                _buildInitialsAvatar(),
                const SizedBox(height: 30),
                _buildInfoCard(),
                const SizedBox(height: 30),
                _buildProfileButton(
                  text: 'Actualizar Información',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AccountPage(userRole: widget.userRole),
                    ),
                  ),
                  icon: Icons.edit,
                ),
                _buildProfileButton(
                  text: 'Actualizar Contraseña',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordPage(),
                    ),
                  ),
                  icon: Icons.lock,
                ),
                _buildProfileButton(
                  text: 'Cerrar Sesión',
                  onPressed: logout,
                  backgroundColor: Colors.red.shade600,
                  icon: Icons.exit_to_app,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
  );
}

Widget _buildShimmerEffect() {
  return SingleChildScrollView(
    child: Column(
      children: [
        const SizedBox(height: 30),
        Shimmer.fromColors(
          baseColor: Theme.of(context).colorScheme.tertiary,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(height: 30),
        _buildShimmerInfoCard(),
        const SizedBox(height: 30),
        _buildShimmerButton(),
        _buildShimmerButton(),
        _buildShimmerButton(),
        const SizedBox(height: 20),
      ],
    ),
  );
}

Widget _buildShimmerInfoCard() {
  return Shimmer.fromColors(
    baseColor: Theme.of(context).colorScheme.tertiary,
    highlightColor: Colors.grey.shade100,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      padding: const EdgeInsets.all(20.0),
      height: 200,
      color: Colors.grey.shade300,
    ),
  );
}

Widget _buildShimmerButton() {
  return Shimmer.fromColors(
    baseColor: Theme.of(context).colorScheme.tertiary,
    highlightColor: Colors.grey.shade100,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
      height: 50,
      color: Colors.grey.shade300,
    ),
  );
}

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }
}