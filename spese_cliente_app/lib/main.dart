import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spese_cliente_app/data/client_repository.dart';
import 'package:spese_cliente_app/data/database_helper.dart';
import 'package:spese_cliente_app/data/material_repository.dart';
import 'package:spese_cliente_app/providers/client_provider.dart';
import 'package:spese_cliente_app/screens/client_list_screen.dart';

void main() {
  final helper = DatabaseHelper();
  final clientRepository = ClientRepository(helper);
  final materialRepository = MaterialRepository(helper);

  runApp(MultiProvider(
    providers: [
      Provider<MaterialRepository>.value(value: materialRepository),
      ChangeNotifierProvider<ClientProvider>(
        create: (_) => ClientProvider(clientRepository),
      ),
    ],
    child: const SpeseClienteApp(),
  ));
}

class SpeseClienteApp extends StatelessWidget {
  const SpeseClienteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spese Cliente',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
      ),
      home: const ClientListScreen(),
    );
  }
}
