import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../bug_reporter.dart';

class TapTargetResolver {
  TapTargetResolver._();

  static String? labelAt(Offset position, int viewId) {
    final result = HitTestResult();
    RendererBinding.instance.hitTestInView(result, position, viewId);

    String? iconFallback;

    for (final entry in result.path) {
      final target = entry.target;
      if (target is! RenderObject) continue;

      final semanticsLabel = target.debugSemantics?.label.trim();
      if (semanticsLabel != null &&
          semanticsLabel.isNotEmpty &&
          !_isGlyph(semanticsLabel)) {
        return _format(semanticsLabel);
      }

      if (target is RenderParagraph) {
        final text = target.text.toPlainText();
        if (_isIconFont(target.text.style) || _isGlyph(text)) {
          iconFallback ??= _iconName(text);
        } else {
          final trimmed = text.trim();
          if (trimmed.isNotEmpty) return _format(trimmed);
        }
      }
    }

    return iconFallback;
  }

  static bool _isIconFont(TextStyle? style) {
    final family = style?.fontFamily ?? '';
    if (family.contains('Icon')) return true;
    return (style?.fontFamilyFallback ?? const <String>[])
        .any((f) => f.contains('Icon'));
  }

  static bool _isGlyph(String value) {
    if (value.isEmpty) return false;
    return value.runes.every((r) => r >= 0xE000 && r <= 0xF8FF);
  }

  static String? _iconName(String glyph) {
    if (glyph.isEmpty) return null;
    final codePoint = glyph.runes.first;
    return BugReporter.config.iconNames[codePoint] ?? _defaultIconNames[codePoint];
  }

  static String _format(String label) {
    final clean = label.replaceAll('\n', ' ').trim();
    return clean.length > 50 ? '${clean.substring(0, 50)}...' : clean;
  }

  static final Map<int, String> _defaultIconNames = {
    Icons.bug_report.codePoint: 'Report a bug',
    Icons.access_time.codePoint: 'Time',
    Icons.add.codePoint: 'Add',
    Icons.arrow_back.codePoint: 'Back',
    Icons.arrow_back_ios_new.codePoint: 'Back',
    Icons.check.codePoint: 'Done',
    Icons.chevron_left.codePoint: 'Previous',
    Icons.chevron_right.codePoint: 'Next',
    Icons.close.codePoint: 'Close',
    Icons.delete.codePoint: 'Delete',
    Icons.delete_outline.codePoint: 'Delete',
    Icons.edit.codePoint: 'Edit',
    Icons.event.codePoint: 'Date',
    Icons.event_available.codePoint: 'Date',
    Icons.info_outline.codePoint: 'Info',
    Icons.menu.codePoint: 'Menu',
    Icons.more_vert.codePoint: 'More',
    Icons.repeat.codePoint: 'Repeat',
    Icons.save.codePoint: 'Save',
    Icons.schedule.codePoint: 'Time',
    Icons.search.codePoint: 'Search',
    Icons.settings.codePoint: 'Settings',
    Icons.share.codePoint: 'Share',
  };
}
