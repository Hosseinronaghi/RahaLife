import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Raha Life'**
  String get appName;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @lists.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get lists;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reports;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Affairs'**
  String get tasks;

  /// No description provided for @medications.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get medications;

  /// No description provided for @appointments.
  ///
  /// In en, this message translates to:
  /// **'Appointment'**
  String get appointments;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get notes;

  /// No description provided for @shopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get shopping;

  /// No description provided for @finance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get finance;

  /// No description provided for @habits.
  ///
  /// In en, this message translates to:
  /// **'Habit'**
  String get habits;

  /// No description provided for @goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// No description provided for @birthdays.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get birthdays;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @upNext.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get upNext;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addNewItem.
  ///
  /// In en, this message translates to:
  /// **'Add new item'**
  String get addNewItem;

  /// No description provided for @quickAdd.
  ///
  /// In en, this message translates to:
  /// **'Quick add'**
  String get quickAdd;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI assistant'**
  String get aiAssistant;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'You have no new notifications.'**
  String get noNotifications;

  /// No description provided for @noItemsToday.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled for today.'**
  String get noItemsToday;

  /// No description provided for @emptyTodayHint.
  ///
  /// In en, this message translates to:
  /// **'Add a task, event, medicine, or note for this day.'**
  String get emptyTodayHint;

  /// No description provided for @freeAiQuota.
  ///
  /// In en, this message translates to:
  /// **'Raha free AI quota'**
  String get freeAiQuota;

  /// No description provided for @personalApi.
  ///
  /// In en, this message translates to:
  /// **'Personal API key'**
  String get personalApi;

  /// No description provided for @customProvider.
  ///
  /// In en, this message translates to:
  /// **'Custom provider'**
  String get customProvider;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @markDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as done'**
  String get markDone;

  /// No description provided for @markUndone.
  ///
  /// In en, this message translates to:
  /// **'Mark as not done'**
  String get markUndone;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get selectTime;

  /// No description provided for @itemAdded.
  ///
  /// In en, this message translates to:
  /// **'The new item was added.'**
  String get itemAdded;

  /// No description provided for @itemDeleted.
  ///
  /// In en, this message translates to:
  /// **'The item was deleted.'**
  String get itemDeleted;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get requiredField;

  /// No description provided for @searchEverything.
  ///
  /// In en, this message translates to:
  /// **'Search tasks, notes, events, and more'**
  String get searchEverything;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a search term.'**
  String get searchHint;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get noSearchResults;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @persian.
  ///
  /// In en, this message translates to:
  /// **'فارسی'**
  String get persian;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get accentColor;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get fontSize;

  /// No description provided for @small.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get small;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @large.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get large;

  /// No description provided for @homeCustomization.
  ///
  /// In en, this message translates to:
  /// **'Home customization'**
  String get homeCustomization;

  /// No description provided for @showSection.
  ///
  /// In en, this message translates to:
  /// **'Show section'**
  String get showSection;

  /// No description provided for @hideSection.
  ///
  /// In en, this message translates to:
  /// **'Hide section'**
  String get hideSection;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @allFeatures.
  ///
  /// In en, this message translates to:
  /// **'All features'**
  String get allFeatures;

  /// No description provided for @personalization.
  ///
  /// In en, this message translates to:
  /// **'Personalization'**
  String get personalization;

  /// No description provided for @accountAndSync.
  ///
  /// In en, this message translates to:
  /// **'Account and sync'**
  String get accountAndSync;

  /// No description provided for @cloudBackup.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup'**
  String get cloudBackup;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages and sharing'**
  String get messages;

  /// No description provided for @widgets.
  ///
  /// In en, this message translates to:
  /// **'Widgets'**
  String get widgets;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @calendarMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get calendarMonth;

  /// No description provided for @calendarWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get calendarWeek;

  /// No description provided for @calendarDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get calendarDay;

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @noEventsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No items are scheduled for this month.'**
  String get noEventsThisMonth;

  /// No description provided for @totalItems.
  ///
  /// In en, this message translates to:
  /// **'Total items'**
  String get totalItems;

  /// No description provided for @completedItems.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedItems;

  /// No description provided for @pendingItems.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingItems;

  /// No description provided for @financialTotal.
  ///
  /// In en, this message translates to:
  /// **'Today\'s financial total'**
  String get financialTotal;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get testConnection;

  /// No description provided for @saveAiSettings.
  ///
  /// In en, this message translates to:
  /// **'Save AI settings'**
  String get saveAiSettings;

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get apiKey;

  /// No description provided for @baseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get baseUrl;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @connectionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connection successful.'**
  String get connectionSuccess;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed. Check your settings.'**
  String get connectionFailed;

  /// No description provided for @aiSubscriptionNotice.
  ///
  /// In en, this message translates to:
  /// **'ChatGPT subscriptions and OpenAI API billing are separate.'**
  String get aiSubscriptionNotice;

  /// No description provided for @rahaFreeAi.
  ///
  /// In en, this message translates to:
  /// **'Raha free AI'**
  String get rahaFreeAi;

  /// No description provided for @openAiApi.
  ///
  /// In en, this message translates to:
  /// **'OpenAI API'**
  String get openAiApi;

  /// No description provided for @geminiApi.
  ///
  /// In en, this message translates to:
  /// **'Google Gemini API'**
  String get geminiApi;

  /// No description provided for @customOpenAi.
  ///
  /// In en, this message translates to:
  /// **'OpenAI-compatible service'**
  String get customOpenAi;

  /// No description provided for @birthdayDate.
  ///
  /// In en, this message translates to:
  /// **'Birthday date'**
  String get birthdayDate;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get years;

  /// No description provided for @birthdayReminder.
  ///
  /// In en, this message translates to:
  /// **'Birthday reminder'**
  String get birthdayReminder;

  /// No description provided for @medicineTaken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get medicineTaken;

  /// No description provided for @medicineSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get medicineSkipped;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @featureNotReady.
  ///
  /// In en, this message translates to:
  /// **'This feature will be enabled in a future release.'**
  String get featureNotReady;

  /// No description provided for @globalSearch.
  ///
  /// In en, this message translates to:
  /// **'Global search'**
  String get globalSearch;

  /// No description provided for @todaySummary.
  ///
  /// In en, this message translates to:
  /// **'Day summary'**
  String get todaySummary;

  /// No description provided for @tapForDetails.
  ///
  /// In en, this message translates to:
  /// **'Tap to view details'**
  String get tapForDetails;

  /// No description provided for @entryDetails.
  ///
  /// In en, this message translates to:
  /// **'Item details'**
  String get entryDetails;

  /// No description provided for @dateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get dateAndTime;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description was added.'**
  String get noDescription;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add affair'**
  String get addTask;

  /// No description provided for @addMedicine.
  ///
  /// In en, this message translates to:
  /// **'Add medicine'**
  String get addMedicine;

  /// No description provided for @addAppointment.
  ///
  /// In en, this message translates to:
  /// **'Add appointment'**
  String get addAppointment;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get addNote;

  /// No description provided for @addShopping.
  ///
  /// In en, this message translates to:
  /// **'Add shopping item'**
  String get addShopping;

  /// No description provided for @addFinance.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get addFinance;

  /// No description provided for @addHabit.
  ///
  /// In en, this message translates to:
  /// **'Add habit'**
  String get addHabit;

  /// No description provided for @addBirthday.
  ///
  /// In en, this message translates to:
  /// **'Add birthday'**
  String get addBirthday;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved.'**
  String get settingsSaved;

  /// No description provided for @activeModules.
  ///
  /// In en, this message translates to:
  /// **'Active modules'**
  String get activeModules;

  /// No description provided for @futureModules.
  ///
  /// In en, this message translates to:
  /// **'Future features'**
  String get futureModules;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @guestMode.
  ///
  /// In en, this message translates to:
  /// **'Guest mode'**
  String get guestMode;

  /// No description provided for @syncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync status'**
  String get syncStatus;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @people.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get people;

  /// No description provided for @noPeople.
  ///
  /// In en, this message translates to:
  /// **'No people have been added yet.'**
  String get noPeople;

  /// No description provided for @addPerson.
  ///
  /// In en, this message translates to:
  /// **'Add person'**
  String get addPerson;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @relationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get relationship;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @noShoppingLists.
  ///
  /// In en, this message translates to:
  /// **'No shopping lists have been created yet.'**
  String get noShoppingLists;

  /// No description provided for @newShoppingList.
  ///
  /// In en, this message translates to:
  /// **'New shopping list'**
  String get newShoppingList;

  /// No description provided for @listName.
  ///
  /// In en, this message translates to:
  /// **'List name'**
  String get listName;

  /// No description provided for @shoppingItems.
  ///
  /// In en, this message translates to:
  /// **'Shopping items'**
  String get shoppingItems;

  /// No description provided for @oneItemPerLine.
  ///
  /// In en, this message translates to:
  /// **'Enter one item per line.'**
  String get oneItemPerLine;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get items;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copiedForSharing.
  ///
  /// In en, this message translates to:
  /// **'The list text was copied for sharing.'**
  String get copiedForSharing;

  /// No description provided for @noShoppingItems.
  ///
  /// In en, this message translates to:
  /// **'This list has no items yet.'**
  String get noShoppingItems;

  /// No description provided for @addShoppingItems.
  ///
  /// In en, this message translates to:
  /// **'Add shopping items'**
  String get addShoppingItems;

  /// No description provided for @medication.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get medication;

  /// No description provided for @noMedications.
  ///
  /// In en, this message translates to:
  /// **'No medicine has been added yet.'**
  String get noMedications;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @tablet.
  ///
  /// In en, this message translates to:
  /// **'Tablet'**
  String get tablet;

  /// No description provided for @capsule.
  ///
  /// In en, this message translates to:
  /// **'Capsule'**
  String get capsule;

  /// No description provided for @syrup.
  ///
  /// In en, this message translates to:
  /// **'Syrup'**
  String get syrup;

  /// No description provided for @drops.
  ///
  /// In en, this message translates to:
  /// **'Drops'**
  String get drops;

  /// No description provided for @injection.
  ///
  /// In en, this message translates to:
  /// **'Injection'**
  String get injection;

  /// No description provided for @cream.
  ///
  /// In en, this message translates to:
  /// **'Cream'**
  String get cream;

  /// No description provided for @inhaler.
  ///
  /// In en, this message translates to:
  /// **'Inhaler'**
  String get inhaler;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @medicineName.
  ///
  /// In en, this message translates to:
  /// **'Medicine name'**
  String get medicineName;

  /// No description provided for @medicineForm.
  ///
  /// In en, this message translates to:
  /// **'Medicine form'**
  String get medicineForm;

  /// No description provided for @dosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get dosage;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructions;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get addAccount;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get accountName;

  /// No description provided for @openingBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get openingBalance;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions have been added yet.'**
  String get noTransactions;

  /// No description provided for @financialSummary.
  ///
  /// In en, this message translates to:
  /// **'Financial summary'**
  String get financialSummary;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @transactionType.
  ///
  /// In en, this message translates to:
  /// **'Transaction type'**
  String get transactionType;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @debt.
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get debt;

  /// No description provided for @receivable.
  ///
  /// In en, this message translates to:
  /// **'Receivable'**
  String get receivable;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get saving;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @localAccount.
  ///
  /// In en, this message translates to:
  /// **'Local account'**
  String get localAccount;

  /// No description provided for @syncNextVersion.
  ///
  /// In en, this message translates to:
  /// **'Multi-device sync will be enabled in the next release.'**
  String get syncNextVersion;

  /// No description provided for @multiDevice.
  ///
  /// In en, this message translates to:
  /// **'Multiple devices'**
  String get multiDevice;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @localAccountNotice.
  ///
  /// In en, this message translates to:
  /// **'This account is currently stored on this device and is ready for the next sync release.'**
  String get localAccountNotice;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'The password must contain at least 8 characters.'**
  String get weakPassword;

  /// No description provided for @accountExists.
  ///
  /// In en, this message translates to:
  /// **'A local account already exists.'**
  String get accountExists;

  /// No description provided for @accountNotFound.
  ///
  /// In en, this message translates to:
  /// **'No local account was found.'**
  String get accountNotFound;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'The email or password is incorrect.'**
  String get invalidCredentials;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get invalidEmail;

  /// No description provided for @cycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle'**
  String get cycle;

  /// No description provided for @cyclePrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Cycle privacy'**
  String get cyclePrivacyTitle;

  /// No description provided for @cyclePrivacyText.
  ///
  /// In en, this message translates to:
  /// **'Cycle information stays on this device. This is a tracking and estimation tool, not medical advice.'**
  String get cyclePrivacyText;

  /// No description provided for @estimatedNextCycle.
  ///
  /// In en, this message translates to:
  /// **'Estimated next period'**
  String get estimatedNextCycle;

  /// No description provided for @estimateOnly.
  ///
  /// In en, this message translates to:
  /// **'This date is an estimate and not a medical certainty.'**
  String get estimateOnly;

  /// No description provided for @noCycleRecords.
  ///
  /// In en, this message translates to:
  /// **'No cycle records have been added yet.'**
  String get noCycleRecords;

  /// No description provided for @addCycleRecord.
  ///
  /// In en, this message translates to:
  /// **'Add period'**
  String get addCycleRecord;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get endDate;

  /// No description provided for @endDateOptional.
  ///
  /// In en, this message translates to:
  /// **'End date (optional)'**
  String get endDateOptional;

  /// No description provided for @flowIntensity.
  ///
  /// In en, this message translates to:
  /// **'Flow intensity'**
  String get flowIntensity;

  /// No description provided for @flowLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get flowLight;

  /// No description provided for @flowMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get flowMedium;

  /// No description provided for @flowHeavy.
  ///
  /// In en, this message translates to:
  /// **'Heavy'**
  String get flowHeavy;

  /// No description provided for @painLevel.
  ///
  /// In en, this message translates to:
  /// **'Pain level'**
  String get painLevel;

  /// No description provided for @mood.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get mood;

  /// No description provided for @moodCalm.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get moodCalm;

  /// No description provided for @moodSensitive.
  ///
  /// In en, this message translates to:
  /// **'Sensitive'**
  String get moodSensitive;

  /// No description provided for @moodLow.
  ///
  /// In en, this message translates to:
  /// **'Low energy'**
  String get moodLow;

  /// No description provided for @moodEnergetic.
  ///
  /// In en, this message translates to:
  /// **'Energetic'**
  String get moodEnergetic;

  /// No description provided for @moodIrritable.
  ///
  /// In en, this message translates to:
  /// **'Irritable'**
  String get moodIrritable;

  /// No description provided for @affairType.
  ///
  /// In en, this message translates to:
  /// **'Affair type'**
  String get affairType;

  /// No description provided for @affairPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get affairPersonal;

  /// No description provided for @affairWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get affairWork;

  /// No description provided for @affairAdministrative.
  ///
  /// In en, this message translates to:
  /// **'Administrative'**
  String get affairAdministrative;

  /// No description provided for @affairFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Follow-up'**
  String get affairFollowUp;

  /// No description provided for @affairMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get affairMedical;

  /// No description provided for @affairLaboratory.
  ///
  /// In en, this message translates to:
  /// **'Laboratory'**
  String get affairLaboratory;

  /// No description provided for @affairPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment and renewal'**
  String get affairPayment;

  /// No description provided for @affairStudy.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get affairStudy;

  /// No description provided for @affairCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get affairCustom;

  /// No description provided for @appointmentType.
  ///
  /// In en, this message translates to:
  /// **'Appointment format'**
  String get appointmentType;

  /// No description provided for @appointmentMeeting.
  ///
  /// In en, this message translates to:
  /// **'Meeting'**
  String get appointmentMeeting;

  /// No description provided for @appointmentCafe.
  ///
  /// In en, this message translates to:
  /// **'Cafe'**
  String get appointmentCafe;

  /// No description provided for @appointmentGathering.
  ///
  /// In en, this message translates to:
  /// **'Gathering'**
  String get appointmentGathering;

  /// No description provided for @appointmentInPerson.
  ///
  /// In en, this message translates to:
  /// **'In-person session'**
  String get appointmentInPerson;

  /// No description provided for @appointmentPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone call'**
  String get appointmentPhone;

  /// No description provided for @appointmentOnline.
  ///
  /// In en, this message translates to:
  /// **'Online session'**
  String get appointmentOnline;

  /// No description provided for @appointmentParty.
  ///
  /// In en, this message translates to:
  /// **'Party'**
  String get appointmentParty;

  /// No description provided for @appointmentCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get appointmentCustom;

  /// No description provided for @relatedPerson.
  ///
  /// In en, this message translates to:
  /// **'Related person'**
  String get relatedPerson;

  /// No description provided for @noRelatedPerson.
  ///
  /// In en, this message translates to:
  /// **'No related person'**
  String get noRelatedPerson;

  /// No description provided for @affairShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get affairShopping;

  /// No description provided for @affairBill.
  ///
  /// In en, this message translates to:
  /// **'Bill and payment'**
  String get affairBill;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @reminderHint.
  ///
  /// In en, this message translates to:
  /// **'Show a notification or alarm at the selected time.'**
  String get reminderHint;

  /// No description provided for @reminderMode.
  ///
  /// In en, this message translates to:
  /// **'Reminder type'**
  String get reminderMode;

  /// No description provided for @notificationMode.
  ///
  /// In en, this message translates to:
  /// **'Gentle notification'**
  String get notificationMode;

  /// No description provided for @alarmMode.
  ///
  /// In en, this message translates to:
  /// **'Sound alarm'**
  String get alarmMode;

  /// No description provided for @remindBefore.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get remindBefore;

  /// No description provided for @atEventTime.
  ///
  /// In en, this message translates to:
  /// **'At event time'**
  String get atEventTime;

  /// No description provided for @oneDayBefore.
  ///
  /// In en, this message translates to:
  /// **'One day before'**
  String get oneDayBefore;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @repeatOnce.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get repeatOnce;

  /// No description provided for @repeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get repeatDaily;

  /// No description provided for @repeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get repeatWeekly;

  /// No description provided for @repeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get repeatMonthly;

  /// No description provided for @repeatYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get repeatYearly;

  /// No description provided for @reminderDue.
  ///
  /// In en, this message translates to:
  /// **'This item is due.'**
  String get reminderDue;

  /// No description provided for @customizeModuleOrder.
  ///
  /// In en, this message translates to:
  /// **'Module layout'**
  String get customizeModuleOrder;

  /// No description provided for @dragToReorderModules.
  ///
  /// In en, this message translates to:
  /// **'Drag modules to reorder them. You can also hide individual modules.'**
  String get dragToReorderModules;

  /// No description provided for @restoreDefaultOrder.
  ///
  /// In en, this message translates to:
  /// **'Restore default order'**
  String get restoreDefaultOrder;

  /// No description provided for @noVisibleModules.
  ///
  /// In en, this message translates to:
  /// **'All modules are hidden.'**
  String get noVisibleModules;

  /// No description provided for @notificationsAndAlarms.
  ///
  /// In en, this message translates to:
  /// **'Notifications and alarms'**
  String get notificationsAndAlarms;

  /// No description provided for @notificationsPermissionHint.
  ///
  /// In en, this message translates to:
  /// **'Enable notification permission to receive reminders.'**
  String get notificationsPermissionHint;

  /// No description provided for @notificationPermissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Notification permission enabled.'**
  String get notificationPermissionGranted;

  /// No description provided for @notificationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission was not granted.'**
  String get notificationPermissionDenied;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get enableNotifications;

  /// No description provided for @testNotification.
  ///
  /// In en, this message translates to:
  /// **'Test notification'**
  String get testNotification;

  /// No description provided for @testAlarm.
  ///
  /// In en, this message translates to:
  /// **'Test alarm'**
  String get testAlarm;

  /// No description provided for @testReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Raha Life test reminder'**
  String get testReminderTitle;

  /// No description provided for @testReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Notifications are working correctly.'**
  String get testReminderBody;

  /// No description provided for @testAlarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Raha Life test alarm'**
  String get testAlarmTitle;

  /// No description provided for @testAlarmBody.
  ///
  /// In en, this message translates to:
  /// **'Check the alarm sound and vibration.'**
  String get testAlarmBody;

  /// No description provided for @storeOrLocation.
  ///
  /// In en, this message translates to:
  /// **'Store or location'**
  String get storeOrLocation;

  /// No description provided for @linkShoppingToAffair.
  ///
  /// In en, this message translates to:
  /// **'Create shopping affair'**
  String get linkShoppingToAffair;

  /// No description provided for @linkShoppingToAffairHint.
  ///
  /// In en, this message translates to:
  /// **'Link this list to a scheduled affair so it can remind you at the selected time.'**
  String get linkShoppingToAffairHint;

  /// No description provided for @shoppingAffairDescription.
  ///
  /// In en, this message translates to:
  /// **'Affair linked to a shopping list'**
  String get shoppingAffairDescription;

  /// No description provided for @purchaseDate.
  ///
  /// In en, this message translates to:
  /// **'Purchase date'**
  String get purchaseDate;

  /// No description provided for @openLinkedAffair.
  ///
  /// In en, this message translates to:
  /// **'Open linked affair'**
  String get openLinkedAffair;

  /// No description provided for @bill.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get bill;

  /// No description provided for @billType.
  ///
  /// In en, this message translates to:
  /// **'Bill type'**
  String get billType;

  /// No description provided for @billIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Bill identifier'**
  String get billIdentifier;

  /// No description provided for @paymentIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Payment identifier'**
  String get paymentIdentifier;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @markPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as paid'**
  String get markPaid;

  /// No description provided for @markUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as unpaid'**
  String get markUnpaid;

  /// No description provided for @unpaidBills.
  ///
  /// In en, this message translates to:
  /// **'Unpaid bills'**
  String get unpaidBills;

  /// No description provided for @billReminderBody.
  ///
  /// In en, this message translates to:
  /// **'A bill payment deadline is approaching.'**
  String get billReminderBody;

  /// No description provided for @categoryBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get categoryBills;

  /// No description provided for @categoryRentHousing.
  ///
  /// In en, this message translates to:
  /// **'Rent and housing'**
  String get categoryRentHousing;

  /// No description provided for @categoryGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get categoryGroceries;

  /// No description provided for @categoryRestaurantCafe.
  ///
  /// In en, this message translates to:
  /// **'Restaurant and cafe'**
  String get categoryRestaurantCafe;

  /// No description provided for @categoryTransportation.
  ///
  /// In en, this message translates to:
  /// **'Transportation'**
  String get categoryTransportation;

  /// No description provided for @categoryFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get categoryFuel;

  /// No description provided for @categoryHealthcare.
  ///
  /// In en, this message translates to:
  /// **'Healthcare'**
  String get categoryHealthcare;

  /// No description provided for @categoryMedicine.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get categoryMedicine;

  /// No description provided for @categoryDailyShopping.
  ///
  /// In en, this message translates to:
  /// **'Daily shopping'**
  String get categoryDailyShopping;

  /// No description provided for @categoryEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get categoryEducation;

  /// No description provided for @categoryEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get categoryEntertainment;

  /// No description provided for @categoryTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get categoryTravel;

  /// No description provided for @categoryClothing.
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get categoryClothing;

  /// No description provided for @categoryInternetPhone.
  ///
  /// In en, this message translates to:
  /// **'Internet and phone'**
  String get categoryInternetPhone;

  /// No description provided for @categoryInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get categoryInsurance;

  /// No description provided for @categoryTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get categoryTax;

  /// No description provided for @categoryLoanInstallment.
  ///
  /// In en, this message translates to:
  /// **'Loans and installments'**
  String get categoryLoanInstallment;

  /// No description provided for @categorySubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get categorySubscriptions;

  /// No description provided for @categoryRepairs.
  ///
  /// In en, this message translates to:
  /// **'Repairs'**
  String get categoryRepairs;

  /// No description provided for @categoryGift.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get categoryGift;

  /// No description provided for @categoryFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get categoryFamily;

  /// No description provided for @categoryPets.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get categoryPets;

  /// No description provided for @categoryCharity.
  ///
  /// In en, this message translates to:
  /// **'Charity'**
  String get categoryCharity;

  /// No description provided for @billElectricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get billElectricity;

  /// No description provided for @billWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get billWater;

  /// No description provided for @billGas.
  ///
  /// In en, this message translates to:
  /// **'Gas'**
  String get billGas;

  /// No description provided for @billTelephone.
  ///
  /// In en, this message translates to:
  /// **'Telephone'**
  String get billTelephone;

  /// No description provided for @billInternet.
  ///
  /// In en, this message translates to:
  /// **'Internet'**
  String get billInternet;

  /// No description provided for @billBuildingCharge.
  ///
  /// In en, this message translates to:
  /// **'Building charge'**
  String get billBuildingCharge;

  /// No description provided for @minutesBefore.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes before'**
  String minutesBefore(int count);

  /// No description provided for @hoursBefore.
  ///
  /// In en, this message translates to:
  /// **'{count} hours before'**
  String hoursBefore(int count);

  /// No description provided for @daysBefore.
  ///
  /// In en, this message translates to:
  /// **'{count} days before'**
  String daysBefore(int count);

  /// No description provided for @shoppingReminderBody.
  ///
  /// In en, this message translates to:
  /// **'You have {count} items in this shopping list.'**
  String shoppingReminderBody(int count);

  /// No description provided for @openLinkedShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Open linked shopping list'**
  String get openLinkedShoppingList;

  /// No description provided for @medicationReminderBody.
  ///
  /// In en, this message translates to:
  /// **'It is time to take your medicine.'**
  String get medicationReminderBody;

  /// No description provided for @dailyMedicationReminder.
  ///
  /// In en, this message translates to:
  /// **'Remind every day at the selected time'**
  String get dailyMedicationReminder;

  /// No description provided for @nextCycleReminder.
  ///
  /// In en, this message translates to:
  /// **'Next cycle reminder'**
  String get nextCycleReminder;

  /// No description provided for @nextCycleReminderHint.
  ///
  /// In en, this message translates to:
  /// **'Remind me based on the estimated next start date'**
  String get nextCycleReminderHint;

  /// No description provided for @cycleReminderBody.
  ///
  /// In en, this message translates to:
  /// **'The estimated next cycle is approaching. This date is only an estimate.'**
  String get cycleReminderBody;

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get projects;

  /// No description provided for @addProject.
  ///
  /// In en, this message translates to:
  /// **'Add project'**
  String get addProject;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get projectName;

  /// No description provided for @projectDescription.
  ///
  /// In en, this message translates to:
  /// **'Project description'**
  String get projectDescription;

  /// No description provided for @projectStatus.
  ///
  /// In en, this message translates to:
  /// **'Project status'**
  String get projectStatus;

  /// No description provided for @projectActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get projectActive;

  /// No description provided for @projectPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get projectPaused;

  /// No description provided for @projectDone.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get projectDone;

  /// No description provided for @projectArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get projectArchived;

  /// No description provided for @projectStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get projectStart;

  /// No description provided for @projectDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get projectDue;

  /// No description provided for @projectProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get projectProgress;

  /// No description provided for @projectOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get projectOverview;

  /// No description provided for @projectAffairs.
  ///
  /// In en, this message translates to:
  /// **'Affairs'**
  String get projectAffairs;

  /// No description provided for @projectNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get projectNotes;

  /// No description provided for @projectChecklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get projectChecklist;

  /// No description provided for @projectFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get projectFiles;

  /// No description provided for @projectPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get projectPeople;

  /// No description provided for @projectFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get projectFinance;

  /// No description provided for @noProjects.
  ///
  /// In en, this message translates to:
  /// **'No projects yet.'**
  String get noProjects;

  /// No description provided for @addChecklistItem.
  ///
  /// In en, this message translates to:
  /// **'Add checklist item'**
  String get addChecklistItem;

  /// No description provided for @attachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get attachment;

  /// No description provided for @addAttachment.
  ///
  /// In en, this message translates to:
  /// **'Add file'**
  String get addAttachment;

  /// No description provided for @removeAttachment.
  ///
  /// In en, this message translates to:
  /// **'Remove file'**
  String get removeAttachment;

  /// No description provided for @projectLinkedItems.
  ///
  /// In en, this message translates to:
  /// **'Linked items'**
  String get projectLinkedItems;

  /// No description provided for @openProject.
  ///
  /// In en, this message translates to:
  /// **'Open project'**
  String get openProject;

  /// No description provided for @professionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Professional notes'**
  String get professionalNotes;

  /// No description provided for @newNote.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get newNote;

  /// No description provided for @noteTitle.
  ///
  /// In en, this message translates to:
  /// **'Note title'**
  String get noteTitle;

  /// No description provided for @noteBody.
  ///
  /// In en, this message translates to:
  /// **'Note body'**
  String get noteBody;

  /// No description provided for @pinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get pinned;

  /// No description provided for @pinNote.
  ///
  /// In en, this message translates to:
  /// **'Pin note'**
  String get pinNote;

  /// No description provided for @unpinNote.
  ///
  /// In en, this message translates to:
  /// **'Unpin note'**
  String get unpinNote;

  /// No description provided for @archiveNote.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archiveNote;

  /// No description provided for @noteTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get noteTags;

  /// No description provided for @richText.
  ///
  /// In en, this message translates to:
  /// **'Rich text'**
  String get richText;

  /// No description provided for @noteProject.
  ///
  /// In en, this message translates to:
  /// **'Linked project'**
  String get noteProject;

  /// No description provided for @noNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes yet.'**
  String get noNotes;

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get editNote;

  /// No description provided for @noteSaved.
  ///
  /// In en, this message translates to:
  /// **'Note saved.'**
  String get noteSaved;

  /// No description provided for @medicationCatalog.
  ///
  /// In en, this message translates to:
  /// **'Medication catalog'**
  String get medicationCatalog;

  /// No description provided for @searchMedicine.
  ///
  /// In en, this message translates to:
  /// **'Search medicine'**
  String get searchMedicine;

  /// No description provided for @genericName.
  ///
  /// In en, this message translates to:
  /// **'Generic name'**
  String get genericName;

  /// No description provided for @brandName.
  ///
  /// In en, this message translates to:
  /// **'Brand name'**
  String get brandName;

  /// No description provided for @therapeuticGroup.
  ///
  /// In en, this message translates to:
  /// **'Therapeutic group'**
  String get therapeuticGroup;

  /// No description provided for @commonUse.
  ///
  /// In en, this message translates to:
  /// **'Common use'**
  String get commonUse;

  /// No description provided for @recordingOnly.
  ///
  /// In en, this message translates to:
  /// **'This catalog is only for selecting and recording a medicine you already use. It is not treatment advice.'**
  String get recordingOnly;

  /// No description provided for @reasonForUse.
  ///
  /// In en, this message translates to:
  /// **'Reason for use'**
  String get reasonForUse;

  /// No description provided for @courseType.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get courseType;

  /// No description provided for @courseContinuous.
  ///
  /// In en, this message translates to:
  /// **'Continuous'**
  String get courseContinuous;

  /// No description provided for @courseFixed.
  ///
  /// In en, this message translates to:
  /// **'Until a date'**
  String get courseFixed;

  /// No description provided for @courseDays.
  ///
  /// In en, this message translates to:
  /// **'Fixed number of days'**
  String get courseDays;

  /// No description provided for @courseAsNeeded.
  ///
  /// In en, this message translates to:
  /// **'As needed'**
  String get courseAsNeeded;

  /// No description provided for @courseStart.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get courseStart;

  /// No description provided for @courseEnd.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get courseEnd;

  /// No description provided for @courseLengthDays.
  ///
  /// In en, this message translates to:
  /// **'Number of days'**
  String get courseLengthDays;

  /// No description provided for @medicationFinished.
  ///
  /// In en, this message translates to:
  /// **'Course finished'**
  String get medicationFinished;

  /// No description provided for @selectFromCatalog.
  ///
  /// In en, this message translates to:
  /// **'Choose from catalog'**
  String get selectFromCatalog;

  /// No description provided for @manualMedicine.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get manualMedicine;

  /// No description provided for @birthdayRelationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get birthdayRelationship;

  /// No description provided for @selectPersonOptional.
  ///
  /// In en, this message translates to:
  /// **'Select person (optional)'**
  String get selectPersonOptional;

  /// No description provided for @shareWithPeople.
  ///
  /// In en, this message translates to:
  /// **'Share with people'**
  String get shareWithPeople;

  /// No description provided for @sharePermission.
  ///
  /// In en, this message translates to:
  /// **'Permission'**
  String get sharePermission;

  /// No description provided for @permissionView.
  ///
  /// In en, this message translates to:
  /// **'View only'**
  String get permissionView;

  /// No description provided for @permissionCheck.
  ///
  /// In en, this message translates to:
  /// **'Check/interact'**
  String get permissionCheck;

  /// No description provided for @permissionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get permissionEdit;

  /// No description provided for @sharedPeople.
  ///
  /// In en, this message translates to:
  /// **'People with access'**
  String get sharedPeople;

  /// No description provided for @internalShare.
  ///
  /// In en, this message translates to:
  /// **'Internal share'**
  String get internalShare;

  /// No description provided for @systemShare.
  ///
  /// In en, this message translates to:
  /// **'Share with other apps'**
  String get systemShare;

  /// No description provided for @shareQueued.
  ///
  /// In en, this message translates to:
  /// **'Share queued for synchronization.'**
  String get shareQueued;

  /// No description provided for @messagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesTitle;

  /// No description provided for @newConversation.
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get newConversation;

  /// No description provided for @selectPersonToMessage.
  ///
  /// In en, this message translates to:
  /// **'Select a person to message.'**
  String get selectPersonToMessage;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Write a message…'**
  String get typeMessage;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @pendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get pendingSync;

  /// No description provided for @deliveredLocal.
  ///
  /// In en, this message translates to:
  /// **'Saved locally'**
  String get deliveredLocal;

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet.'**
  String get noMessages;

  /// No description provided for @messageOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Messages are stored offline for now. Delivery between users starts after a compatible collaboration service is selected and enabled.'**
  String get messageOfflineHint;

  /// No description provided for @shareItemInMessage.
  ///
  /// In en, this message translates to:
  /// **'Send an app item'**
  String get shareItemInMessage;

  /// No description provided for @syncCenter.
  ///
  /// In en, this message translates to:
  /// **'Sync center'**
  String get syncCenter;

  /// No description provided for @syncProvider.
  ///
  /// In en, this message translates to:
  /// **'Sync provider'**
  String get syncProvider;

  /// No description provided for @rahaCloud.
  ///
  /// In en, this message translates to:
  /// **'Raha Sync'**
  String get rahaCloud;

  /// No description provided for @googleDrive.
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get googleDrive;

  /// No description provided for @dropbox.
  ///
  /// In en, this message translates to:
  /// **'Dropbox'**
  String get dropbox;

  /// No description provided for @oneDrive.
  ///
  /// In en, this message translates to:
  /// **'OneDrive'**
  String get oneDrive;

  /// No description provided for @localBackup.
  ///
  /// In en, this message translates to:
  /// **'Local backup only'**
  String get localBackup;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @lastSync.
  ///
  /// In en, this message translates to:
  /// **'Last sync'**
  String get lastSync;

  /// No description provided for @neverSynced.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get neverSynced;

  /// No description provided for @syncReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to sync'**
  String get syncReady;

  /// No description provided for @syncNeedsServer.
  ///
  /// In en, this message translates to:
  /// **'Record-level multi-device sync needs a compatible service such as your own Raha Sync Server; backups can work without any Raha-owned server and use your own storage.'**
  String get syncNeedsServer;

  /// No description provided for @personalCloudHint.
  ///
  /// In en, this message translates to:
  /// **'Google Drive, Dropbox, and OneDrive are prepared for personal backup/sync; OAuth connection becomes active when service credentials are configured.'**
  String get personalCloudHint;

  /// No description provided for @devices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get devices;

  /// No description provided for @thisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get thisDevice;

  /// No description provided for @androidPlatform.
  ///
  /// In en, this message translates to:
  /// **'Android'**
  String get androidPlatform;

  /// No description provided for @iosPlatform.
  ///
  /// In en, this message translates to:
  /// **'iPhone / iOS'**
  String get iosPlatform;

  /// No description provided for @windowsPlatform.
  ///
  /// In en, this message translates to:
  /// **'Windows'**
  String get windowsPlatform;

  /// No description provided for @macosPlatform.
  ///
  /// In en, this message translates to:
  /// **'macOS'**
  String get macosPlatform;

  /// No description provided for @linuxPlatform.
  ///
  /// In en, this message translates to:
  /// **'Linux'**
  String get linuxPlatform;

  /// No description provided for @webPlatform.
  ///
  /// In en, this message translates to:
  /// **'Web'**
  String get webPlatform;

  /// No description provided for @pendingChanges.
  ///
  /// In en, this message translates to:
  /// **'Pending changes'**
  String get pendingChanges;

  /// No description provided for @conflicts.
  ///
  /// In en, this message translates to:
  /// **'Conflicts'**
  String get conflicts;

  /// No description provided for @syncMode.
  ///
  /// In en, this message translates to:
  /// **'Sync mode'**
  String get syncMode;

  /// No description provided for @syncAllDevices.
  ///
  /// In en, this message translates to:
  /// **'All my devices'**
  String get syncAllDevices;

  /// No description provided for @backupOnly.
  ///
  /// In en, this message translates to:
  /// **'Backup only'**
  String get backupOnly;

  /// No description provided for @widgetCenter.
  ///
  /// In en, this message translates to:
  /// **'Widgets'**
  String get widgetCenter;

  /// No description provided for @todayWidget.
  ///
  /// In en, this message translates to:
  /// **'Today widget'**
  String get todayWidget;

  /// No description provided for @widgetTodaySummary.
  ///
  /// In en, this message translates to:
  /// **'Today summary'**
  String get widgetTodaySummary;

  /// No description provided for @widgetPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Widget privacy'**
  String get widgetPrivacy;

  /// No description provided for @hideSensitiveWidgetData.
  ///
  /// In en, this message translates to:
  /// **'Hide sensitive data on widgets'**
  String get hideSensitiveWidgetData;

  /// No description provided for @refreshWidget.
  ///
  /// In en, this message translates to:
  /// **'Refresh widget'**
  String get refreshWidget;

  /// No description provided for @widgetUpdated.
  ///
  /// In en, this message translates to:
  /// **'Widget updated.'**
  String get widgetUpdated;

  /// No description provided for @androidWidgetReady.
  ///
  /// In en, this message translates to:
  /// **'Android home screen widget is enabled.'**
  String get androidWidgetReady;

  /// No description provided for @iosWidgetNeedsTarget.
  ///
  /// In en, this message translates to:
  /// **'The iOS data bridge is ready; a Widget Extension must be added when building iOS.'**
  String get iosWidgetNeedsTarget;

  /// No description provided for @desktopQuickPanel.
  ///
  /// In en, this message translates to:
  /// **'Desktop quick panel'**
  String get desktopQuickPanel;

  /// No description provided for @widgetNotSupported.
  ///
  /// In en, this message translates to:
  /// **'System widgets are not supported on this platform yet.'**
  String get widgetNotSupported;

  /// No description provided for @inbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inbox;

  /// No description provided for @quickCapture.
  ///
  /// In en, this message translates to:
  /// **'Quick capture'**
  String get quickCapture;

  /// No description provided for @captureHint.
  ///
  /// In en, this message translates to:
  /// **'Write anything quickly, then convert it to an affair, appointment, shopping item, note, or project.'**
  String get captureHint;

  /// No description provided for @noInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox is empty.'**
  String get noInbox;

  /// No description provided for @convertTo.
  ///
  /// In en, this message translates to:
  /// **'Convert to'**
  String get convertTo;

  /// No description provided for @convertDone.
  ///
  /// In en, this message translates to:
  /// **'Item converted.'**
  String get convertDone;

  /// No description provided for @cycleToday.
  ///
  /// In en, this message translates to:
  /// **'Today in your cycle'**
  String get cycleToday;

  /// No description provided for @cycleDay.
  ///
  /// In en, this message translates to:
  /// **'Cycle day'**
  String get cycleDay;

  /// No description provided for @cycleInsights.
  ///
  /// In en, this message translates to:
  /// **'Cycle overview'**
  String get cycleInsights;

  /// No description provided for @quickLog.
  ///
  /// In en, this message translates to:
  /// **'Quick log'**
  String get quickLog;

  /// No description provided for @symptoms.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get symptoms;

  /// No description provided for @cyclePrivateHint.
  ///
  /// In en, this message translates to:
  /// **'You can limit sensitive cycle information on the home screen and widgets.'**
  String get cyclePrivateHint;

  /// No description provided for @estimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated'**
  String get estimated;

  /// No description provided for @sharedSpaces.
  ///
  /// In en, this message translates to:
  /// **'Shared spaces'**
  String get sharedSpaces;

  /// No description provided for @sharedSpaceHint.
  ///
  /// In en, this message translates to:
  /// **'Shared-space infrastructure for shopping, projects, affairs and notes is ready; cross-user synchronization starts after a compatible collaboration service is enabled.'**
  String get sharedSpaceHint;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @noItems.
  ///
  /// In en, this message translates to:
  /// **'No items yet.'**
  String get noItems;

  /// No description provided for @sharedShoppingAccess.
  ///
  /// In en, this message translates to:
  /// **'Shared shopping access'**
  String get sharedShoppingAccess;

  /// No description provided for @sharingSaved.
  ///
  /// In en, this message translates to:
  /// **'Sharing settings saved.'**
  String get sharingSaved;

  /// No description provided for @syncPrototypeNote.
  ///
  /// In en, this message translates to:
  /// **'Raha Sync is local-first and provider-based. Local backup and personal storage targets are usable now; full record sync for every module is enabled after the Drift repository migration.'**
  String get syncPrototypeNote;

  /// No description provided for @localQueue.
  ///
  /// In en, this message translates to:
  /// **'Local queue'**
  String get localQueue;

  /// No description provided for @allPlatforms.
  ///
  /// In en, this message translates to:
  /// **'Android, iPhone, Windows, macOS, Linux and Web'**
  String get allPlatforms;

  /// No description provided for @widgetPlatformHint.
  ///
  /// In en, this message translates to:
  /// **'Android generates seven native widgets in CI (Today, Affairs, Medicine, Appointment, Shopping, Birthday, and Quick Add). iOS has the Flutter data bridge but still needs a native WidgetKit Extension target; desktop quick panels remain a later native step.'**
  String get widgetPlatformHint;

  /// No description provided for @kilobytes.
  ///
  /// In en, this message translates to:
  /// **'KB'**
  String get kilobytes;

  /// No description provided for @viewOnly.
  ///
  /// In en, this message translates to:
  /// **'View only'**
  String get viewOnly;

  /// No description provided for @canCheckItems.
  ///
  /// In en, this message translates to:
  /// **'Can check items'**
  String get canCheckItems;

  /// No description provided for @canEdit.
  ///
  /// In en, this message translates to:
  /// **'Can edit'**
  String get canEdit;

  /// No description provided for @cyclePredictionHint.
  ///
  /// In en, this message translates to:
  /// **'Predictions are approximate and based on recorded cycles.'**
  String get cyclePredictionHint;

  /// No description provided for @tapWidgetToAdd.
  ///
  /// In en, this message translates to:
  /// **'On Android, tap a widget below to request adding it to the home screen.'**
  String get tapWidgetToAdd;

  /// No description provided for @widgetPinRequested.
  ///
  /// In en, this message translates to:
  /// **'Widget add request sent.'**
  String get widgetPinRequested;

  /// No description provided for @saveSyncCheckpoint.
  ///
  /// In en, this message translates to:
  /// **'Save local sync checkpoint'**
  String get saveSyncCheckpoint;

  /// No description provided for @localCheckpointSaved.
  ///
  /// In en, this message translates to:
  /// **'Local sync checkpoint saved.'**
  String get localCheckpointSaved;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
