import 'models/validation.dart';

class ReportGenerator {
  static const int _width = 75;

  void printSummary(List<SchemaChange> changes, List<ValidationResult> results) {
    print('');
    _drawTop();
    _drawContent('🧱 OBJECTBOX SCHEMA VALIDATION', centered: true);
    _drawDivider();

    if (changes.isEmpty) {
      _drawContent('🔹 No schema changes detected.', centered: true);
    } else {
      int failures = 0;
      for (int i = 0; i < changes.length; i++) {
        final change = changes[i];
        final result = results[i];
        final status = result.isPass ? '🔹 PASS' : '🔸 FAIL';

        _drawContent('$status: $change');
        if (result.message != null) {
          _drawContent('      └─ ${result.message}');
        }
        if (result.isFailure) failures++;
      }

      _drawDivider();
      if (failures == 0) {
        _drawContent('✨ SUCCESS: Schema is safe for production.', centered: true);
      } else {
        _drawContent('🛑 FAILURE: $failures issue(s) detected.', centered: true);
        _drawContent('Check audit.yaml for details.', centered: true);
      }
    }

    _drawBottom();
    print('');
  }

  void _drawTop() => print('    ┏${'━' * (_width - 2)}┓');
  
  void _drawBottom() => print('    ┗${'━' * (_width - 2)}┛');
  
  void _drawDivider() => print('    ┠${'─' * (_width - 2)}┨');

  void _drawContent(String text, {bool centered = false}) {
    final availableSpace = _width - 4; // 2 for borders, 2 for internal padding
    
    final lines = _wrapText(text, availableSpace);
    
    for (final line in lines) {
      final visibleLength = _estimateVisibleLength(line);
      
      if (centered) {
        final leftPadding = (availableSpace - visibleLength) ~/ 2;
        final rightPadding = availableSpace - visibleLength - leftPadding;
        print('    ┃ ${' ' * leftPadding}$line${' ' * rightPadding} ┃');
      } else {
        final rightPadding = availableSpace - visibleLength;
        print('    ┃ $line${' ' * (rightPadding > 0 ? rightPadding : 0)} ┃');
      }
    }
  }

  List<String> _wrapText(String text, int maxWidth) {
    final words = text.split(' ');
    final lines = <String>[];
    String currentLine = '';

    for (final word in words) {
      final potentialLine = currentLine.isEmpty ? word : '$currentLine $word';
      if (_estimateVisibleLength(potentialLine) <= maxWidth) {
        currentLine = potentialLine;
      } else {
        if (currentLine.isNotEmpty) {
          lines.add(currentLine);
        }
        currentLine = word;

        while (_estimateVisibleLength(currentLine) > maxWidth) {
          final cutPoint = maxWidth - 2; 
          lines.add(currentLine.substring(0, cutPoint));
          currentLine = currentLine.substring(cutPoint);
        }
      }
    }
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }
    return lines;
  }

  int _estimateVisibleLength(String text) {
    int length = text.length;
    final emojiCount = RegExp(r'[🧱🔷🔶✅🛑]').allMatches(text).length;
    return length + emojiCount;

  }
}
