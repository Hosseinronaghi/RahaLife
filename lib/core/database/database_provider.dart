import 'app_database.dart';

/// Single process-wide Drift database. The database itself runs off the UI
/// isolate on native platforms and in a worker/fallback storage on web.
final AppDatabase appDatabase = AppDatabase();
