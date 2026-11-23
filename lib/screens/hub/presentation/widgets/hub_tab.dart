import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Builds a bottom-navigation [Tab] whose label never fades or gets clipped
/// at large font sizes.
///
/// `Tab(text: ...)` draws its label with `softWrap: false` and
/// `TextOverflow.fade`, inside a fixed 72pt-tall tab. With large text the
/// label is wider than its third of the bar (it fades out at the edge) and
/// taller than the space under the icon (its bottom is cut off). Here the
/// label shrinks to fit the width instead, and the tab grows to fit it.
///
/// Call inside the MediaQuery that sets the tab bar's text scale, so the
/// height is measured at the scale the label is drawn at.
Tab hubTab(BuildContext context,
    {required Widget icon, required String label}) {
  return Tab(
    height: hubTabHeight(context),
    icon: icon,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(label, maxLines: 1, softWrap: false),
    ),
  );
}

/// Height for a tab with a 24pt icon above a one-line label: Flutter's
/// default 72pt, or more when the scaled label needs it.
double hubTabHeight(BuildContext context) {
  // TabBar's default Material 3 label style.
  final style = Theme.of(context).textTheme.titleSmall;
  final painter = TextPainter(
    text: TextSpan(text: 'Ag', style: style),
    textScaler: MediaQuery.textScalerOf(context),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  final labelHeight = painter.height;
  painter.dispose();

  const iconSize = 24.0;
  const iconMargin = 10.0; // Tab's default gap under the icon
  const breathingRoom = 8.0;
  return math.max(72.0, iconSize + iconMargin + labelHeight + breathingRoom);
}
