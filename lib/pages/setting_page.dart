import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutorias_estudiantes/themes/theme_provider.dart';

class SettingsPage extends StatelessWidget {
final bool showAppBar;

  const SettingsPage({Key? key, this.showAppBar = true}) : super(key: key);
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: showAppBar
          ? AppBar(
              title: const Text('Todos los Usuarios'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            )
          : null,
        body: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(12)
            ),
            margin: const EdgeInsets.all(25),
            padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              //dark mode
              const Text("Modo oscuro"),
          
          
              //switch toggle
              CupertinoSwitch(
                value: Provider.of<ThemeProvider>(context, listen: false).isDarkMode, 
                onChanged: (value) => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
                activeColor: const Color(0xFFF5CD84).withOpacity(0.8),
                
                ),
            ],
            ),
        ),
    );
  }
}