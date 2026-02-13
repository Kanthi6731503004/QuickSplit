import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quicksplit/features/bill/screens/bill_editor_screen.dart';
import 'package:quicksplit/features/bill/screens/create_bill_screen.dart';
import 'package:quicksplit/features/bill/screens/add_people_screen.dart';
import 'package:quicksplit/features/bill/screens/tax_tip_screen.dart';
import 'package:quicksplit/features/bill/screens/summary_screen.dart';
import 'package:quicksplit/features/home/screens/home_screen.dart';

/// App-wide routing configuration using GoRouter.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: [
    // Home — Bill History
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),

    // Create New Bill
    GoRoute(
      path: '/bill/new',
      name: 'createBill',
      builder: (context, state) => const CreateBillScreen(),
    ),

    // Add People to Bill
    GoRoute(
      path: '/bill/:id/people',
      name: 'addPeople',
      builder: (context, state) {
        final billId = state.pathParameters['id']!;
        return AddPeopleScreen(billId: billId);
      },
    ),

    // Bill Editor (Main Workspace)
    GoRoute(
      path: '/bill/:id',
      name: 'billEditor',
      builder: (context, state) {
        final billId = state.pathParameters['id']!;
        return BillEditorScreen(billId: billId);
      },
    ),

    // Tax & Tip
    GoRoute(
      path: '/bill/:id/tax',
      name: 'taxTip',
      builder: (context, state) {
        final billId = state.pathParameters['id']!;
        return TaxTipScreen(billId: billId);
      },
    ),

    // Summary
    GoRoute(
      path: '/bill/:id/summary',
      name: 'summary',
      builder: (context, state) {
        final billId = state.pathParameters['id']!;
        return SummaryScreen(billId: billId);
      },
    ),
  ],
  errorBuilder: (context, state) =>
      Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
);
