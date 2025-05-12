import 'package:audio_diaries_flutter/core/usecases/calendar.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/empty_state.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/theme/components/cards.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:popover/popover.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:rive/rive.dart' as rive;

extension _TextExtension on rive.Artboard {
  rive.TextValueRun? textRun(String name) => component<rive.TextValueRun>(name);
}

class StudyCalendar extends StatefulWidget {
  final List<StudyModel> studies;
  final ValueChanged<bool> refresh;
  final String Function() getPageName;

  const StudyCalendar({
    super.key,
    required this.studies,
    required this.refresh,
    required this.getPageName,
  });

  @override
  State<StudyCalendar> createState() => _StudyCalendarState();
}

class _StudyCalendarState extends State<StudyCalendar> {
  late PageController? pageController;
  late DateTime focusedDay;
  late DateTime today;
  late DateTime selectedDate;
  late List<DiaryModel> diaries; // Diaries for today
  late bool isBeforeToday;
  late List<DiaryModel> diaryList; // All the diaries
  final DiaryRepository repository = DiaryRepository();
  Map<DateTime, List<String>>? events = {};
  Set<DateTime> activeDates = {};

  ScrollController? controller;
  late rive.StateMachineController _controller;

  rive.TextValueRun? days;
  rive.TextValueRun? cheer;
  rive.TextValueRun? encouragement;

  @override
  void initState() {
    today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    pageController = null;
    controller = ScrollController();
    focusedDay = today;
    selectedDate = today;
    diaryList = _getAllDiaries();
    diaries = fetchDiaries(today);
    events = getCalendarEvents(diaryList);
    getActiveDates(diaryList);

    track();
    super.initState();
  }

  @override
  void dispose() {
    controller?.dispose();
    _controller.dispose();
    pageController = null;
    pageController?.dispose();
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
        controller: controller,
        child: Column(
          children: [
            Container(
              color: CustomColors.productLightBackground,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                CupertinoIcons.clear,
                                color: CustomColors.productNormalActive,
                                size: 20,
                              )),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "Study Calendar",
                          style: CustomTypography().titleLarge(
                              color: CustomColors.productNormalActive),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Expanded(
                        child: SizedBox(),
                      )
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
                spacing: 24,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [calendar(), entries()],
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
        "Study Calendar", {"viewed_at": now.toIso8601String()});
  }

  Widget header() {
    final width = MediaQuery.of(context).size.width;
    return SizedBox(
      width: width,
      height: 150,
      child: rive.RiveAnimation.asset(
        'assets/animations/ghosts-calendar.riv',
        onInit: _onInit,
        fit: BoxFit.contain,
      ),
    );
  }

  void _onInit(rive.Artboard art) {
    var ctrl = rive.StateMachineController.fromArtboard(art, "Ghosts");

    ctrl?.isActive = false;
    if (ctrl != null) {
      art.addController(ctrl);
      final _days = art.textRun('Days');
      final _cheer = art.textRun('Cheer');
      final _encouragement = art.textRun('Encouragement');
      setState(() {
        _controller = ctrl;
        days = _days;
        cheer = _cheer;
        encouragement = _encouragement;
      });

      final arrival = _controller.findSMI('First arrival');
      if (arrival != null && mounted) {
        arrival.value = true;
      }

      determineAnimationWords();
    }
  }

  void determineAnimationWords() {
    days?.text = Intl.plural(activeDates.length,
        other:
            "${activeDates.length} days active - You're doing GREAT! Keep working towards the goals",
        one: "1 day active - You're doing GOOD! Keep working towards the goals",
        zero:
            "No days logged yet - Make sure to look out for your upcoming diaries");
    cheer?.text = "";
    encouragement?.text = "";
  }

