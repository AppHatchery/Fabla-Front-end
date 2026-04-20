import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class StudyIncentives extends StatefulWidget {
  final List<StudyModel> studies;
  final ValueChanged<bool> refresh;

  const StudyIncentives({
    super.key,
    required this.studies,
    required this.refresh,
  });

  @override
  State<StudyIncentives> createState() => _StudyIncentivesState();
}

class _StudyIncentivesState extends State<StudyIncentives> {
  late List<DiaryModel> diaryList;
  late List<StudyModel> studies;
  final DiaryRepository repository = DiaryRepository();

  //Incentive
  double acquired = 0.0;
  double total = 0.0;

  @override
  void initState() {
    diaryList = _getAllDiaries();
    studies = _getStudies();

    track();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return SizedBox(
      height: height,
      width: width,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: CustomColors.yellowTertiary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Expanded(
                        child: SizedBox(),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "Incentives Earned",
                          style: CustomTypography()
                              .titleLarge(color: CustomColors.yellowDark),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                CupertinoIcons.clear,
                                color: CustomColors.yellowDark,
                                size: 20,
                              )),
                        ),
                      ),
                    ],
                  ),
                  //Days active
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    child: header(),
                  ),
                ],
              ),
            ),
            Container(
              width: width,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              color: CustomColors.fillNormal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  compensation(),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  track() async {
    final now = DateTime.now();
    await PendoService.track(
        "Incentives Earned", {"viewed_at": now.toIso8601String()});
  }

  Widget header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: Text(
            formatMoney(acquired,
                currency: widget.studies.first.incentive.currency),
            style: CustomTypography().headlineLargeCustom(
                color: CustomColors.yellowDark, fontSize: 64.sp),
          ),
        ),
      ],
    );
  }

  List<DiaryModel> _getAllDiaries() {
    final list = repository.getAllDiariesWithMultipleEntries();
    return list;
  }

  List<StudyModel> _getStudies() {
    return repository.getAllStudies();
  }

  //Incentive Calculation
  Widget compensation() {
    final width = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Compensation Details",
          style: CustomTypography().titleLarge(),
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: 6),
        Padding(
          padding:EdgeInsets.only(bottom: 24),
          child: Container(
            height: 81,
            width: 440,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: CustomColors.fillWhite,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total Compensation",
                    style: CustomTypography().headlineSmall(),
                  ),
                  Container(
                    decoration: BoxDecoration(
                        color: CustomColors.yellowTertiary,
                        borderRadius: BorderRadius.circular(4)),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                      child: Text(
                        formatMoney(total, currency: widget.studies.first.incentive.currency),
                        style: CustomTypography().headlineSmall(),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          child: SizedBox(
            width: width,
            child: ListView.separated(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemBuilder: (context, index) {
                  if (widget.studies[index].incentive.amount == 0 &&
                      widget.studies[index].incentive.bonus == 0) {
                    return const SizedBox.shrink();
                  }

                  final diaries = diaryList
                      .where((diary) =>
                          diary.studyID == widget.studies[index].studyId)
                      .toList();

                  return StudyIncentive(
                    study: widget.studies[index],
                    diaries: diaries,
                    addToAcquired: (amount, studyTotal) => addToAcquired(amount, studyTotal),
                  );
                },
                separatorBuilder: (context, index) =>
                    const Padding(padding: EdgeInsets.only(bottom: 24)),
                itemCount: widget.studies.length),
          ),
        )
      ],
    );
  }

  // Having all the studies calculate their own incentives and acquired
  void addToAcquired(double amount, double studyTotal) => setState(() {
    acquired += amount;
    total += studyTotal;
  });
}

class StudyIncentive extends StatefulWidget {
  final StudyModel study;
  final List<DiaryModel> diaries;
  final Function(double acquired, double total) addToAcquired;
  const StudyIncentive(
      {super.key,
      required this.study,
      required this.diaries,
      required this.addToAcquired});

  @override
  State<StudyIncentive> createState() => _StudyIncentiveState();
}

class _StudyIncentiveState extends State<StudyIncentive> {
  bool expanded = false;
  int completed = 0;
  double acquired = 0;
  double total = 0;
  int bonusEntriesRequired = 0;
  int totalEntriesRequired = 0;
  bool closeToBonus = false;
  int entriesRequiredForBonus = 0;

  String get currency =>
      widget.study.incentive.currency; // Default to dollar sign

