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
import '../features/inbox/presentation/inbox_screen.dart';
import '../features/lists/presentation/lists_screen.dart';
import '../features/lists/presentation/module_entries_screen.dart';
import '../features/medication/presentation/medication_screen.dart';
import '../features/messages/presentation/chat_screen.dart';
import '../features/messages/presentation/messages_screen.dart';
import '../features/more/presentation/more_screen.dart';
import '../features/notes/presentation/note_editor_screen.dart';
import '../features/notes/presentation/notes_screen.dart';
import '../features/people/presentation/people_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/projects/presentation/project_details_screen.dart';
import '../features/projects/presentation/projects_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/search/presentation/global_search_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/shopping/presentation/shopping_list_screen.dart';
import '../features/shopping/presentation/shopping_screen.dart';
import '../features/sync/presentation/sync_center_screen.dart';
import '../features/widgets/presentation/quick_add_launch_screen.dart';
import '../features/widgets/presentation/widget_settings_screen.dart';
import '../l10n/generated/app_localizations.dart';
import 'shell/responsive_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/today',
    routes: [
      ShellRoute(
        builder: (context, state, child) => ResponsiveShell(child: child),
        routes: [
          GoRoute(path: '/today', builder: (_, _) => const TodayScreen()),
          GoRoute(path: '/calendar', builder: (_, _) => const CalendarScreen()),
          GoRoute(path: '/lists', builder: (_, _) => const ListsScreen()),
          GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen()),
          GoRoute(path: '/more', builder: (_, _) => const MoreScreen()),
        ],
      ),
      GoRoute(path: '/search', builder: (_, _) => const GlobalSearchScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/settings/ai', builder: (_, _) => const AiSettingsScreen()),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
      GoRoute(path: '/sync', builder: (_, _) => const SyncCenterScreen()),
      GoRoute(path: '/widgets', builder: (_, _) => const WidgetSettingsScreen()),
      GoRoute(path: '/quick-add', builder: (_, _) => const QuickAddLaunchScreen()),
      GoRoute(path: '/inbox', builder: (_, _) => const InboxScreen()),
      GoRoute(path: '/projects', builder: (_, _) => const ProjectsScreen()),
      GoRoute(
        path: '/projects/:id',
        builder: (_, state) => ProjectDetailsScreen(
          projectId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(path: '/notes', builder: (_, _) => const NotesScreen()),
      GoRoute(
        path: '/notes/edit',
        builder: (_, state) {
          String? noteId;
          String? projectId;
          final extra = state.extra;
          if (extra is String) {
            noteId = extra;
          } else if (extra is Map) {
            noteId = extra['noteId']?.toString();
            projectId = extra['projectId']?.toString();
          }
          return NoteEditorScreen(
            noteId: noteId,
            initialProjectId: projectId,
          );
        },
      ),
      GoRoute(path: '/messages', builder: (_, _) => const MessagesScreen()),
      GoRoute(
        path: '/messages/:personId',
        builder: (_, state) => ChatScreen(
          personId: state.pathParameters['personId']!,
        ),
      ),
      GoRoute(path: '/people', builder: (_, _) => const PeopleScreen()),
      GoRoute(path: '/shopping', builder: (_, _) => const ShoppingScreen()),
      GoRoute(
        path: '/shopping/:id',
        builder: (_, state) => ShoppingListScreen(
          listId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(path: '/medication', builder: (_, _) => const MedicationScreen()),
      GoRoute(path: '/finance', builder: (_, _) => const FinanceScreen()),
      GoRoute(path: '/cycle', builder: (_, _) => const CycleScreen()),
      GoRoute(
        path: '/module/:type',
        builder: (context, state) {
          final name = state.pathParameters['type'];
          final type = HomeEntryType.values.firstWhere(
            (item) => item.name == name,
            orElse: () => HomeEntryType.affair,
          );
          return ModuleEntriesScreen(
            type: type,
            projectId: state.extra is String ? state.extra as String : null,
          );
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
