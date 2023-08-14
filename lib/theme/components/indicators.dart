import 'package:flutter/material.dart';

import '../custom_colors.dart';
import '../custom_typography.dart';

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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pageCount, (index) {
            return Expanded(
              child: Container(
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: currentPage == index
                      ? CustomColors.productNormal
                      : CustomColors.productBorderNormal,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Container(
            padding: const EdgeInsets.only(left: 5),
            alignment: Alignment.centerLeft,
            child: Text(
              "Q${currentPage + 1}/$pageCount",
              style: CustomTypography().bodyMedium(),
            ))
      ],
    );
  }
}
