import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/features/projects/presentation/projects_controller.dart';

void main() {
  test('project checklist updates progress', () {
    final notifier = ProjectsNotifier(persistenceEnabled: false);
    final project = notifier.add(title: 'Raha Life');
    notifier.addChecklist(project.id, 'Design');
    notifier.addChecklist(project.id, 'Build');
    expect(notifier.state.single.checklistProgress, 0);

    final firstId = notifier.state.single.checklist.first.id;
    notifier.toggleChecklist(project.id, firstId);
    expect(notifier.state.single.checklistProgress, 0.5);
  });
}
