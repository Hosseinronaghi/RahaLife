import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/ai/presentation/ai_settings_screen.dart';
import '../features/auth/presentation/account_screen.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/common/presentation/coming_soon_screen.dart';
import '../features/cycle/presentation/cycle_screen.dart';
import '../features/dashboard/presentation/today_screen.dart';
import '../features/finance/presentation/finance_screen.dart';
import '../features/home/domain/home_entry.dart';
import '../features/lists/presentation/lists_screen.dart';
import '../features/lists/presentation/module_entries_screen.dart';
import '../features/medication/presentation/medication_screen.dart';
import '../features/more/presentation/more_screen.dart';
import '../features/people/presentation/people_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/search/presentation/global_search_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/shopping/presentation/shopping_list_screen.dart';
import '../features/shopping/presentation/shopping_screen.dart';
import '../l10n/generated/app_localizations.dart';
import 'shell/responsive_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/today',
    routes: [
      ShellRoute(
        builder: (context, state, child) => ResponsiveShell(child: child),
        routes: [
          GoRoute(path: '/today', builder: (_, __) => const TodayScreen()),
          GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
          GoRoute(path: '/lists', builder: (_, __) => const ListsScreen()),
          GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
          GoRoute(path: '/more', builder: (_, __) => const MoreScreen()),
        ],
      ),
      GoRoute(path: '/search', builder: (_, __) => const GlobalSearchScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/settings/ai', builder: (_, __) => const AiSettingsScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/account', builder: (_, __) => const AccountScreen()),
      GoRoute(path: '/people', builder: (_, __) => const PeopleScreen()),
      GoRoute(path: '/shopping', builder: (_, __) => const ShoppingScreen()),
      GoRoute(
        path: '/shopping/:id',
        builder: (_, state) => ShoppingListScreen(listId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/medication', builder: (_, __) => const MedicationScreen()),
      GoRoute(path: '/finance', builder: (_, __) => const FinanceScreen()),
      GoRoute(path: '/cycle', builder: (_, __) => const CycleScreen()),
      GoRoute(
        path: '/module/:type',
        builder: (context, state) {
          final name = state.pathParameters['type'];
          final type = HomeEntryType.values.firstWhere(
            (item) => item.name == name,
            orElse: () => HomeEntryType.affair,
          );
          return ModuleEntriesScreen(type: type);
        },
      ),
      GoRoute(
        path: '/coming-soon',
        builder: (context, state) => ComingSoonScreen(
          title: state.extra?.toString() ?? AppLocalizations.of(context).appName,
        ),
      ),
    ],
  );
});
