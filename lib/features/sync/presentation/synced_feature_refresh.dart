import '../../cycle/presentation/cycle_controller.dart';
import '../../finance/presentation/finance_controller.dart';
import '../../home/presentation/home_controller.dart';
import '../../inbox/presentation/inbox_controller.dart';
import '../../medication/presentation/medication_controller.dart';
import '../../messages/presentation/messages_controller.dart';
import '../../notes/presentation/notes_controller.dart';
import '../../people/presentation/people_controller.dart';
import '../../projects/presentation/projects_controller.dart';
import '../../sharing/presentation/sharing_controller.dart';
import '../../shopping/presentation/shopping_controller.dart';

void invalidateSyncedFeatureProviders(dynamic ref) {
  ref.invalidate(homeEntriesProvider);
  ref.invalidate(peopleProvider);
  ref.invalidate(shoppingProvider);
  ref.invalidate(notesProvider);
  ref.invalidate(projectsProvider);
  ref.invalidate(medicationProvider);
  ref.invalidate(cycleProvider);
  ref.invalidate(inboxProvider);
  ref.invalidate(messagesProvider);
  ref.invalidate(sharingProvider);
  ref.invalidate(financeProvider);
}
