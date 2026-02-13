import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quicksplit/core/database/database_helper.dart';
import 'package:quicksplit/core/providers/bill_provider.dart';
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
    return ChangeNotifierProvider(
      create: (_) => BillProvider(),
      child: MaterialApp.router(
        title: 'QuickSplit',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
      ),
    );
  }
}
