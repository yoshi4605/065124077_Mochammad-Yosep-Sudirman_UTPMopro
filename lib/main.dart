import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'providers/checklist_provider.dart';
import 'providers/earthquake_provider.dart';
import 'providers/watchlist_provider.dart';
import 'screens/main_shell.dart';
import 'services/database_helper.dart';
import 'utils/constants.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi SQLite databaseFactory untuk Desktop (Windows, Linux, macOS)
  DatabaseHelper.initializeFfi();

  // Inisialisasi locale bahasa Indonesia untuk format tanggal intl
  await initializeDateFormatting('id_ID', null);

  runApp(const SiagaBumiApp());
}

/// Root widget aplikasi SiagaBumi dengan MultiProvider
class SiagaBumiApp extends StatelessWidget {
  const SiagaBumiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => EarthquakeProvider()..fetchAll(),
        ),
        ChangeNotifierProvider(
          create: (_) => WatchlistProvider()..loadWatchlist(),
        ),
        ChangeNotifierProvider(
          create: (_) => ChecklistProvider()..loadItems(),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const MainShell(),
      ),
    );
  }
}
