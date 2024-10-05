import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tutorias_estudiantes/services/auth/auth_service.dart';
import 'package:tutorias_estudiantes/components/my_button.dart';
import 'package:tutorias_estudiantes/components/my_textfiled.dart';

class LoginPage extends StatelessWidget{

//email and pw text controllers
final TextEditingController _emailController = TextEditingController();
final TextEditingController _pwController = TextEditingController();

  // Tap to go to Resgiter page
  final void Function()? onTap;

  LoginPage ({
    super.key,
    required this.onTap,
    });

  // login method
  void login(BuildContext context) async {
    // auth service
    final  authservice = Authservice();

    // try login
    try {
      await authservice.signInWithEmailPassword(_emailController.text, _pwController.text);
    }

    // catch any errors
    catch (e) {
      showDialog(
        context: context, 
        builder: (context) => AlertDialog(
          title: Text(e.toString()),
        )
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
           // logo
           Icon(
            Icons.message,
            size: 60,
            color: Theme.of(context).colorScheme.primary,
            ),
            
            const SizedBox(height: 50),

           //welcome back message
           Text(
            "Bienvenido de vuelta",
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize:16,
            ),
            ),

            const SizedBox(height: 25),

           //email textfiled
           MyTextField(
            hintText: "Correo",
            obscureText: false,
            controller: _emailController,
           ),

           const SizedBox(height: 10),

           //pw textfiled
           MyTextField(
            hintText: "Contraseña",
            obscureText: true,
            controller: _pwController,
           ),

           const SizedBox(height: 25),

           //login button
           MyButton(
            text: "Ingresar",
            onTap: () => login(context),
           ),

           const SizedBox(height: 25),

           //register now
           Row(
            mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Text(
                "No eres usuario?",
                style: TextStyle(color: Theme.of(context).colorScheme.primary)
                ),
               GestureDetector(
                onTap: onTap,
                 child: Text(
                  "Registrate", 
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary
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