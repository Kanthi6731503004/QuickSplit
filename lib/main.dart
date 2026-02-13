import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quicksplit/core/database/database_helper.dart';
import 'package:quicksplit/core/providers/bill_provider.dart';
import 'package:quicksplit/core/providers/theme_provider.dart';
import 'package:quicksplit/core/router/app_router.dart';
import 'package:quicksplit/core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DatabaseHelper.initForWeb();
  runApp(const QuickSplitApp());
}

class QuickSplitApp extends StatelessWidget {
  const QuickSplitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BillProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'QuickSplit',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
