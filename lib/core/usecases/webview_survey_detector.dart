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
  return false;
})()
''';
