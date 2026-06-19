import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('de'),
    Locale('en'),
    Locale('es')
  ];

  /// Title of the daily goal section on the home page
  ///
  /// In en, this message translates to:
  /// **'Today\'s Goal'**
  String get todaysGoal;

  /// Empty-state text shown in the today's goal section when no goal is scheduled for the current day
  ///
  /// In en, this message translates to:
  /// **'There\'s no daily goal today'**
  String get noDailyGoalToday;

  /// Title of the weekly goal widget in the home app bar
  ///
  /// In en, this message translates to:
  /// **'Weekly Goal'**
  String get weeklyGoal;

  /// Section header for the list of diary/survey entries due today
  ///
  /// In en, this message translates to:
  /// **'Today\'s Entries'**
  String get todaysEntries;

  /// Label for the Study tab in the bottom navigation bar
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get study;

  /// Label for the History tab in the bottom navigation bar
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// Label for the Settings tab in the bottom navigation bar
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Heading for compensation earned so far on the incentives screen
  ///
  /// In en, this message translates to:
  /// **'Incentives Earned'**
  String get incentivesEarned;

  /// Section title on the incentives screen
  ///
  /// In en, this message translates to:
  /// **'Compensation Details'**
  String get compensationDetails;

  /// Expandable help link on the incentives screen
  ///
  /// In en, this message translates to:
  /// **'How are incentives calculated?'**
  String get howAreIncentivesCalculated;

  /// Label for the total number of entries in the incentives breakdown
  ///
  /// In en, this message translates to:
  /// **'Total Entries'**
  String get totalEntries;

  /// Fragment shown before a per-entry incentive amount (see concatenation note)
  ///
  /// In en, this message translates to:
  /// **'Each'**
  String get each;

  /// Label for the total compensation amount
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// Fragment shown before the entry count required to earn a completion bonus
  ///
  /// In en, this message translates to:
  /// **'Bonus When You Complete'**
  String get bonusText;

  /// title for the study calendar modal
  ///
  /// In en, this message translates to:
  /// **'Study Calendar'**
  String get studyCalendar;

  /// Past entries
  ///
  /// In en, this message translates to:
  /// **'Past Entries'**
  String get pastEntries;

  /// Today's entries for diaries
  ///
  /// In en, this message translates to:
  /// **'Today\'s entries'**
  String get todaysCalendarEntries;

  /// diaries which are coming up the next day and beyond
  ///
  /// In en, this message translates to:
  /// **'Upcoming entries'**
  String get upComingEntries;

  /// get your bonus text
  ///
  /// In en, this message translates to:
  /// **'Get Your Bonus'**
  String get getYourBonus;

  /// total completion text for the incentive page
  ///
  /// In en, this message translates to:
  /// **'Total Completion'**
  String get totalCompletion;

  /// available until text for diary validity
  ///
  /// In en, this message translates to:
  /// **'Available Until:'**
  String get availableUntil;

  /// when the diary open
  ///
  /// In en, this message translates to:
  /// **'Opens At:'**
  String get opensAt;
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
      <String>['de', 'en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
