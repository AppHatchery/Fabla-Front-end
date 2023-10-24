import 'package:flutter/material.dart';

import '../custom_colors.dart';

/// Custom Bar Indicator.
///
/// [pageCount] is the total number of pages.
///
/// [currentPage] is the current page.
class CustomBarIndicator extends StatelessWidget {
  final int pageCount;
  final int currentPage;
  const CustomBarIndicator(
      {super.key, required this.pageCount, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30), // Apply borderRadius here
            child: LinearProgressIndicator(
              backgroundColor: CustomColors.greyDarker,
              value: (currentPage + 1) / pageCount,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(CustomColors.yellowDark),
              minHeight: 12,
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
        // const SizedBox(height: 12),
        // Container(
        //     padding: const EdgeInsets.only(left: 5),
        //     alignment: Alignment.centerLeft,
        //     child: Text(
        //       "Question ${currentPage + 1}/$pageCount",
        //       style: CustomTypography().bodyMedium(),
        //     ))
      ],
    );
  }
}
