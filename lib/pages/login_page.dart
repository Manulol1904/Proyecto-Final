import 'package:flutter/material.dart';
import 'package:tutorias_estudiantes/pages/home_page.dart';
import 'package:tutorias_estudiantes/pages/register_page.dart';
import 'package:tutorias_estudiantes/services/auth/auth_service.dart';
import 'package:tutorias_estudiantes/components/my_button.dart';
import 'package:tutorias_estudiantes/components/my_textfiled.dart';

class LoginPage extends StatefulWidget {
  final void Function()? onTap;

  const LoginPage({super.key, required this.onTap});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  bool _isPasswordVisible = false;

  void login(BuildContext context) async {
  final authservice = Authservice();
  try {
    await authservice.signInWithEmailPassword(
        _emailController.text, _pwController.text);
    
    // Navigate to the Home Page after successful login
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(), // Replace with your actual home page widget
        ),
      );
    }
  } catch (e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Inicio de sesión fallido"),
        content: const Text("Por favor, revisa tu correo o contraseña e intenta nuevamente."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}



  void navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterPage(
          onTap: () => Navigator.pop(context), // Para volver al login
        ),
      ),
    );
  }

  void forgotPassword(BuildContext context) {
    final TextEditingController _forgotEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Recuperar Contraseña'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Por favor, ingrese su correo electrónico:'),
              const SizedBox(height: 10),
              TextField(
                controller: _forgotEmailController,
                decoration: InputDecoration(
                  hintText: 'Correo electrónico',
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final authservice = Authservice();
                try {
                  await authservice.resetPassword(_forgotEmailController.text);
                  Navigator.of(context).pop(); // Close the dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Correo de recuperación enviado'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Recuperar Contraseña'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.message,
              size: 60,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 50),
            Text(
              "Bienvenido de vuelta",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 25),
            MyTextField(
              hintText: "Correo",
              obscureText: false,
              controller: _emailController,
            ),
            const SizedBox(height: 10),
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
            MyButton(
              text: "Ingresar",
              onTap: () => login(context),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "No eres usuario?",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary),
                ),
                GestureDetector(
                  onTap: navigateToRegister,
                  child: Text(
                    "Registrate",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => forgotPassword(context),
              child: Text(
                "¿Olvidó su contraseña?",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
