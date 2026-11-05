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

  /// Title of the welcome screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to Fabla!'**
  String get welcomeToFabla;

  /// Description of fabla
  ///
  /// In en, this message translates to:
  /// **'Fabla is a tool for daily experience research, audio diaries and more'**
  String get fableLoginDescription;

  /// study String label
  ///
  /// In en, this message translates to:
  /// **'Study String'**
  String get studyID;

  /// No description provided for @enterYourStudyString.
  ///
  /// In en, this message translates to:
  /// **'Enter the study string...'**
  String get enterYourStudyString;

  /// verifying study id
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get verifyingStudyID;

  /// loading text
  ///
  /// In en, this message translates to:
  /// **'Hang tight while we verify the study string - \nalmost there!'**
  String get hangOnTight;

  /// Title of the study information section
  ///
  /// In en, this message translates to:
  /// **'Study Information'**
  String get studyInformation;

  /// Description of the study information
  ///
  /// In en, this message translates to:
  /// **'Below is the study information associated with this study string.'**
  String get belowIsInformation;

  /// Name of the study
  ///
  /// In en, this message translates to:
  /// **'Study Name'**
  String get studyName;

  /// Duration of the study
  ///
  /// In en, this message translates to:
  /// **'Study Duration'**
  String get studyDuration;

  /// Name of the researcher
  ///
  /// In en, this message translates to:
  /// **'Researcher Name'**
  String get researcherName;

  /// Button to view study details
  ///
  /// In en, this message translates to:
  /// **'View Study Details'**
  String get viewStudyDetails;

  /// Button to confirm study joining
  ///
  /// In en, this message translates to:
  /// **'Confirm Joining'**
  String get confirmJoining;

  /// Button to take me back
  ///
  /// In en, this message translates to:
  /// **'This isn’t right - take me back'**
  String get thisIsntRight;

  /// Title of the participant login screen
  ///
  /// In en, this message translates to:
  /// **'Participant Login'**
  String get participantLogin;

  /// Description of the participant login screen
  ///
  /// In en, this message translates to:
  /// **'Please enter the participant ID you were given by the researchers here.'**
  String get participantLoginDescription;

  /// Participant ID label
  ///
  /// In en, this message translates to:
  /// **'Participant ID'**
  String get participantID;

  /// Participant ID text field placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your participant ID...'**
  String get enterYourParticipantID;

  /// Login button
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Need help with the participant ID?
  ///
  /// In en, this message translates to:
  /// **'Need help with the participant ID?'**
  String get needHelpWithParticipantID;

  /// Need help with the study String?
  ///
  /// In en, this message translates to:
  /// **'Need help with the study String?'**
  String get needHelpWithStudyID;

  /// Contact us button
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @studyStringError.
  ///
  /// In en, this message translates to:
  /// **'Oops! We cannot access your study without a valid Study String.'**
  String get studyStringError;

  /// No description provided for @your.
  ///
  /// In en, this message translates to:
  /// **'Your'**
  String get your;

  /// No description provided for @alphanumericcode.
  ///
  /// In en, this message translates to:
  /// **'is an alphanumeric code (e.g. ABC123) shared by your researcher to grant you access to your study on Fabla'**
  String get alphanumericcode;

  /// No description provided for @ifYouNeedHelpPopUP.
  ///
  /// In en, this message translates to:
  /// **'If you need help with your'**
  String get ifYouNeedHelpPopUP;

  /// No description provided for @youMay.
  ///
  /// In en, this message translates to:
  /// **'you may'**
  String get youMay;

  /// No description provided for @reachOut.
  ///
  /// In en, this message translates to:
  /// **'or reach out to your researcher directly!'**
  String get reachOut;

  /// No description provided for @whatIsMyStudyString.
  ///
  /// In en, this message translates to:
  /// **'What\'s my Study String?'**
  String get whatIsMyStudyString;

  /// No description provided for @studyStringEmpty.
  ///
  /// In en, this message translates to:
  /// **'Oops! We cannot access your study without a valid Study String.'**
  String get studyStringEmpty;

  /// No description provided for @participantIDEmpty.
  ///
  /// In en, this message translates to:
  /// **'Oops! We cannot access your study without a valid Participant ID.'**
  String get participantIDEmpty;

  /// No description provided for @participantIDError.
  ///
  /// In en, this message translates to:
  /// **'Oops! We do not have this ID in the participant list. Please check your email and try again.'**
  String get participantIDError;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingIn;

  /// No description provided for @hangOn.
  ///
  /// In en, this message translates to:
  /// **'Hang tight while we verify the study string - \nalmost there!'**
  String get hangOn;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @youveCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'\nYou\'ve checked in!'**
  String get youveCheckedIn;

  /// No description provided for @welcomeDescription.
  ///
  /// In en, this message translates to:
  /// **'You are now checked into our study. Thank you so much for joining our research!'**
  String get welcomeDescription;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @preferredName.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Preferred Name'**
  String get preferredName;

  /// No description provided for @turnOnNotificationsTimely.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications for timely reminders!'**
  String get turnOnNotificationsTimely;

  /// No description provided for @makeSureYouHaveSoundOn.
  ///
  /// In en, this message translates to:
  /// **'Make sure you have sound on to catch these alerts on time'**
  String get makeSureYouHaveSoundOn;

  /// No description provided for @batterySaverText.
  ///
  /// In en, this message translates to:
  /// **'Oops! It looks like your phone is in battery-saving mode. This may affect your ability to receive diary notifications. To ensure the study runs smoothly, we recommend turning off battery-saving mode.'**
  String get batterySaverText;

  /// No description provided for @notificationWarning.
  ///
  /// In en, this message translates to:
  /// **'Oops! We recommend you turn ON notifications to allow Fabla to send you reminders to complete the study, otherwise you might not know when to submit the diaries and measures needed for this study.'**
  String get notificationWarning;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @enableMicPermission.
  ///
  /// In en, this message translates to:
  /// **'Oops! You need to enable microphone access to use the recording diary.'**
  String get enableMicPermission;

  /// No description provided for @testMicText.
  ///
  /// In en, this message translates to:
  /// **'Let\'s test your microphone, say something'**
  String get testMicText;

  /// No description provided for @micAccessText.
  ///
  /// In en, this message translates to:
  /// **'Great, next enable microphone access'**
  String get micAccessText;

  /// No description provided for @needToEnableLocation.
  ///
  /// In en, this message translates to:
  /// **'Oops! You need to enable location access to participate in the study.'**
  String get needToEnableLocation;

  /// No description provided for @locationAccessText.
  ///
  /// In en, this message translates to:
  /// **'Let\'s enable access to your location.'**
  String get locationAccessText;

  /// No description provided for @needToEnableCamera.
  ///
  /// In en, this message translates to:
  /// **'Oops! You need to enable camera access to participate in the study.'**
  String get needToEnableCamera;

  /// No description provided for @cameraAccessText.
  ///
  /// In en, this message translates to:
  /// **'Let\'s enable access to your camera.'**
  String get cameraAccessText;

  /// No description provided for @testCameraFeed.
  ///
  /// In en, this message translates to:
  /// **'Let\'s test the camera feed.'**
  String get testCameraFeed;

  /// No description provided for @justFewMoreQuestions.
  ///
  /// In en, this message translates to:
  /// **'You’re almost done! Just a few more questions to personalize your study'**
  String get justFewMoreQuestions;

  /// No description provided for @settingsThingsUp.
  ///
  /// In en, this message translates to:
  /// **'Setting up...'**
  String get settingsThingsUp;

  /// No description provided for @hangTight.
  ///
  /// In en, this message translates to:
  /// **'Hang tight while we set things up for you - \nalmost there!'**
  String get hangTight;

  /// No description provided for @studyPlan.
  ///
  /// In en, this message translates to:
  /// **'Study Plan'**
  String get studyPlan;

  /// Shown on the study plan screen after setup; {name} is the participant's name
  ///
  /// In en, this message translates to:
  /// **'All set {name}, here is your study schedule'**
  String studyPlanText(String name);

  /// No description provided for @aBlueDotStudyPlanCalendar.
  ///
  /// In en, this message translates to:
  /// **'A blue dot on the calendar indicates at least one survey is scheduled for that date.'**
  String get aBlueDotStudyPlanCalendar;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @welcomeLetsGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Welcome, \nLet\'s Get Started'**
  String get welcomeLetsGetStarted;

  /// No description provided for @finishedText.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! {icon} You are all set! Your participation is invaluable to our research. We\'re thrilled to have you on board!'**
  String finishedText(Object icon);

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
  /// **'Bonus When You Complete {entries} entries'**
  String bonusText(int entries);

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

  /// No description provided for @studyDetails.
  ///
  /// In en, this message translates to:
  /// **'Study Details'**
  String get studyDetails;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated:'**
  String get lastUpdated;

  /// No description provided for @viewDetials.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetials;

  /// No description provided for @updateStudy.
  ///
  /// In en, this message translates to:
  /// **'Update Study'**
  String get updateStudy;

  /// No description provided for @contactResearcher.
  ///
  /// In en, this message translates to:
  /// **'Contact Researcher'**
  String get contactResearcher;

  /// No description provided for @participantDetails.
  ///
  /// In en, this message translates to:
  /// **'Participant Details'**
  String get participantDetails;

  /// No description provided for @dateJoined.
  ///
  /// In en, this message translates to:
  /// **'Date Joined'**
  String get dateJoined;

  /// No description provided for @onboardingSurvey.
  ///
  /// In en, this message translates to:
  /// **'Onboarding Survey'**
  String get onboardingSurvey;

  /// No description provided for @onboardingCompletedText.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get onboardingCompletedText;

  /// No description provided for @microphone.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get microphone;

  /// No description provided for @enableMicAccess.
  ///
  /// In en, this message translates to:
  /// **'Enable Microphone Access'**
  String get enableMicAccess;

  /// No description provided for @micAccessTextSettings.
  ///
  /// In en, this message translates to:
  /// **'You must enable microphone Access to record audio diaries.'**
  String get micAccessTextSettings;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @reminderText.
  ///
  /// In en, this message translates to:
  /// **'Set personalized reminders in addition to Fabla’s default notifications.'**
  String get reminderText;

  /// No description provided for @addReminder.
  ///
  /// In en, this message translates to:
  /// **'+ Add Reminder'**
  String get addReminder;

  /// No description provided for @poweredByAppHatchery.
  ///
  /// In en, this message translates to:
  /// **'Powered by AppHatchery'**
  String get poweredByAppHatchery;

  /// No description provided for @leaveStudy.
  ///
  /// In en, this message translates to:
  /// **'Leave Study'**
  String get leaveStudy;

  /// No description provided for @studyUpdateRemote.
  ///
  /// In en, this message translates to:
  /// **'Your study has an update'**
  String get studyUpdateRemote;

  /// No description provided for @studyUpdateRemoteTextOne.
  ///
  /// In en, this message translates to:
  /// **'Your researcher has made an update to the study, which may include changes to wording or instructions. Please update to continue with the latest version.'**
  String get studyUpdateRemoteTextOne;

  /// No description provided for @studyUpdateRemoteTextTwo.
  ///
  /// In en, this message translates to:
  /// **'If you have questions about the changes, please contact your researcher.'**
  String get studyUpdateRemoteTextTwo;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNow;

  /// No description provided for @updatingStudy.
  ///
  /// In en, this message translates to:
  /// **'Updating Study'**
  String get updatingStudy;

  /// No description provided for @updatingStudyText.
  ///
  /// In en, this message translates to:
  /// **'Hang tight! We\'re updating the experiment content. This won\'t take long!'**
  String get updatingStudyText;

  /// No description provided for @studyUpdateSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Study Update Successful'**
  String get studyUpdateSuccessful;

  /// No description provided for @studyUpdateSuccessfulText.
  ///
  /// In en, this message translates to:
  /// **'Your study has been updated to the latest version.'**
  String get studyUpdateSuccessfulText;

  /// No description provided for @studyUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Study Update Failed'**
  String get studyUpdateFailed;

  /// No description provided for @studyUpdateFailedInternetText.
  ///
  /// In en, this message translates to:
  /// **'Your study was not updated. Please check your internet connection and try again or update later under '**
  String get studyUpdateFailedInternetText;

  /// No description provided for @studyUpdateFailedInternetTextTwo.
  ///
  /// In en, this message translates to:
  /// **'“Settings > Study Details”'**
  String get studyUpdateFailedInternetTextTwo;

  /// No description provided for @studyUpdateFailedText.
  ///
  /// In en, this message translates to:
  /// **'Your study was not updated. Retry update or try later under '**
  String get studyUpdateFailedText;

  /// No description provided for @retryUpdate.
  ///
  /// In en, this message translates to:
  /// **'Retry Update'**
  String get retryUpdate;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Update Later'**
  String get updateLater;

  /// No description provided for @studyUpdateFailedHelpText.
  ///
  /// In en, this message translates to:
  /// **'If the issue persists, '**
  String get studyUpdateFailedHelpText;

  /// No description provided for @studyUpdateWarning.
  ///
  /// In en, this message translates to:
  /// **'Waring'**
  String get studyUpdateWarning;

  /// No description provided for @studyUpdateWarningText.
  ///
  /// In en, this message translates to:
  /// **'You are trying to make a manual update to the study. Only proceed if you have received a request from your researcher to update your study.'**
  String get studyUpdateWarningText;

  /// No description provided for @takeMeBack.
  ///
  /// In en, this message translates to:
  /// **'Take Me Back'**
  String get takeMeBack;

  /// No description provided for @proceed.
  ///
  /// In en, this message translates to:
  /// **'Proceed'**
  String get proceed;
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
