// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get welcomeToFabla => 'Willkommen zu Fabla!';

  @override
  String get fableLoginDescription =>
      'Fabla ist ein Instrument zur Erforschung alltäglicher Erlebnisse, zur Erstellung von Audio-Tagebüchern und vielem mehr';

  @override
  String get studyID => 'Studien ID';

  @override
  String get enterYourStudyString => 'Gebe die Studien ID ein...';

  @override
  String get verifyingStudyID => 'Wird überprüft ...';

  @override
  String get hangOnTight =>
      'Einen Moment bitte, wir überprüfen deine Studien-ID. Gleich geht´s weiter.';

  @override
  String get studyInformation => 'Studieninformation';

  @override
  String get belowIsInformation =>
      'Diese Informationen wurden aus dem Studiencode übernommen, den du eingegeben hast. Bitte prüfe, ob alles stimmt.';

  @override
  String get studyName => 'Name der Studie';

  @override
  String get studyDuration => 'Dauer der Studie';

  @override
  String get researcherName => 'Forschende Person';

  @override
  String get viewStudyDetails => 'Studien-Details anzeigen';

  @override
  String get confirmJoining => 'Teilnahme bestätigen';

  @override
  String get thisIsntRight => 'Das stimmt nicht - zurück';

  @override
  String get participantLogin => 'Login Teilnehmende';

  @override
  String get participantLoginDescription =>
      'Bitte gib deine zugeteilte Teilnehmenden ID ein.';

  @override
  String get participantID => 'Teilnehmenden ID';

  @override
  String get enterYourParticipantID => 'Gebe die Teilnehmenden ID ein...';

  @override
  String get login => 'Anmelden';

  @override
  String get needHelpWithParticipantID =>
      'Benötigst du Hilfe bei der Teilnehmenden ID?';

  @override
  String get needHelpWithStudyID => 'Benötigst du Hilfe bei der Studien ID?';

  @override
  String get contactUs => 'Kontaktiere uns';

  @override
  String get studyStringError =>
      'Hoppla! Ohne eine gültige Studien-ID können wir nicht auf diese Studie zugreifen.';

  @override
  String get your => 'Eine';

  @override
  String get alphanumericcode =>
      'ist ein alphanumerischer Code (z.B. ABC123), mit dem du Zugriff auf die Studie erhälst.';

  @override
  String get ifYouNeedHelpPopUP => 'Bei Fragen zu deiner';

  @override
  String get youMay => ' ';

  @override
  String get reachOut => 'oder deine Studienleitung.';

  @override
  String get whatIsMyStudyString => 'Was ist meine Studien ID?';

  @override
  String get studyStringEmpty =>
      'Hoppla! Wir haben diesen Code leider nicht in unserer Studienliste. Bitte überprüfe deine E-Mails und versuche es nochmal.';

  @override
  String get participantIDEmpty =>
      'Hoppla! Ohne eine gültige Teilnehmenden ID ist der Zugang zur Studie nicht möglich.';

  @override
  String get participantIDError =>
      '  Hoppla! Wir haben diese ID leider nicht in unserer Teilnehmendenliste. Bitte überprüfe deine E-Mails und versuche es nochmal.';

  @override
  String get signingIn => 'Anmeldung läuft ...';

  @override
  String get hangOn => 'Gleich geht´s weiter';

  @override
  String get welcome => 'Willkommen';

  @override
  String get youveCheckedIn => '\nDann legen wir mal los.';

  @override
  String get welcomeDescription =>
      'Toll, dass du dabei bist. Deine Teilnahme bedeutet uns wirklich viel.';

  @override
  String get continueText => 'Weiter';

  @override
  String get preferredName =>
      'Hier kannst du deinen bevorzugten Namen eingeben';

  @override
  String get turnOnNotificationsTimely =>
      'Aktiviere die Benachichtigungen, damit du deine Erinnerungen pünklich erhältst!';

  @override
  String get makeSureYouHaveSoundOn =>
      'Stelle sicher, dass der Ton eingeschaltet ist, damit du keine Benachrichtigungen verpasst.';

  @override
  String get batterySaverText =>
      'Hoppla! Dein Energiesparmodus ist aktiviert. Das kann den Empfang von Tagebuchbenachrichtigungen beeinträchtigen. Für einen reibungslosen Ablauf der Studie schalte ihn lieber aus.';

  @override
  String get notificationWarning =>
      'Hoppla! Wir empfehlen dir, die Benachichtigungen zu aktivieren, damit wir dich rechtzeitig an anstehende Aufgaben erinnern können. Anderenfalls erfährst du möglicherweise nicht rechtzeitig, wann du für diese Studie erforderliche Tagebücher und Messungen einreichen musst.';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get enableMicPermission =>
      'Hoppla! Du musst den Zugriff auf das Mikrofon aktivieren, damit die Aufzeichnung funktioniert.';

  @override
  String get testMicText =>
      'Lass uns nun dein Mikrofon testen. Bitte sag etwas.';

  @override
  String get micAccessText =>
      'Super, aktiviere nun den Zugriff auf das Mikrofon.';

  @override
  String get needToEnableLocation =>
      'Bitte aktiviere die Standorteinstellung während der Nutzung der App.';

  @override
  String get locationAccessText =>
      'Lass uns nun die Standortfreigabe aktivieren.';

  @override
  String get needToEnableCamera =>
      'Hoppla! Du musst den Kamerazugriff aktivieren, um an der Studie teilzunehmen.';

  @override
  String get cameraAccessText =>
      'Lass uns als nächstes den Zugriff auf deine Kamera aktivieren.';

  @override
  String get testCameraFeed => 'Lass uns jetzt deine Kamera testen.';

  @override
  String get justFewMoreQuestions =>
      'Fast geschafft! Nur noch ein paar Fragen um die Studie individuell für dich anzupassen.';

  @override
  String get settingsThingsUp => 'Wird eingerichtet ...';

  @override
  String get hangTight => 'Bleib dran. Gleich geht´s weiter';

  @override
  String get studyPlan => 'Studienplan';

  @override
  String studyPlanText(String name) {
    return '$name, du hast es geschafft! Hier siehst du den Studienplan.';
  }

  @override
  String get aBlueDotStudyPlanCalendar =>
      'Ein blauer Punkt im Kalender zeigt an, dass für diesen Tag mindestens ein Eintrag geplant ist.';

  @override
  String get getStarted => 'Loslegen';

  @override
  String get welcomeLetsGetStarted =>
      'Willkommen, jetzt kann´s richtig losgehen!';

  @override
  String finishedText(Object icon) {
    return 'Glückwunsch $icon Du bist startklar! Deine Teilnahme ist für unsere Forschung von großem Wert. Wir freuen uns sehr, dass du dabei bist!';
  }

  @override
  String get todaysGoal => 'Heutiges Ziel';

  @override
  String get noDailyGoalToday => 'Heute gibt es kein Tagesziel';

  @override
  String get weeklyGoal => 'Wochenziel';

  @override
  String get todaysEntries => 'Tagebuch- oder Umfrageeinträge für heute';

  @override
  String get study => 'Studie';

  @override
  String get history => 'Verlauf';

  @override
  String get settings => 'Einstellungen';

  @override
  String get incentivesEarned => 'Bisherige Vergütung';

  @override
  String get compensationDetails => 'Vergütungsdetails';

  @override
  String get howAreIncentivesCalculated => 'Wie werden die Prämien berechnet?';

  @override
  String get totalEntries => 'Gesamtzahl der Einträge';

  @override
  String get each => 'Für jede';

  @override
  String get total => 'Gesamtbetrag';

  @override
  String bonusText(int entries) {
    return 'Prämie bei Abschluss von $entries';
  }

  @override
  String get getYourBonus => 'Einträge bis Prämie:';

  @override
  String get totalCompletion => 'Gesamteinträge bis Abschluss:';

  @override
  String get studyCalendar => 'Studienkalender';

  @override
  String get pastEntries => 'Vergangene  Aufgaben vom ';

  @override
  String get todaysCalendarEntries => 'Heute verfügbare Aufgaben';

  @override
  String get upComingEntries => 'Anstehende Aufgaben am';

  @override
  String get availableUntil => 'Verfügbar bis:';

  @override
  String get opensAt => 'Verfügbar ab:';

  @override
  String get studyDetails => 'Studiendetails';

  @override
  String get lastUpdated => 'Zuletzt aktualisiert:';

  @override
  String get viewDetials => 'Details anzeigen';

  @override
  String get updateStudy => 'Studie aktualisieren';

  @override
  String get contactResearcher => 'Studienleitung kontaktieren';

  @override
  String get participantDetails => 'Teilnehmenden Details';

  @override
  String get dateJoined => 'Beitrittsdatum';

  @override
  String get onboardingSurvey => 'Einführungsumfrage';

  @override
  String get onboardingCompletedText => 'Ausgefüllt';

  @override
  String get microphone => 'Mikrofon';

  @override
  String get enableMicAccess => 'Zugriff auf das Mikrofon aktivieren';

  @override
  String get micAccessTextSettings =>
      'Der Zugriff auf das Mikrofon muss aktiviert werden, um Audio-Tagebücher aufzunehmen.';

  @override
  String get reminders => 'Erinnerungen';

  @override
  String get reminderText =>
      'Zusätzlich zu den Standardbenachrichtigungen von Fabla kannst du personalisierte Erinnerungen einstellen.';

  @override
  String get addReminder => 'Erinnerungen hinzufügen';

  @override
  String get poweredByAppHatchery => 'Entwickelt von AppHatchery';

  @override
  String get leaveStudy => 'Studie verlassen';

  @override
  String get studyUpdateRemote => 'Für deine Studie ist ein Update verfügbar';

  @override
  String get studyUpdateRemoteTextOne =>
      'Die Studienleitung hat ein Update für die Studie vorgenommen, das möglicherweise Änderungen am Wortlaut oder an den Anweisungen enthält. Bitte aktualisiere die Studie, um mit der neuesten Version fortzufahren.';

  @override
  String get studyUpdateRemoteTextTwo =>
      'Wenn Fragen zu den Änderungen aufkommen, wende dich bitte an die Studienleitung.';

  @override
  String get updateNow => 'Jetzt aktualisieren';

  @override
  String get updatingStudy => 'Studie wird aktualisiert';

  @override
  String get updatingStudyText =>
      'Bitte habe noch etwas Geduld! Wir aktualisieren gerade den Inhalt der Studie. Das dauert nicht lange.';

  @override
  String get studyUpdateSuccessful => 'Aktualisierung erfolgreich';

  @override
  String get studyUpdateSuccessfulText =>
      'Die Studie wurde erfolgreich aktualisiert.';

  @override
  String get studyUpdateFailed => 'Aktualisierung fehlgeschlagen';

  @override
  String get studyUpdateFailedInternetText =>
      'Die Studie wurde nicht aktualisiert. Bitte überprüfe deine Internetverbindung und versuche es erneut oder aktualisiere sie später unter. ';

  @override
  String get studyUpdateFailedInternetTextTwo =>
      '“Einstellungen > Studiendetails”';

  @override
  String get studyUpdateFailedText =>
      'Die Studie wurde nicht aktualisiert. Versuche es erneut oder später unter ';

  @override
  String get retryUpdate => 'Aktualisieren wiederholen';

  @override
  String get updateLater => 'Später aktualisieren';

  @override
  String get studyUpdateFailedHelpText =>
      'Wenn das Problem weiterhin besteht, wende dich bitte an die ';

  @override
  String get studyUpdateWarning => 'Warnung';

  @override
  String get studyUpdateWarningText =>
      'Du bist dabei, die Studie manuell zu aktualisieren. Führe diese Aktion nur aus, wenn die Studienleitung dich ausdrücklich dazu aufgefordert hat.';

  @override
  String get takeMeBack => 'Zurück';

  @override
  String get proceed => 'Weiter';
}