  Widget calendar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          spacing: 6,
          children: [
            Text(
              "Study Calendar",
              style: CustomTypography().titleLarge(),
            ),
            HelpButton()
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: CustomColors.fillWhite,
            borderRadius: BorderRadius.circular(12),
            shape: BoxShape.rectangle,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
          child: TableCalendar(
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2060, 3, 14),
            focusedDay: focusedDay,
            currentDay: today,
            availableGestures: AvailableGestures.horizontalSwipe,
            rowHeight: 54,
            headerStyle: const HeaderStyle(
                titleCentered: false,
                formatButtonVisible: false,
                rightChevronVisible: false,
                leftChevronVisible: false),
            calendarStyle: CalendarStyle(
              outsideTextStyle: CustomTypography()
                  .bodyLarge(color: CustomColors.textTertiaryContent),
              todayDecoration: const BoxDecoration(
                  color: CustomColors.productNormalActive,
                  shape: BoxShape.circle),
            ),
            startingDayOfWeek: StartingDayOfWeek.monday,
            daysOfWeekHeight: 45,
            onDaySelected: _onDaySelected,
            onCalendarCreated: (controller) {
              pageController = controller;
            },
            eventLoader: getDiariesForDay,
            calendarBuilders: CalendarBuilders(
              headerTitleBuilder: (context, day) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Text(
                        getMonthYear(day),
                        style: CustomTypography().titleSmall(
                            color: CustomColors.textSecondaryContent),
                      ),
                    ),
                    SizedBox(
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => pageController?.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.ease),
                            child: const SizedBox(
                                height: 24,
                                width: 24,
                                child: Icon(Icons.chevron_left_rounded)),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => pageController?.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.ease),
                            child: const SizedBox(
                                height: 24,
                                width: 24,
                                child: Icon(Icons.chevron_right_rounded)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              dowBuilder: (context, day) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.only(bottom: 8),
                  decoration: const BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              width: 0.6,
                              color: CustomColors.productBorderNormal))),
                  child: Center(
                    child: Text(
                      DateFormat.E().format(day)[0],
                      style: CustomTypography()
                          .titleSmall(color: CustomColors.textSecondaryContent),
                    ),
                  ),
                );
              },
              defaultBuilder: (context, day, focusedDay) {
                final color = selectedDate == day
                    ? CustomColors.productNormalActive
                    : null;

                final textColor = selectedDate == day
                    ? CustomColors.textWhite
                    : CustomColors.textTertiaryContent;
                return Center(
                  child: Container(
                    width: 33,
                    height: 33,
                    margin: const EdgeInsets.only(bottom: 4),
                    alignment: Alignment.center,
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, color: color),
                    child: Text(
                      day.day.toString(),
                      style: CustomTypography().bodyMedium(color: textColor),
                    ),
                  ),
                );
              },
              todayBuilder: (context, date, time) {
                final color = (today == selectedDate || date == selectedDate)
                    ? CustomColors.productNormalActive
                    : CustomColors.productLightBackground;

                final textColor =
                    (today == selectedDate || date == selectedDate)
                        ? CustomColors.textWhite
                        : CustomColors.productNormal;
                return Center(
                  child: Container(
                    width: 33,
                    height: 33,
                    margin: const EdgeInsets.only(bottom: 4),
                    alignment: Alignment.center,
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, color: color),
                    child: Text(
                      date.day.toString(),
                      style: CustomTypography().bodyLarge(color: textColor),
                    ),
                  ),
                );
              },
              singleMarkerBuilder: (context, date, event) {
                isBeforeToday = date.isBefore(today);
                final isDiaryOnEventSubmitted = _diaryOnEventSubmitted(date);

                final color = isBeforeToday
                    ? isDiaryOnEventSubmitted
                        ? CustomColors.productLightPrimaryActive
                        : CustomColors.productBorderNormal
                    : CustomColors.productNormalActive;
                return Container(
                  width: 7.0,
                  height: 7.0,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: color),
                  margin: const EdgeInsets.symmetric(
                      vertical: 5.0, horizontal: 1.5),
                );
              },
            ),
          ),
        )
      ],
    );
  }

  bool _diaryOnEventSubmitted(DateTime date) {
    final diaries = diaryList.where((diary) {
      return DateTime(
        diary.due.year,
        diary.due.month,
        diary.due.day,
      ).isAtSameMomentAs(DateTime(date.year, date.month, date.day));
    }).toList();

    //check if any of the diaries were submitted
    return diaries.any((diary) {
      return diary.status == DiaryStatus.submitted;
    });
  }

  _onDaySelected(DateTime selectedDay, DateTime focusedDate) {
    setState(() {
      //reloading diaries bases on new selected date

      focusedDay = selectedDay;
      selectedDate = selectedDay;
      diaries = fetchDiaries(selectedDate);
    });
  }

  Widget entries() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
          DateUtils.isSameDay(DateTime.now(), selectedDate)
              ? "Tasks Available Today"
              : "Tasks Due ${DateFormat("MMMM d").format(selectedDate)}, ${DateFormat.y().format(selectedDate)} ",
          style: CustomTypography().titleLarge()),
      const SizedBox(height: 4),

      //Scrollable widget to display all entries due on selected date
      diaries.isNotEmpty
          ? ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: diaries.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: DiaryCardSmall(
                    diary: diaries[index],
                  ),
                );
              },
            )
          : const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: FreeDayWidget(),
            )
    ]);
  }

  getMonthYear(DateTime day) {
    final DateFormat formatter = DateFormat("MMMM yyyy");
    return formatter.format(day);
  }

  List<String> getDiariesForDay(DateTime day) {
    if (events != null) {
      final date = DateTime(day.year, day.month, day.day);
      return events![date] ?? [];
    }

    return [];
  }

  List<DiaryModel> _getAllDiaries() {
    final list = repository.getAllDiariesWithMultipleEntries();
    return list;
  }

  getActiveDates(List<DiaryModel> diaries) {
    // get dates of submitted diaries
    for (final diary in diaries) {
      if (diary.status == DiaryStatus.submitted) {
        activeDates.add(diary.start);
      }
    }
  }

  //Retrieving entries for a specific date (Called From StudyCalendar)
  List<DiaryModel> fetchDiaries(DateTime date) {
    return filterTodaysDiaries(date, diaryList);
  }
}

class HelpButton extends StatelessWidget {
  const HelpButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
        iconSize: 20,
        color: CustomColors.productNormalActive,
        onPressed: () => showPopover(
            context: context,
            bodyBuilder: (context) => Container(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "Active: You have completed at least 1 task on a due day. Due day: A day that you have tasks due.",
                    style: CustomTypography().titleRegular(),
                  ),
                ),
            direction: PopoverDirection.top,
            constraints: BoxConstraints(maxWidth: 220),
            arrowHeight: 0,
            arrowWidth: 0,
            barrierColor: Colors.transparent),
        icon: Icon(Icons.help_outline_rounded));
  }
}
