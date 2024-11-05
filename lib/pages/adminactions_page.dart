import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminActionsPage extends StatelessWidget {
  const AdminActionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registros de Administración'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('AdminActions')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar los registros'));
          }

          final actions = snapshot.data!.docs;

          if (actions.isEmpty) {
            return const Center(child: Text('No hay registros de administración.'));
          }

          return ListView.builder(
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              final actionData = action.data() as Map<String, dynamic>;
              final actionType = actionData['actionType'];
              final targetId = actionData['targetId'];
              final timestamp = (actionData['timestamp'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.all(8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(actionType),
                  subtitle: Text('ID del objeto: $targetId\nFecha y hora: ${timestamp.toLocal()}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    onPressed: () async {
                      // Mostrar un diálogo de confirmación antes de eliminar
                      final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Confirmar eliminación'),
                            content: const Text('¿Estás seguro de que deseas eliminar este registro?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          );
                        },
                      );

                      // Si el usuario confirma la eliminación, proceder
                      if (shouldDelete == true) {
                        try {
                          await FirebaseFirestore.instance
                              .collection('AdminActions')
                              .doc(action.id) // Usa el ID del documento
                              .delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Registro eliminado exitosamente')),
                          );
                        } catch (error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al eliminar el registro: $error')),
                          );
                        }
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
