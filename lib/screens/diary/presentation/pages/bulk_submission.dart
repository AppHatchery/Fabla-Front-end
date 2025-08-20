import 'package:audio_diaries_flutter/screens/diary/data/bulk_submission.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/bulk_submission/bulk_submission_cubit.dart';
import 'package:audio_diaries_flutter/screens/hub/presentation/cubit/hub_cubit.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart'
    show CustomOutlineButton;
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
            "Pending Submissions",
            style: CustomTypography()
                .headlineMedium(color: CustomColors.textNormalContent),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
            child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              spacing: 12,
              children: [
                banner(),
                BlocConsumer<BulkSubmissionCubit, BulkSubmissionState>(
                    builder: (context, state) {
                  if (state is BulkSubmissionInProgress) {
                    return diaries(state.diaries);
                  } else if (state is BulkSubmissionFailed) {
                    retry = true;
                    failed = state.failedCount;
                    return diaries(state.diaries);
                  }

                  return CircularProgressIndicator();
                }, listener: (context, state) {
                  if (state is BulkSubmissionSuccess) {
                    if (mounted) {
                      setState(() {
                        complete = true;
                      });

                      _hubCubit.refresh();
                      Navigator.pop(context);
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
                }),
              ],
            ),
          ),
        )),
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

  Widget banner() {
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
                    onClick: () => null,
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
}
