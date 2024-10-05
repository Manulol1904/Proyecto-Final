import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tutorias_estudiantes/services/auth/auth_service.dart';
import 'package:tutorias_estudiantes/components/my_button.dart';
import 'package:tutorias_estudiantes/components/my_textfiled.dart';

class RegisterPage extends StatelessWidget{

  //email and pw text controllers
final TextEditingController _emailController = TextEditingController();
final TextEditingController _pwController = TextEditingController();
final TextEditingController _confirmpwController = TextEditingController();

// Tap to go to Resgiter page
  final void Function()? onTap;

  RegisterPage ({
    super.key,
    required this.onTap,
    });

  //register method
  void register(BuildContext context){
    // get auth service
    final _auth = Authservice();

    // password match -> create user
    if(_pwController.text == _confirmpwController.text){
      try{
        _auth.signUpWithEmailPassword(
      _emailController.text, 
      _pwController.text,
      );
      }catch (e){
        showDialog(
        context: context, 
        builder: (context) => AlertDialog(
          title: Text(e.toString()),
        )
        );
      }
    }
    // password dont match -> show error to user
    else{
      showDialog(
        context: context, 
        builder: (context) => const AlertDialog(
          title: Text("Las contraseñas no coinciden"),
        )
        );

    }

  }

  @override
  Widget build(BuildContext context){
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
            "Crea una cuenta para ti",
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

           const SizedBox(height: 10),

           //confirmpw textfield
           MyTextField(
            hintText: "Confirmar Contraseña",
            obscureText: true,
            controller: _confirmpwController,
           ),

           const SizedBox(height: 25),

           //login button
           MyButton(
            text: "Registrar",
            onTap: () => register(context),
           ),

           const SizedBox(height: 25),

           //register now
           Row(
            mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Text(
                "Ya tienes cuenta?",
                style: TextStyle(color: Theme.of(context).colorScheme.primary)
                ),
               GestureDetector(
                onTap: onTap,
                 child: Text(
                  "Ingresa", 
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