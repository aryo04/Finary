import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:cakeu/core/services/supabase_service.dart';
import 'package:cakeu/shared/widgets/main_shell.dart';
import 'package:cakeu/features/auth/presentation/pages/login_page.dart';
import 'package:cakeu/features/auth/presentation/pages/register_page.dart';
import 'package:cakeu/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:cakeu/features/transactions/presentation/pages/transactions_page.dart';
import 'package:cakeu/features/transactions/presentation/pages/add_transaction_page.dart';
import 'package:cakeu/features/categories/presentation/pages/categories_page.dart';
import 'package:cakeu/features/chatbot/presentation/pages/chatbot_page.dart';
import 'package:cakeu/features/reports/presentation/pages/reports_page.dart';
import 'package:cakeu/features/profile/presentation/pages/profile_page.dart';
import 'package:cakeu/features/security/presentation/pages/privacy_security_page.dart';
import 'package:cakeu/features/wallets/presentation/pages/manage_wallets_page.dart';

/// Adapter to bridge `Stream<AuthState>` to Listenable for GoRouter refreshListenable
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic>? stream) {
    if (stream == null) return;
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  StreamSubscription<dynamic>? _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

Stream<dynamic>? _getSafeAuthStateStream() {
  try {
    if (!SupabaseService.isInitialized) return null;
    return SupabaseService.client.auth.onAuthStateChange;
  } catch (_) {
    return null;
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/dashboard',
  refreshListenable: GoRouterRefreshStream(_getSafeAuthStateStream()),
  redirect: (context, state) {
    final isAuth = SupabaseService.isAuthenticated;
    final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';

    if (!isAuth && !isAuthRoute) {
      return '/login';
    }
    if (isAuth && isAuthRoute) {
      return '/dashboard';
    }
    return null;
  },
  routes: [
    // ─── Auth Routes ───
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),

    // ─── Stateful Shell Route with IndexedStack (Instant 60/120 FPS Tab Switching) ───
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: Dashboard (Beranda)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardPage(),
            ),
          ],
        ),

        // Tab 1: Transactions (Transaksi)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/transactions',
              builder: (context, state) => const TransactionsPage(),
            ),
          ],
        ),

        // Tab 2: Chat AI
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/chatbot',
              builder: (context, state) => const ChatbotPage(),
            ),
          ],
        ),

        // Tab 3: Reports (Laporan)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/reports',
              builder: (context, state) => const ReportsPage(),
            ),
          ],
        ),

        // Tab 4: Profile (Profil)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),

    // ─── Full-screen routes ───
    GoRoute(
      path: '/transactions/add',
      builder: (context, state) => const AddTransactionPage(),
    ),
    GoRoute(
      path: '/categories',
      builder: (context, state) => const CategoriesPage(),
    ),
    GoRoute(
      path: '/privacy-security',
      builder: (context, state) => const PrivacySecurityPage(),
    ),
    GoRoute(
      path: '/wallets',
      builder: (context, state) => const ManageWalletsPage(),
    ),
  ],
);
