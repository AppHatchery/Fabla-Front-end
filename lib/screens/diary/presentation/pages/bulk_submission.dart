import 'package:audio_diaries_flutter/main.dart';
import 'package:audio_diaries_flutter/screens/diary/data/bulk_submission.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/bulk_submission/bulk_submission_cubit.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/pages/diarycompletion.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/circle_transition_clipper.dart';
import 'package:audio_diaries_flutter/screens/hub/presentation/cubit/hub_cubit.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart'
    show CustomOutlineButton, CustomFlatButton;
import 'package:audio_diaries_flutter/theme/components/cards.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class BulkSubmissionPage extends StatefulWidget {
  final List<DiarySubmission> submissions;
  const BulkSubmissionPage({super.key, required this.submissions});

  @override
  State<BulkSubmissionPage> createState() => _BulkSubmissionPageState();
}

class _BulkSubmissionPageState extends State<BulkSubmissionPage> {
  late BulkSubmissionCubit _cubit;
  late HubCubit _hubCubit;

  bool? complete;
  bool retry = false;
  int failed = 0;

  @override
  void initState() {
    _cubit = BlocProvider.of<BulkSubmissionCubit>(context);
    _hubCubit = BlocProvider.of<HubCubit>(context);
    _cubit.startBulkSubmission(widget.submissions);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: complete ?? false,
      child: Scaffold(
        backgroundColor: CustomColors.fillNormal,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: CustomColors.fillNormal,
          scrolledUnderElevation: 0.0,
          title: Text(
            "Entries to be uploaded",
            style: CustomTypography()
                .headlineMedium(color: CustomColors.textNormalContent),
          ),
          centerTitle: false,
        ),
        body: SafeArea(
            child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            spacing: 12,
            children: [
              Expanded(
                  child: BlocConsumer<BulkSubmissionCubit, BulkSubmissionState>(
                      builder: (context, state) {
                if (state is BulkSubmissionInProgress) {
                  return content(state.diaries);
                } else if (state is BulkSubmissionFailed) {
                  return content(state.diaries);
                }

                return CircularProgressIndicator();
              }, listener: (context, state) {
                if (state is BulkSubmissionSuccess) {
                  if (mounted) {
                    setState(() {
                      complete = true;
                    });

                    _hubCubit.refresh();
                    goToCompletion();
                  }
                } else if (state is BulkSubmissionFailed) {
                  if (mounted) {
                    setState(() {
                      complete = false;
                      retry = true;
                      failed = state.failedCount;
                    });
                  }
                }
              })),
              CustomFlatButton(
                isDisabled: !retry,
                onClick: () {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const Hub(),
                          settings: RouteSettings(name: "/Hub")),
                      (route) => false);
                },
                text: "Return Home",
                color: CustomColors.productNormal,
                textColor: CustomColors.textWhite,
              ),
            ],
          ),
        )),
      ),
    );
  }

  Widget content(List<DiarySubmission> items) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 24,
        children: [banner(items), diaries(items)],
      ),
    );
  }

  Widget diaries(List<DiarySubmission> items) {
    return ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(0),
        shrinkWrap: true,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: PendingSubmissionSmallCard(
              diary: item.diary,
              study: item.study,
              status: item.status,
            ),
          );
        });
  }

  Widget banner(List<DiarySubmission> items) {
    final width = MediaQuery.of(context).size.width;

    final text = 'Please wait until all your submissions are uploaded.';

    final retryText = Intl.plural(
      failed,
      other:
          "$failed diary submissions could not be uploaded and are still pending",
      one: "1 diary submission could not be uploaded and is still pending",
    );
    final buttonText = 'Retry Upload';

    final color =
        retry ? CustomColors.warningNormal : CustomColors.productNormalActive;
    final backgroundColor =
        retry ? CustomColors.warningFill : Color(0xFFD0DEF4);

    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 2, color: color),
          borderRadius: BorderRadius.circular(11),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              retry
                  ? Icon(
                      CupertinoIcons.clear_circled,
                      size: 24,
                      color: color,
                    )
                  : Image.asset(
                      'assets/images/icons/arrow_upload_progress.png',
                      height: 24,
                      width: 24,
                    ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Text(
                        retry ? 'Upload Failed' : "Uploading in Progress",
                        style:
                            CustomTypography().titleSmallCustom(color: color),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 0, vertical: 2),
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        ),
                        child: Text(
                          retry ? retryText : text,
                          style: CustomTypography().bodyLarge(color: color),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
          retry
              ? Padding(
                  padding: const EdgeInsets.only(left: 40.0, top: 12),
                  child: CustomOutlineButton(
                    onClick: () => retryUpload(items),
                    backgroundColor: color,
                    color: color,
                    borderRadius: 12,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 4.0),
                    children: Wrap(children: [
                      Text(
                        buttonText,
                        style: CustomTypography()
                            .button(color: CustomColors.textWhite),
                      )
                    ]),
                  ),
                )
              : const SizedBox.shrink()
        ],
      ),
    );
  }

  void retryUpload(List<DiarySubmission> submissions) {
    setState(() {
      complete = false;
      retry = false;
    });
    _cubit.retryFailedSubmissions(submissions);
  }

  void goToCompletion() {
    Navigator.of(context).pushReplacement(_completionRoute());
  }

  Route _completionRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const DiaryCompletionPage(),
      transitionDuration: const Duration(milliseconds: 1200),
      reverseTransitionDuration: const Duration(milliseconds: 1200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var screenSize = MediaQuery.of(context).size;
        var centerCircleClipper =
            Offset(screenSize.width / 2, screenSize.height / 2);

        double beginRadius = 0.0;
        double endRadius = screenSize.height * 1.2;

        var radiusTween = Tween(begin: beginRadius, end: endRadius);
        var radiusTweenAnimation = animation.drive(radiusTween);

        return ClipPath(
          clipper: CircleTransitionClipper(
              center: centerCircleClipper, radius: radiusTweenAnimation.value),
          child: child,
        );
      },
    );
  }
}
