import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/todo_controller.dart';
import 'controllers/theme_controller.dart';
import 'views/home_screen.dart';

/// Entry point aplikasi Todo List MVC.
///
/// Inisialisasi:
///   1. `WidgetsFlutterBinding.ensureInitialized()` diperlukan sebelum
///      operasi async (SharedPreferences, SQLite).
///   2. ThemeController.loadTheme() dibaca dari SharedPreferences.
///   3. MultiProvider menyediakan TodoController & ThemeController
///      ke seluruh widget tree.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi FFI untuk SQLite di Windows/Linux
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Inisialisasi ThemeController dan baca tema tersimpan
  final themeController = ThemeController();
  await themeController.loadTheme();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider(create: (_) => TodoController()),
      ],
      child: const TodoApp(),
    ),
  );
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    return MaterialApp(
      title: 'Todo List',
      debugShowCheckedModeBanner: false,

      // ─── Light Theme ─────────────────────────────────────────────
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),

      // ─── Dark Theme ──────────────────────────────────────────────
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),

      themeMode: themeController.themeMode,
      home: const HomeScreen(),
    );
  }
}
