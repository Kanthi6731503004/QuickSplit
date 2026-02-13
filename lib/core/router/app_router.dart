import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quicksplit/features/bill/screens/bill_editor_screen.dart';
import 'package:quicksplit/features/bill/screens/create_bill_screen.dart';
import 'package:quicksplit/features/bill/screens/add_people_screen.dart';
import 'package:quicksplit/features/bill/screens/tax_tip_screen.dart';
import 'package:quicksplit/features/bill/screens/summary_screen.dart';
import 'package:quicksplit/features/home/screens/home_screen.dart';

/// Custom page with SharedAxisTransition for forward/backward navigation.
CustomTransitionPage<void> _sharedAxisPage({
  required GoRouterState state,
  required Widget child,
  SharedAxisTransitionType type = SharedAxisTransitionType.horizontal,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: type,
        child: child,
      );
    },
  );
}

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
      pageBuilder: (context, state) =>
          _sharedAxisPage(state: state, child: const CreateBillScreen()),
    ),

    // Add People to Bill
    GoRoute(
      path: '/bill/:id/people',
      name: 'addPeople',
      pageBuilder: (context, state) {
        final billId = state.pathParameters['id']!;
        return _sharedAxisPage(
          state: state,
          child: AddPeopleScreen(billId: billId),
        );
      },
    ),

    // Bill Editor (Main Workspace)
    GoRoute(
      path: '/bill/:id',
      name: 'billEditor',
      pageBuilder: (context, state) {
        final billId = state.pathParameters['id']!;
        return _sharedAxisPage(
          state: state,
          child: BillEditorScreen(billId: billId),
        );
      },
    ),

    // Tax & Tip
    GoRoute(
      path: '/bill/:id/tax',
      name: 'taxTip',
      pageBuilder: (context, state) {
        final billId = state.pathParameters['id']!;
        return _sharedAxisPage(
          state: state,
          child: TaxTipScreen(billId: billId),
        );
      },
    ),

    // Summary
    GoRoute(
      path: '/bill/:id/summary',
      name: 'summary',
      pageBuilder: (context, state) {
        final billId = state.pathParameters['id']!;
        return _sharedAxisPage(
          state: state,
          child: SummaryScreen(billId: billId),
          type: SharedAxisTransitionType.vertical,
        );
      },
    ),
  ],
  errorBuilder: (context, state) =>
      Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
);
