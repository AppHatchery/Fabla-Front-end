// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get welcomeToFabla => '¡Te damos la bienvenida a Fabla!';

  @override
  String get fableLoginDescription =>
      'Fabla es una herramienta para la investigación de experiencias diarias, diarios de audio y mucho más';

  @override
  String get studyID => 'Código del estudio';

  @override
  String get enterYourStudyString => 'Introduce el código del estudio...';

  @override
  String get verifyingStudyID => 'Verificando...';

  @override
  String get hangOnTight =>
      'Espera un momento mientras verificamos el código del estudio. ¡Ya casi está!';

  @override
  String get studyInformation => 'Información del estudio';

  @override
  String get belowIsInformation =>
      'A continuación se muestra la información del estudio asociada a este código de estudio.';

  @override
  String get studyName => 'Nombre del estudio';

  @override
  String get studyDuration => 'Duración del estudio';

  @override
  String get researcherName => 'Nombre del investigador';

  @override
  String get viewStudyDetails => 'Ver detalles del estudio';

  @override
  String get confirmJoining => 'Confirmar participación';

  @override
  String get thisIsntRight => 'Esto no está bien, llévame de vuelta';

  @override
  String get participantLogin => 'Inicio de sesión de participante';

  @override
  String get participantLoginDescription =>
      'Introduce el ID de participante que te proporcionaron los investigadores.';

  @override
  String get participantID => 'ID de participante';

  @override
  String get enterYourParticipantID => 'Introduce tu ID de participante...';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get needHelpWithParticipantID =>
      '¿Necesitas ayuda con el ID de participante?';

  @override
  String get needHelpWithStudyID =>
      '¿Necesitas ayuda con el código de estudio?';

  @override
  String get contactUs => 'Contáctanos';

  @override
  String get studyStringError =>
      '¡Vaya! No podemos acceder a tu estudio sin un código de estudio válido.';

  @override
  String get your => 'Tu';

  @override
  String get alphanumericcode =>
      'es un código alfanumérico (p. ej., ABC123) que tu investigador comparte contigo para darte acceso a tu estudio en Fabla';

  @override
  String get ifYouNeedHelpPopUP => 'Si necesitas ayuda con tu';

  @override
  String get youMay => 'puedes';

  @override
  String get reachOut => '¡o contacta directamente con tu investigador!';

  @override
  String get whatIsMyStudyString => '¿Cuál es mi código de estudio?';

  @override
  String get studyStringEmpty =>
      '¡Vaya! No podemos acceder a tu estudio sin un código de estudio válido.';

  @override
  String get participantIDEmpty =>
      '¡Vaya! No podemos acceder a tu estudio sin un ID de participante válido.';

  @override
  String get participantIDError =>
      '¡Vaya! No tenemos este ID en la lista de participantes. Revisa tu correo electrónico e inténtalo de nuevo.';

  @override
  String get signingIn => 'Iniciando sesión...';

  @override
  String get hangOn =>
      'Espera un momento mientras verificamos el código del estudio. ¡Ya casi está!';

  @override
  String get welcome => 'Te damos la bienvenida';

  @override
  String get youveCheckedIn => '\n¡Ya estás dentro!';

  @override
  String get welcomeDescription =>
      'Ya estás registrado en nuestro estudio. ¡Muchas gracias por unirte a nuestra investigación!';

  @override
  String get continueText => 'Continuar';

  @override
  String get preferredName => 'Introduce tu nombre preferido';

  @override
  String get turnOnNotificationsTimely =>
      '¡Activa las notificaciones para recibir recordatorios a tiempo!';

  @override
  String get makeSureYouHaveSoundOn =>
      'Asegúrate de tener el sonido activado para no perderte estas alertas a tiempo';

  @override
  String get batterySaverText =>
      '¡Vaya! Parece que tu teléfono está en modo de ahorro de batería. Esto puede afectar la recepción de las notificaciones del diario. Para que el estudio funcione correctamente, te recomendamos desactivar el modo de ahorro de batería.';

  @override
  String get notificationWarning =>
      '¡Vaya! Te recomendamos activar las notificaciones para que Fabla pueda enviarte recordatorios para completar el estudio; de lo contrario, podrías no saber cuándo enviar los diarios y las mediciones necesarias para este estudio.';

  @override
  String get openSettings => 'Abrir ajustes';

  @override
  String get enableMicPermission =>
      '¡Vaya! Necesitas habilitar el acceso al micrófono para usar el diario de grabación.';

  @override
  String get testMicText => 'Vamos a probar tu micrófono, di algo';

  @override
  String get micAccessText => 'Genial, ahora habilita el acceso al micrófono';

  @override
  String get needToEnableLocation =>
      '¡Vaya! Necesitas habilitar el acceso a la ubicación para participar en el estudio.';

  @override
  String get locationAccessText =>
      'Vamos a habilitar el acceso a tu ubicación.';

  @override
  String get needToEnableCamera =>
      '¡Vaya! Necesitas habilitar el acceso a la cámara para participar en el estudio.';

  @override
  String get cameraAccessText => 'Vamos a habilitar el acceso a tu cámara.';

  @override
  String get testCameraFeed => 'Vamos a probar la cámara.';

  @override
  String get justFewMoreQuestions =>
      '¡Ya casi terminas! Solo unas preguntas más para personalizar tu estudio';

  @override
  String get settingsThingsUp => 'Configurando...';

  @override
  String get hangTight =>
      'Espera un momento mientras lo preparamos todo para ti. ¡Ya casi está!';

  @override
  String get studyPlan => 'Plan del estudio';

  @override
  String studyPlanText(String name) {
    return '¡Todo listo, $name! Este es tu calendario del estudio.';
  }

  @override
  String get aBlueDotStudyPlanCalendar =>
      'Un punto azul en el calendario indica que hay al menos una encuesta programada para esa fecha.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get welcomeLetsGetStarted => 'Welcome, \nLet\'s Get Started';

  @override
  String finishedText(Object icon) {
    return 'Congratulations! $icon You are all set! Your participation is invaluable to our research. We\'re thrilled to have you on board!';
  }

  @override
  String get todaysGoal => 'Meta de hoy';

  @override
  String get noDailyGoalToday => 'Hoy no hay ninguna meta diaria';

  @override
  String get weeklyGoal => 'Meta semanal';

  @override
  String get todaysEntries => 'Entradas de hoy';

  @override
  String get study => 'Estudio';

  @override
  String get history => 'Historial';

  @override
  String get settings => 'Ajustes';

  @override
  String get incentivesEarned => 'Incentivos ganados';

  @override
  String get compensationDetails => 'Detalles de compensación';

  @override
  String get howAreIncentivesCalculated => '¿Cómo se calculan los incentivos?';

  @override
  String get totalEntries => 'Total de entradas';

  @override
  String get each => 'Por cada';

  @override
  String get total => 'Total';

  @override
  String get bonusText => 'Bono al completar';

  @override
  String get getYourBonus => 'Consigue tu bono';

  @override
  String get totalCompletion => 'Finalización total';

  @override
  String get studyCalendar => 'Calendario del estudio';

  @override
  String get pastEntries => 'Entradas anteriores';

  @override
  String get todaysCalendarEntries => 'Entradas de hoy';

  @override
  String get upComingEntries => 'Próximas entradas';

  @override
  String get availableUntil => 'Disponible hasta:';

  @override
  String get opensAt => 'Disponible desde:';
}
