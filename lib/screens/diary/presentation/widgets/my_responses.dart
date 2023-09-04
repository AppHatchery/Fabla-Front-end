import 'dart:ffi';

import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../theme/components/cards.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';
import '../../data/prompt.dart';
import '../../domain/entities/recording.dart';
import '../cubit/prompt/prompt_cubit.dart';

/// This class is the UI element that is displayed when the user selects the option "RECORD RESPONSE"
/// and has recorded an audio
/// it displays the Audio that the user has recorded
/// and a button for them to add a new response(no functionality yet)
/// the My response section, to be changed into a  list in case of multiple responses
class MyResponse extends StatefulWidget {
  final Prompt prompt;
  final DiaryStatus status;
  final List<Recording> recordings;

  const MyResponse({
    super.key,
    required this.prompt,
    required this.status,
    required this.recordings,
  });

  @override
  State<MyResponse> createState() => _MyResponseState();
}

class _MyResponseState extends State<MyResponse> {
   int? expandedCardId;

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "My Response",
          style: CustomTypography()
              .titleLarge(color: CustomColors.textNormalContent),
        ),
        const SizedBox(height: 12),
        ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.recordings.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: AudioDiaryCard(
                  recording: widget.recordings[index],
                  delete: () => deleteResponse(
                      widget.prompt, widget.recordings[index].path),
                  viewOnly: widget.status == DiaryStatus.submitted,
                  isExpanded: expandedCardId == widget.recordings[index].id,
                  onTap: () {
                    setState(() {
                      expandedCardId = expandedCardId == widget.recordings[index].id ? null : widget.recordings[index].id;
                    });
                  },
                ),
              );
            }
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  void deleteResponse(Prompt loadedPrompt, String path) {
    final promptCubit = context.read<PromptCubit>();
    promptCubit.removeResponse(loadedPrompt, path);
  }
}
