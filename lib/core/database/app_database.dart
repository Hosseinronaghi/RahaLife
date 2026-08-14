import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get colorValue => integer().nullable()();
  TextColumn get iconName => text().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {id};
}


@DataClassName('PersonRow')
class People extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get relationship => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  DateTimeColumn get birthDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('UserProfileRow')
class UserProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text().unique()();
  TextColumn get remoteUserId => text().nullable()();
  BoolColumn get isLocalOnly => boolean().withDefault(const Constant(true))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('AffairRow')
class Affairs extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get affairType => text().withDefault(const Constant('personal'))();
  TextColumn get personId => text().nullable().references(People, #id)();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get projectId => text().nullable()();
  DateTimeColumn get startsAt => dateTime().nullable()();
  DateTimeColumn get dueAt => dateTime().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  TextColumn get recurrenceRule => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  @override Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('MedicationRow')
class Medications extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get medicationForm => text().withDefault(const Constant('tablet'))();
  TextColumn get dosage => text().nullable()();
  TextColumn get instructions => text().nullable()();
  DateTimeColumn get startsOn => dateTime().nullable()();
  DateTimeColumn get endsOn => dateTime().nullable()();
  RealColumn get stockQuantity => real().nullable()();
  RealColumn get lowStockThreshold => real().nullable()();
  DateTimeColumn get expiresOn => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('MedicationScheduleRow')
class MedicationSchedules extends Table {
  TextColumn get id => text()();
  TextColumn get medicationId => text().references(Medications, #id)();
  TextColumn get localTime => text()();
  TextColumn get recurrenceRule => text()();
  RealColumn get quantityPerDose => real().nullable()();
  IntColumn get reminderMinutesBefore => integer().withDefault(const Constant(0))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('MedicationLogRow')
class MedicationLogs extends Table {
  TextColumn get id => text()();
  TextColumn get scheduleId => text().references(MedicationSchedules, #id)();
  DateTimeColumn get scheduledAt => dateTime()();
  DateTimeColumn get actedAt => dateTime().nullable()();
  TextColumn get status => text()();
  TextColumn get note => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('AppointmentRow')
class Appointments extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get appointmentType => text().withDefault(const Constant('meeting'))();
  TextColumn get personId => text().nullable().references(People, #id)();
  TextColumn get contactName => text().nullable()();
  TextColumn get contactPhone => text().nullable()();
  TextColumn get location => text().nullable()();
  DateTimeColumn get startsAt => dateTime()();
  DateTimeColumn get endsAt => dateTime().nullable()();
  TextColumn get recurrenceRule => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('scheduled'))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {id};
}


@DataClassName('BirthdayRow')
class Birthdays extends Table {
  TextColumn get id => text()();
  TextColumn get personName => text()();
  TextColumn get personId => text().nullable().references(People, #id)();
  TextColumn get relationship => text().nullable()();
  DateTimeColumn get birthDate => dateTime()();
  TextColumn get calendarType => text().withDefault(const Constant('gregorian'))();
  IntColumn get reminderDaysBefore => integer().withDefault(const Constant(1))();
  TextColumn get note => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('NoteRow')
class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().nullable()();
  TextColumn get body => text()();
  TextColumn get noteType => text().withDefault(const Constant('text'))();
  DateTimeColumn get scheduledAt => dateTime().nullable()();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ShoppingListRow')
class ShoppingLists extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ShoppingItemRow')
class ShoppingItems extends Table {
  TextColumn get id => text()();
  TextColumn get listId => text().references(ShoppingLists, #id)();
  TextColumn get title => text()();
  RealColumn get quantity => real().nullable()();
  TextColumn get unit => text().nullable()();
  IntColumn get estimatedAmountMinor => integer().nullable()();
  IntColumn get actualAmountMinor => integer().nullable()();
  BoolColumn get isChecked => boolean().withDefault(const Constant(false))();
  DateTimeColumn get checkedAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('AccountRow')
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get accountType => text()();
  TextColumn get currencyCode => text().withDefault(const Constant('IRR'))();
  IntColumn get openingBalanceMinor => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TransactionRow')
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get destinationAccountId => text().nullable().references(Accounts, #id)();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get projectId => text().nullable()();
  IntColumn get amountMinor => integer()();
  TextColumn get currencyCode => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get occurredAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('HabitRow')
class Habits extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get recurrenceRule => text()();
  RealColumn get targetValue => real().nullable()();
  TextColumn get unit => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('HabitLogRow')
class HabitLogs extends Table {
  TextColumn get id => text()();
  TextColumn get habitId => text().references(Habits, #id)();
  DateTimeColumn get localDate => dateTime()();
  RealColumn get value => real().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('GoalRow')
class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get horizon => text()();
  DateTimeColumn get targetDate => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  RealColumn get progress => real().withDefault(const Constant(0))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {id};
}


@DataClassName('CycleLogRow')
class CycleLogs extends Table {
  TextColumn get id => text()();
  DateTimeColumn get startsOn => dateTime()();
  DateTimeColumn get endsOn => dateTime().nullable()();
  TextColumn get flowIntensity => text()();
  IntColumn get painLevel => integer().withDefault(const Constant(0))();
  TextColumn get mood => text().nullable()();
  TextColumn get symptomsJson => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ProjectRow')
class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  RealColumn get progress => real().withDefault(const Constant(0))();
  DateTimeColumn get startsOn => dateTime().nullable()();
  DateTimeColumn get dueOn => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  @override Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ProjectChecklistRow')
class ProjectChecklist extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get title => text()();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ProjectAttachmentRow')
class ProjectAttachments extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get fileName => text()();
  TextColumn get localPath => text().nullable()();
  TextColumn get remoteObjectKey => text().nullable()();
  IntColumn get sizeBytes => integer().withDefault(const Constant(0))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('RichNoteRow')
class RichNotes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().nullable()();
  TextColumn get deltaJson => text()();
  TextColumn get plainText => text()();
  TextColumn get projectId => text().nullable().references(Projects, #id)();
  TextColumn get personId => text().nullable().references(People, #id)();
  TextColumn get tagsJson => text().nullable()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  @override Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('MessageRow')
class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get personId => text().references(People, #id)();
  TextColumn get body => text()();
  BoolColumn get isOutgoing => boolean().withDefault(const Constant(true))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get sharedEntityType => text().nullable()();
  TextColumn get sharedEntityId => text().nullable()();
  TextColumn get attachmentName => text().nullable()();
  TextColumn get attachmentPath => text().nullable()();
  DateTimeColumn get readAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ShareGrantRow')
class ShareGrants extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get personId => text().references(People, #id)();
  TextColumn get permission => text().withDefault(const Constant('view'))();
  TextColumn get status => text().withDefault(const Constant('queued'))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('DeviceRow')
class Devices extends Table {
  TextColumn get id => text()();
  TextColumn get platform => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get remoteDeviceId => text().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SyncQueueRow')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get payloadJson => text()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(tables: [
  Categories, People, UserProfiles, Affairs, Medications, MedicationSchedules, MedicationLogs,
  Appointments, Birthdays, Notes, ShoppingLists, ShoppingItems, Accounts, Transactions,
  Habits, HabitLogs, Goals, CycleLogs, Projects, ProjectChecklist, ProjectAttachments,
  RichNotes, Messages, ShareGrants, Devices, SyncQueue,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 4) {
            await m.addColumn(affairs, affairs.projectId);
            await m.addColumn(transactions, transactions.projectId);
            await m.addColumn(birthdays, birthdays.personId);
            await m.addColumn(birthdays, birthdays.relationship);
            await m.createTable(projects);
            await m.createTable(projectChecklist);
            await m.createTable(projectAttachments);
            await m.createTable(richNotes);
            await m.createTable(messages);
            await m.createTable(shareGrants);
            await m.createTable(devices);
          }
          if (from < 5) {
            // Record-level sync metadata for all user data.
            await m.addColumn(categories, categories.version);
            await m.addColumn(categories, categories.deviceId);
            await m.addColumn(categories, categories.deletedAt);
            await m.addColumn(people, people.version);
            await m.addColumn(people, people.deviceId);
            await m.addColumn(people, people.deletedAt);
            await m.addColumn(userProfiles, userProfiles.version);
            await m.addColumn(userProfiles, userProfiles.deviceId);
            await m.addColumn(userProfiles, userProfiles.deletedAt);
            await m.addColumn(affairs, affairs.deviceId);
            await m.addColumn(medications, medications.version);
            await m.addColumn(medications, medications.deviceId);
            await m.addColumn(medications, medications.deletedAt);
            await m.addColumn(medicationSchedules, medicationSchedules.version);
            await m.addColumn(medicationSchedules, medicationSchedules.deviceId);
            await m.addColumn(medicationSchedules, medicationSchedules.deletedAt);
            await m.addColumn(medicationLogs, medicationLogs.version);
            await m.addColumn(medicationLogs, medicationLogs.deviceId);
            await m.addColumn(medicationLogs, medicationLogs.deletedAt);
            await m.addColumn(appointments, appointments.version);
            await m.addColumn(appointments, appointments.deviceId);
            await m.addColumn(appointments, appointments.deletedAt);
            await m.addColumn(birthdays, birthdays.version);
            await m.addColumn(birthdays, birthdays.deviceId);
            await m.addColumn(birthdays, birthdays.deletedAt);
            await m.addColumn(notes, notes.version);
            await m.addColumn(notes, notes.deviceId);
            await m.addColumn(notes, notes.deletedAt);
            await m.addColumn(shoppingLists, shoppingLists.version);
            await m.addColumn(shoppingLists, shoppingLists.deviceId);
            await m.addColumn(shoppingLists, shoppingLists.deletedAt);
            await m.addColumn(shoppingItems, shoppingItems.version);
            await m.addColumn(shoppingItems, shoppingItems.deviceId);
            await m.addColumn(shoppingItems, shoppingItems.deletedAt);
            await m.addColumn(accounts, accounts.version);
            await m.addColumn(accounts, accounts.deviceId);
            await m.addColumn(accounts, accounts.deletedAt);
            await m.addColumn(transactions, transactions.version);
            await m.addColumn(transactions, transactions.deviceId);
            await m.addColumn(transactions, transactions.deletedAt);
            await m.addColumn(habits, habits.version);
            await m.addColumn(habits, habits.deviceId);
            await m.addColumn(habits, habits.deletedAt);
            await m.addColumn(habitLogs, habitLogs.version);
            await m.addColumn(habitLogs, habitLogs.deviceId);
            await m.addColumn(habitLogs, habitLogs.deletedAt);
            await m.addColumn(goals, goals.version);
            await m.addColumn(goals, goals.deviceId);
            await m.addColumn(goals, goals.deletedAt);
            await m.addColumn(cycleLogs, cycleLogs.version);
            await m.addColumn(cycleLogs, cycleLogs.deviceId);
            await m.addColumn(cycleLogs, cycleLogs.deletedAt);

            // v4-only tables were created with the current schema when
            // upgrading from <4, so only a direct v4 -> v5 upgrade needs
            // explicit column additions.
            if (from == 4) {
              await m.addColumn(projectChecklist, projectChecklist.version);
              await m.addColumn(projectChecklist, projectChecklist.deviceId);
              await m.addColumn(projectChecklist, projectChecklist.deletedAt);
              await m.addColumn(projectAttachments, projectAttachments.version);
              await m.addColumn(projectAttachments, projectAttachments.deviceId);
              await m.addColumn(projectAttachments, projectAttachments.deletedAt);
              await m.addColumn(messages, messages.version);
              await m.addColumn(messages, messages.deviceId);
              await m.addColumn(messages, messages.deletedAt);
              await m.addColumn(shareGrants, shareGrants.version);
              await m.addColumn(shareGrants, shareGrants.deviceId);
              await m.addColumn(shareGrants, shareGrants.deletedAt);
            }
          }
        },
      );
}

LazyDatabase _openConnection() => LazyDatabase(() async {
  final directory = await getApplicationSupportDirectory();
  final file = File(p.join(directory.path, 'raha_life.sqlite'));
  return NativeDatabase.createInBackground(file);
});
