// Returns true only for platforms with a real JS detector (Qualtrics, REDCap).
// Used to distinguish meaningful end-string checks from the default passthrough,
// which always returns true and would make end_string_present unreliable.
bool isKnownSurveyPlatform(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  final host = uri.host.toLowerCase();
  final path = uri.path.toLowerCase();
  return host.contains('qualtrics') ||
      host.contains('redcap') ||
      path.contains('/redcap/') ||
      path.contains('/redcap_v');
}

String detectSurveyPlatform(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return 'unknown';

  final host = uri.host.toLowerCase();
  final path = uri.path.toLowerCase();

  if (host.contains('qualtrics')) return qualtricsDetector;

  if (host.contains('redcap') ||
      path.contains('/redcap/') ||
      path.contains('/redcap_v')) {
    return redcapDetector;
  }

// Default lets you go past
  return '''
(function() {
  return true;
})()
''';
}

const String qualtricsDetector = '''
(function() {
  const selectors = [
    '.EndOfSurvey',
    '#EndOfSurvey',
    '.SurveyEnd',
    '.CompletedSurvey',
    '#SurveyEngineBody .SurveyEnd',
    '#end-of-survey',
  ];
  for (const s of selectors) {
    try {
      const el = document.querySelector(s);
      if (el && getComputedStyle(el).display !== 'none' && getComputedStyle(el).visibility !== 'hidden') return true;
    } catch(e) {}
  }
  return false;
})()
''';

// Returns the end-string detector JS for any known platform, or null for unknown ones.
// These are plain text checks used as a dumb failsafe at the moment the user
// taps Finish or Close — separate from the DOM selector polling in detectSurveyPlatform.
// One shared list is used since these strings are completion-specific enough
// that cross-platform false positives aren't a concern.
String? getEndStringDetector(String url) {
  if (!isKnownSurveyPlatform(url)) return null;
  return surveyEndStringDetector;
}

const String surveyEndStringDetector = '''
(function() {
  const text = document.body ? document.body.innerText : '';
  const endStrings = [
    'We thank you for your time spent taking this survey.',
    'Your response has been recorded.',
    'Thank you for finishing this survey.',
    'Thank you for taking the survey.',
    'You may now close this tab/window.',
    'Thank you for your submission.',
  ];
  return endStrings.some(s => text.includes(s));
})()
''';

const String redcapDetector = '''
(function() {
  const selectors = [
    '.surveyacknowledgment',
    '#surveyacknowledgment',
    '[data-mlm="survey-acknowledgment"]',
    '#survey-acknowledgement-table'
  ];
  for (const s of selectors) {
    try {
      const el = document.querySelector(s);
      if (el && getComputedStyle(el).display !== 'none' && getComputedStyle(el).visibility !== 'hidden') return true;
    } catch(e) {}
  }
  if (document.body && document.body.innerText.includes('You may now close this tab/window')) return true;
  return false;
})()
''';
