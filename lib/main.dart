import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutorias_estudiantes/services/auth/auth_gate.dart';
import 'package:tutorias_estudiantes/services/auth/login_or_register.dart';
import 'package:tutorias_estudiantes/firebase_options.dart';
import 'package:tutorias_estudiantes/themes/light_mode.dart';
import 'package:tutorias_estudiantes/themes/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MainApp(),
      )
    
    );
  
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Authgate(),
      theme: Provider.of<ThemeProvider>(context).themeData,
    );
  }
}
