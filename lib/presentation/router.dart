import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasir_app/presentation/common/providers/providers.dart';
import 'features/auth/login_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/product/pages/product_list_page.dart';
import 'features/product/pages/stock_page.dart';
import 'features/product/pages/category_page.dart';
import 'features/transaction/pages/pos_page.dart';
import 'features/transaction/pages/payment_page.dart';
import 'features/report/pages/report_page.dart';
import 'features/settings/pages/settings_page.dart';
import 'features/settings/pages/user_management_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final loc = state.matchedLocation;
      if (!isLoggedIn && loc != '/login') return '/login';
      if (isLoggedIn && loc == '/login') {
        final done = await ref.read(repositoryProvider).isOnboardingComplete();
        return done ? '/pos' : '/onboarding';
      }
      if (isLoggedIn && loc == '/onboarding') return null;
      // Role-based route guard: kasir tidak boleh akses laporan & manajemen user
      if (isLoggedIn) {
        final role = ref.read(repositoryProvider).currentUser?.role;
        const kasirBlocked = ['/report', '/users'];
        if (role == 'kasir' && kasirBlocked.contains(loc)) return '/pos';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
      GoRoute(
        path: '/payment',
        builder: (context, state) {
          final extra = state.extra as Map<String, double>? ?? const {};
          return PaymentPage(
            total: extra['total'] ?? 0,
            subtotal: extra['subtotal'] ?? 0,
            tax: extra['tax'] ?? 0,
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/pos', builder: (_, __) => const PosPage()),
          GoRoute(path: '/products', builder: (_, __) => const ProductListPage()),
          GoRoute(path: '/categories', builder: (_, __) => const CategoryPage()),
          GoRoute(path: '/stock', builder: (_, __) => const StockPage()),
          GoRoute(path: '/report', builder: (_, __) => const ReportPage()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
          GoRoute(path: '/users', builder: (_, __) => const UserManagementPage()),
        ],
      ),
    ],
  );
});

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).asData?.value;
    final role = user?.role;

    final destinations = <(IconData, String, String)>[
      (Icons.point_of_sale, 'POS', '/pos'),
      (Icons.inventory_2, 'Produk', '/products'),
      (Icons.inventory, 'Stok', '/stock'),
    ];
    // Laporan hanya untuk admin & owner (bukan kasir)
    if (role == 'admin' || role == 'owner') {
      destinations.add((Icons.bar_chart, 'Laporan', '/report'));
    }
    destinations.add((Icons.settings, 'Settings', '/settings'));

    return _MainShellContent(destinations: destinations, child: child);
  }
}

class _MainShellContent extends StatefulWidget {
  final List<(IconData, String, String)> destinations;
  final Widget child;
  const _MainShellContent({required this.destinations, required this.child});

  @override
  State<_MainShellContent> createState() => _MainShellContentState();
}

class _MainShellContentState extends State<_MainShellContent> {
  int _selectedIndex = 0;

  void _onTap(int index) {
    setState(() => _selectedIndex = index);
    context.go(widget.destinations[index].$3);
  }

  @override
  Widget build(BuildContext context) {
    final dests = widget.destinations;
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex.clamp(0, dests.length - 1),
        onDestinationSelected: _onTap,
        destinations: dests
            .map((d) => NavigationDestination(icon: Icon(d.$1), label: d.$2))
            .toList(),
      ),
    );
  }
}