  @override
  void initState() {
    super.initState();
    calculations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.addToAcquired(acquired, total);
    });
  }

  void calculations() {
    final incentive = widget.study.incentive;
    final threshold = incentive.threshold;
    final totalDiaries = widget.diaries.length;

    int completedDiaries = 0;
    int remainingDiaries = 0;

    for (final diary in widget.diaries) {
      if (diary.status == DiaryStatus.submitted) {
        completedDiaries++;
      } else if (diary.status == DiaryStatus.idle) {
        remainingDiaries++;
      }
    }

    // Calculate the number of diaries required to achieve the bonus
    // The bonus is achieved if the percentage of completed diaries is greater than or equal to the threshold
    final bonusEntriesRequired = (totalDiaries * (threshold / 100)).ceil();
    final percentage =
        totalDiaries > 0 ? (completedDiaries / totalDiaries) * 100 : 0;
    final hasAchievedBonus = percentage >= threshold;

    // Calculate earnings
    final baseEarnings = incentive.amount * completedDiaries;
    final bonusEarnings = hasAchievedBonus ? incentive.bonus : 0;
    final acquired = baseEarnings + bonusEarnings;
    final total = (incentive.amount * totalDiaries) + incentive.bonus;

    // Check if bonus is still achievable and user is close to threshold
    final diariesToAchieveBonus = bonusEntriesRequired - completedDiaries;
    final isCloseToBonus = diariesToAchieveBonus > 0 &&
        diariesToAchieveBonus <= 2 &&
        remainingDiaries >= diariesToAchieveBonus;

    setState(() {
      this.bonusEntriesRequired = bonusEntriesRequired;
      totalEntriesRequired = totalDiaries;
      completed = completedDiaries;
      this.total = total;
      this.acquired = acquired;
      closeToBonus = isCloseToBonus;
      entriesRequiredForBonus = diariesToAchieveBonus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CustomColors.fillWhite,
        borderRadius: BorderRadius.circular(16),
        shape: BoxShape.rectangle,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(widget.study.name,
                        style: CustomTypography().titleSmall()),
                    previewTotal()
                  ],
                ),
              ),
              IconButton(
                  onPressed: () {
                    setState(() {
                      expanded = !expanded;
                    });
                  },
                  icon: Icon(
                    expanded
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    size: 20,
                    color: CustomColors.textNormalContent,
                  ))
            ],
          ),
          closeToBonus
              ? Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(bonusMessage(),
                              style: CustomTypography()
                                  .titleSmall(color: CustomColors.yellowDark))),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeOut,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  axis: Axis.vertical,
                  child: child,
                ),
              );
            },
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      spacing: 16,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(
                          height: 1,
                          thickness: 1.5,
                          color: CustomColors.grey,
                        ),
                        progress(),
                        help(),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          )
        ],
      ),
    );
  }

  String bonusMessage() {
    return Intl.message(Intl.plural(
      entriesRequiredForBonus,
      one:
          '1 more entry to your ${formatMoney(widget.study.incentive.bonus, currency: currency)} bonus!',
      other:
          '$entriesRequiredForBonus more entries to your ${formatMoney(widget.study.incentive.bonus, currency: currency)} bonus!',
      name: 'bonusMessage',
      args: [entriesRequiredForBonus],
      desc: 'Bonus message for the user',
    ));
  }

  Widget previewTotal() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            color: widget.study.color?.withAlpha(90),
          ),
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            "${formatMoney(acquired, currency: currency)}/${formatMoney(total, currency: currency)}",
            style: CustomTypography()
                .titleSmall(color: CustomColors.textNormalContent),
          ),
        ),
      ],
    );
  }

  Widget progress() {
    final width = MediaQuery.of(context).size.width;
    final color = widget.study.color;
    final bonusAvailable = widget.study.incentive.bonus > 0;
    final bonusXTotalEntries =
        (bonusEntriesRequired / totalEntriesRequired) * 100;
    final showtwoIcons = bonusXTotalEntries >= 95;
    return SizedBox(
      width: width,
      child: Column(
        children: [
          // Progress bar
          LayoutBuilder(builder: (context, constraints) {
            final max = constraints.maxWidth;

            // Progress is how much has been acquired
            // Bonus is how much is required to get the bonus
            final double _progress = (acquired / total) * max;
            final double _bonus =
                (bonusEntriesRequired / totalEntriesRequired) * max;

            return SizedBox(
              width: max,
              height: 45,
              child: Stack(
                children: [
                  //BONUS
                  _bonus >= max
                      ? const SizedBox.shrink()
                      : bonusAvailable
                          ? Positioned(
                              left: _bonus,
                              top: 5,
                              child: showtwoIcons
                                  ? SizedBox.shrink()
                                  : Image.asset(
                                      'assets/images/icons/Flag.png',
                                      width: 20,
                                      height: 20,
                                      color: color,
                                    ))
                          : const SizedBox.shrink(),
                  //Completion
                  Positioned(
                    left: showtwoIcons ? max - 33 : max - 20,
                    top: showtwoIcons ? 0.3 : 5,
                    child: showtwoIcons
                        ? Image.asset(
                            'assets/images/icons/Trophy&Flag.png',
                            width: 40.34,
                            height: 28.45,
                            color: color,
                          )
                        : Icon(Icons.emoji_events_rounded,
                            color: color, size: 20),
                  ),

                  //PROGRESS BAR BACKGROUND
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(color: CustomColors.fillWhite),
                      child: Container(
                        width: max,
                        height: 6,
                        constraints: const BoxConstraints(maxHeight: 6),
                        decoration: BoxDecoration(
                          color: color?.withAlpha(90),
                          borderRadius: BorderRadius.circular(27),
                        ),
                      ),
                    ),
                  ),
                  //PROGRESS BAR
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: _progress,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(27),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          // Keys
          // Bonus
          bonusAvailable
              ? Row(
                  spacing: 2,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/images/icons/Flag.png',
                      width: 18,
                      height: 18,
                      color: color,
                    ),
                    Expanded(
                      child: Text("Get Your Bonus",
                          style: CustomTypography().bodyMedium(
                              color: CustomColors.textNormalContent)),
                    ),
                    Text("$completed/$bonusEntriesRequired",
                        style: CustomTypography()
                            .bodyMedium(color: CustomColors.textNormalContent)),
                  ],
                )
              : SizedBox.shrink(),

          // Total
          Row(
            spacing: 2,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.emoji_events_rounded,
                size: 18,
                color: color,
              ),
              Expanded(
                child: Text("Total Completion",
                    style: CustomTypography()
                        .bodyMedium(color: CustomColors.textNormalContent)),
              ),
              Text("$completed/$totalEntriesRequired",
                  style: CustomTypography()
                      .bodyMedium(color: CustomColors.textNormalContent)),
            ],
          )
        ],
      ),
    );
  }

  Widget help() {
    return GestureDetector(
      onTap: () => showHelpDialog(),
      child: Container(
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          color: CustomColors.productNormal.withAlpha(90),
        ),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Icon(Icons.help_outline_rounded,
                color: CustomColors.textSecondaryContent),
            Text(
              "How are the incentives calculated?",
              style: CustomTypography()
                  .bodyMedium(color: CustomColors.textSecondaryContent),
            ),
          ],
        ),
      ),
    );
  }

  void showHelpDialog() async {
    await showDialog(context: context, builder: (context) => helpDialog());
  }

  Widget helpDialog() {
    final bonusAvailable = widget.study.incentive.bonus > 0;
    return SimpleDialog(
      contentPadding: const EdgeInsets.all(0),
      titlePadding: const EdgeInsets.all(0),
      insetPadding: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Colors.grey, width: 1)),
      surfaceTintColor: CustomColors.fillWhite,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: CustomColors.fillWhite),
          child: Column(
            children: [
              // Title
              Row(
                children: [
                  Expanded(
                      child: Text("How are the incentives calculated?",
                          style: CustomTypography().titleSmall())),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded))
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  spacing: 6,
                  children: [
                    // Breakdown
                    Row(
                      children: [
                        Expanded(
                            child: Text("Each ${widget.study.name}",
                                style: CustomTypography().bodyMedium())),
                        Text(
                            formatMoney(widget.study.incentive.amount,
                                currency: currency),
                            style: CustomTypography().bodyMedium()),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: Text("Total Entries",
                                style: CustomTypography().bodyMedium())),
                        Text(totalEntriesRequired.toString(),
                            style: CustomTypography().bodyMedium()),
                      ],
                    ),
                    bonusAvailable ? Row(
                      children: [
                        Expanded(
                            child: Text(
                                "Bonus When You Complete $bonusEntriesRequired Entries",
                                style: CustomTypography().bodyMedium())),
                        Text(
                            formatMoney(widget.study.incentive.bonus,
                                currency: currency),
                            style: CustomTypography().bodyMedium()),
                      ],
                    ) : SizedBox.shrink(),
                  ],
                ),
              ),

              // Total
              Container(
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  color: widget.study.color?.withAlpha(90),
                ),
                padding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                        child:
                            Text("Total", style: CustomTypography().title())),
                    Text(formatMoney(total, currency: currency),
                        style: CustomTypography().title())
                  ],
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
