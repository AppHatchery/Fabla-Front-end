import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
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
  final DiaryModel diary;
  final PromptModel prompt;
  final List<Recording> recordings;
  final void Function(String) edit;

  const MyResponse({
    super.key,
    required this.edit,
    required this.diary,
    required this.prompt,
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
        widget.prompt.answer!.recordings.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: TextAnswerCard(
                  isVisible: true,
                  edit: widget.edit,
                  answer: widget.prompt.answer!.response!,
                  callerWidget: "diary",
                  delete: () => deleteResponse(widget.prompt, ''),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.recordings.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: NewAudioCard(
                      isVisible: true,
                      recording: widget.recordings[index],
                      delete: () => deleteResponse(
                          widget.prompt, widget.recordings[index].path),
                      viewOnly: false,
                      promptId: widget.prompt.id,
                      callerWidget: "diary",
                    ),
                  );
                }),
        const SizedBox(height: 12),
      ],
    );
  }

  void deleteResponse(PromptModel loadedPrompt, String path) {
    final promptCubit = context.read<PromptCubit>();
    promptCubit.removeResponse(
        diary: widget.diary, path: path, prompt: loadedPrompt);
  }
}
