const syncModuleTypes = <String, List<String>>{
  'notes': ['rich_note'],
  'tasks': ['home_entry'],
  'shopping': ['shopping_list', 'shopping_item'],
  'projects': ['project'],
  'people': ['person'],
  'finance': ['finance_account', 'finance_transaction', 'budget'],
  'health': ['cycle_log', 'medication_plan'],
  'bookmarks': ['bookmark'],
};
const defaultSyncModules = ['notes', 'shopping', 'projects', 'bookmarks'];
Set<String>? syncTypes(Map<String, String> config) {
  final raw = config['modules'];
  if (raw == null) {
    return null; // Preserve existing explicit all-data connections.
  }
  return {for (final module in raw.split(',')) ...?syncModuleTypes[module]};
}
