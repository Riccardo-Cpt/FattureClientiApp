import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:spese_cliente_app/data/client_repository.dart';
import 'package:spese_cliente_app/data/database_helper.dart';
import 'package:spese_cliente_app/data/material_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spese_cliente_app/l10n/strings.dart';
import 'package:spese_cliente_app/providers/client_provider.dart';
import 'package:spese_cliente_app/providers/locale_provider.dart';
import 'package:spese_cliente_app/screens/client_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final localeProvider = LocaleProvider.fromPrefs(
    prefs,
    WidgetsBinding.instance.platformDispatcher.locale,
  );
  final helper = DatabaseHelper();
  final clientRepository = ClientRepository(helper);
  final materialRepository = MaterialRepository(helper);

  runApp(MultiProvider(
    providers: [
      Provider<MaterialRepository>.value(value: materialRepository),
      Provider<ClientRepository>.value(value: clientRepository),
      ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
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
      locale: context.watch<LocaleProvider>().locale,
      supportedLocales: S.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
