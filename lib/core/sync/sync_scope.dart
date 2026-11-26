const syncModuleTypes = <String, List<String>>{
  'notes': ['rich_note'],
  'tasks': ['home_entry'],
  'shopping': ['shopping_list', 'shopping_item'],
  'projects': ['project'],
  'people': ['person'],
  'finance': ['finance_account', 'finance_transaction', 'budget'],
  'health': ['cycle_log', 'medication_plan', 'medication_dose'],
  'bookmarks': ['bookmark'],
  'entertainment': ['entertainment'],
  'files': ['attachment_blob', 'attachment_chunk', 'attachment_link'],
};
const defaultSyncModules = ['notes', 'shopping', 'projects', 'bookmarks'];
const sensitiveSyncModules = {'finance', 'health'};
const sensitiveSyncConsentKey = 'readableSensitiveSyncAccepted';

Set<String> effectiveSyncModules(Map<String, String> config) {
  final selected = (config['modules']?.split(',') ?? defaultSyncModules)
      .where(syncModuleTypes.containsKey)
      .toSet();
  if (config[sensitiveSyncConsentKey] != 'true') {
    selected.removeAll(sensitiveSyncModules);
  }
  return selected;
}

String syncScopeIdentity(Map<String, String> config) =>
    (effectiveSyncModules(config).toList()..sort()).join(',');

Set<String> syncTypes(Map<String, String> config) =>
    {for (final module in effectiveSyncModules(config)) ...syncModuleTypes[module]!};
