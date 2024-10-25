import 'package:flutter/material.dart';
import 'package:tutorias_estudiantes/services/auth/auth_service.dart';
import 'package:tutorias_estudiantes/components/my_button.dart';
import 'package:tutorias_estudiantes/components/my_textfiled.dart';

class RegisterPage extends StatefulWidget {
  // Tap to go to Register page
  final void Function()? onTap;

  const RegisterPage({
    super.key,
    required this.onTap,
  });

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Email and password text controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final TextEditingController _confirmpwController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Register method
  void register(BuildContext context) {
    // Get auth service
    final _auth = Authservice();

    // Password match -> create user
    if (_pwController.text == _confirmpwController.text) {
      try {
        _auth.signUpWithEmailPassword(
          _emailController.text,
          _pwController.text,
        );
      } catch (e) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(e.toString()),
          ),
        );
      }
    } else {
      // Passwords don't match -> show error
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text("Las contraseñas no coinciden"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Icon(
              Icons.message,
              size: 60,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 50),

            // Welcome message
            Text(
              "Crea una cuenta para ti",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 25),

            // Email textfield
            MyTextField(
              hintText: "Correo",
              obscureText: false,
              controller: _emailController,
            ),
            const SizedBox(height: 10),

            // Password textfield with toggle visibility
            MyTextField(
              hintText: "Contraseña",
              obscureText: !_isPasswordVisible,
              controller: _pwController,
              hasToggleIcon: true,
              onToggleVisibility: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            const SizedBox(height: 10),

            // Confirm password textfield with toggle visibility
            MyTextField(
              hintText: "Confirmar Contraseña",
              obscureText: !_isConfirmPasswordVisible,
              controller: _confirmpwController,
              hasToggleIcon: true,
              onToggleVisibility: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
            const SizedBox(height: 25),

            // Register button
            MyButton(
              text: "Registrar",
              onTap: () => register(context),
            ),
            const SizedBox(height: 25),

            // Already have an account
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Ya tienes cuenta?",
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
                GestureDetector(
                  onTap: widget.onTap,
                  child: Text(
                    "Ingresa",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
