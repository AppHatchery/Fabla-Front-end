import 'package:audio_diaries_flutter/screens/diary/data/option.dart';
import 'package:flutter/material.dart';

import '../../screens/diary/data/diary.dart';
import '../../screens/diary/data/options.dart';
import '../../screens/diary/data/prompt.dart';
import '../../screens/diary/data/tag.dart';
import '../../theme/resources/strings.dart';
import 'statuses.dart';
import 'types.dart';

final List<Diary> dummyDiaries = [
  Diary(
      id: 0,
      prompts: fakePrompts[0] ?? [],
      tags: fakeTags,
      status: DiaryStatus.idle,
      start: DateTime.now(),
      due: DateTime.now()),
  Diary(
      id: 1,
      prompts: fakePrompts[0] ?? [],
      tags: fakeTags,
      status: DiaryStatus.ongoing,
      start: DateTime.now(),
      due: DateTime.now()),
  Diary(
      id: 2,
      prompts: fakePrompts[0] ?? [],
      tags: fakeTags,
      status: DiaryStatus.submitted,
      start: DateTime.now(),
      due: DateTime.now()),
  Diary(
      id: 3,
      prompts: fakePrompts[0] ?? [],
      tags: fakeTags,
      status: DiaryStatus.complete,
      start: DateTime.now(),
      due: DateTime.now()),
  Diary(
      id: 4,
      prompts: fakePrompts[0] ?? [],
      tags: fakeTags,
      status: DiaryStatus.ongoing,
      start: DateTime.now(),
      due: DateTime.now()),
];

List<Diary> exampleDiaries = [
  Diary(
      id: 0,
      prompts: fakePrompts[0] ?? [],
      tags: fakeTags,
      status: DiaryStatus.idle,
      start: DateTime.now(),
      due: DateTime.now()),
  Diary(
      id: 1,
      prompts: fakePrompts[0] ?? [],
      tags: fakeTags,
      status: DiaryStatus.ongoing,
      start: DateTime.now(),
      due: DateTime.now()),
  Diary(
      id: 2,
      prompts: fakePrompts[0] ?? [],
      tags: fakeTags,
      status: DiaryStatus.submitted,
      start: DateTime.now(),
      due: DateTime.now()),
  Diary(
      id: 3,
      prompts: fakePrompts[0] ?? [],
      tags: fakeTags,
      status: DiaryStatus.complete,
      start: DateTime.now(),
      due: DateTime.now()),
  Diary(
      id: 4,
      prompts: fakePrompts[0] ?? [],
      tags: fakeTags,
      status: DiaryStatus.ongoing,
      start: DateTime.now(),
      due: DateTime.now()),
];

final Map<int, List<Prompt>> fakePrompts = {
  // Day One
  0: [
    Prompt(
        id: 0,
        question: "How do you FEEL PHYSICALLY right now?",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Very bad",
            endText: "Very good",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.physically),
    Prompt(
        id: 1,
        question:
            "How do you FEEL EMOTIONALLY right now? Please use the slider to rate how PLEASANT or UNPLEASANT you feel emotionally:",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Extremely unpleasant",
            endText: "Extremely pleasant",
            choices: [
              Option(id: 0, option: "-5"),
              Option(id: 1, option: "5"),
            ]),
        questionType: QuestionType.emotionally),
    Prompt(
        id: 2,
        question:
            "Please use the slider to rate the INTENSITY of the overall emotion you are experiencing right now",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Least intense",
            endText: "Most intense",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.intensity),
    Prompt(
        id: 3,
        question: "I felt lonely today.",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "Extremely",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.lonely),
    Prompt(
        id: 4,
        question: "I felt left out today.",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "Extremely",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.leftout),
    Prompt(
        id: 5,
        question: "How much social interaction did you have today?",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "A lot",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.socialinteraction),
    Prompt(
        id: 6,
        question: "I felt understood/cared for by others today.",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "A lot",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.understood),
    Prompt(
        id: 7,
        question: "I felt stressed today.",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "A lot",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.stressed),
    Prompt(
        id: 8,
        question:
            "Which of the following best describes where you are physically right now? Check all that apply.",
        responseType: ResponseType.multiple,
        option: Options.returnOptions(
            type: OptionsType.multiple, choices: multipleOptions),
        questionType: QuestionType.whereyouare),
    Prompt(
        id: 9,
        question: "How many people are around you right now?",
        responseType: ResponseType.radio,
        option: Options.returnOptions(
            type: OptionsType.radio, choices: radioOptions),
        questionType: QuestionType.peoplearoundyou),
    Prompt(
      id: 11,
      question: "Talk about your day today.",
      responseType: ResponseType.recording,
      note: Strings.researcherNote,
    ),
    Prompt(
      id: 12,
      question:
          "Talk about a time today when you felt understood or cared for by others, no matter how small.",
      responseType: ResponseType.recording,
      note: Strings.researcherNoteTwo,
    ),
  ],
  // Day Two
  1: [
    Prompt(
        id: 13,
        question: "How do you FEEL PHYSICALLY right now?",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Very bad",
            endText: "Very good",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.physically),
    Prompt(
        id: 14,
        question:
            "How do you FEEL EMOTIONALLY right now? Please use the slider to rate how PLEASANT or UNPLEASANT you feel emotionally:",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Extremely unpleasant",
            endText: "Extremely pleasant",
            choices: [
              Option(id: 0, option: "-5"),
              Option(id: 1, option: "5"),
            ]),
        questionType: QuestionType.emotionally),
    Prompt(
        id: 15,
        question:
            "Please use the slider to rate the INTENSITY of the overall emotion you are experiencing right now",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Least intense",
            endText: "Most intense",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.intensity),
    Prompt(
        id: 16,
        question: "I felt lonely today.",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "Extremely",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.lonely),
    Prompt(
        id: 17,
        question: "I felt left out today.",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "Extremely",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.leftout),
    Prompt(
        id: 18,
        question: "How much social interaction did you have today?",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "A lot",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.socialinteraction),
    Prompt(
        id: 19,
        question: "I felt understood/cared for by others today.",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "A lot",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.understood),
    Prompt(
        id: 20,
        question: "I felt stressed today.",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "A lot",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.stressed),
    Prompt(
        id: 21,
        question:
            "Which of the following best describes where you are physically right now? Check all that apply.",
        responseType: ResponseType.multiple,
        option: Options.returnOptions(
            type: OptionsType.multiple, choices: multipleOptions),
        questionType: QuestionType.whereyouare),
    Prompt(
        id: 22,
        question: "How many people are around you right now?",
        responseType: ResponseType.radio,
        option: Options.returnOptions(
            type: OptionsType.radio, choices: radioOptions),
        questionType: QuestionType.peoplearoundyou),
    Prompt(
      id: 24,
      question: "Talk about your day today.",
      responseType: ResponseType.recording,
      note: Strings.researcherNote,
    ),
    Prompt(
      id: 25,
      question:
          "Talk about a time today when you felt understood or cared for by others, no matter how small.",
      responseType: ResponseType.recording,
      note: Strings.researcherNoteTwo,
    ),
  ],
  // Day Three
  2: [
    Prompt(
        id: 26,
        question: "How do you FEEL PHYSICALLY right now?",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Very bad",
            endText: "Very good",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.physically),
    Prompt(
        id: 27,
        question:
            "How do you FEEL EMOTIONALLY right now? Please use the slider to rate how PLEASANT or UNPLEASANT you feel emotionally:",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Extremely unpleasant",
            endText: "Extremely pleasant",
            choices: [
              Option(id: 0, option: "-5"),
              Option(id: 1, option: "5"),
            ]),
        questionType: QuestionType.emotionally),
    Prompt(
        id: 28,
        question:
            "Please use the slider to rate the INTENSITY of the overall emotion you are experiencing right now",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Least intense",
            endText: "Most intense",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.intensity),
    Prompt(
        id: 29,
        question: "I felt lonely today.",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "Extremely",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.lonely),
    Prompt(
        id: 30,
        question: "I felt left out today.",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "Extremely",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.leftout),
    Prompt(
        id: 31,
        question: "How much social interaction did you have today?",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "A lot",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.socialinteraction),
    Prompt(
        id: 32,
        question: "I felt understood/cared for by others today.",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "A lot",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.understood),
    Prompt(
        id: 33,
        question: "I felt stressed today.",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "A lot",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.stressed),
    Prompt(
        id: 34,
        question:
            "Which of the following best describes where you are physically right now? Check all that apply.",
        responseType: ResponseType.multiple,
        option: Options.returnOptions(
            type: OptionsType.multiple, choices: multipleOptions),
        questionType: QuestionType.whereyouare),
    Prompt(
        id: 35,
        question: "How many people are around you right now?",
        responseType: ResponseType.radio,
        option: Options.returnOptions(
            type: OptionsType.radio, choices: radioOptions),
        questionType: QuestionType.peoplearoundyou),
    Prompt(
      id: 37,
      question: "Talk about your day today.",
      responseType: ResponseType.recording,
      note: Strings.researcherNote,
    ),
    Prompt(
      id: 38,
      question:
          "Talk about a time today when you felt understood or cared for by others, no matter how small.",
      responseType: ResponseType.recording,
      note: Strings.researcherNoteTwo,
    ),
  ],
  // Day Four
  3: [
    Prompt(
        id: 39,
        question: "How do you FEEL PHYSICALLY right now?",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Very bad",
            endText: "Very good",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.physically),
    Prompt(
        id: 40,
        question:
            "How do you FEEL EMOTIONALLY right now? Please use the slider to rate how PLEASANT or UNPLEASANT you feel emotionally:",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Extremely unpleasant",
            endText: "Extremely pleasant",
            choices: [
              Option(id: 0, option: "-5"),
              Option(id: 1, option: "5"),
            ]),
        questionType: QuestionType.emotionally),
    Prompt(
        id: 41,
        question:
            "Please use the slider to rate the INTENSITY of the overall emotion you are experiencing right now",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Least intense",
            endText: "Most intense",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.intensity),
    Prompt(
        id: 42,
        question: "I felt lonely today.",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "Extremely",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.lonely),
    Prompt(
        id: 43,
        question: "I felt left out today.",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "Extremely",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.leftout),
    Prompt(
        id: 44,
        question: "How much social interaction did you have today?",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "A lot",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.socialinteraction),
    Prompt(
        id: 45,
        question: "I felt understood/cared for by others today.",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "A lot",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.understood),
    Prompt(
        id: 46,
        question: "I felt stressed today.",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "A lot",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.stressed),
    Prompt(
        id: 47,
        question:
            "Which of the following best describes where you are physically right now? Check all that apply.",
        responseType: ResponseType.multiple,
        option: Options.returnOptions(
            type: OptionsType.multiple, choices: multipleOptions),
        questionType: QuestionType.whereyouare),
    Prompt(
        id: 48,
        question: "How many people are around you right now?",
        responseType: ResponseType.radio,
        option: Options.returnOptions(
            type: OptionsType.radio, choices: radioOptions),
        questionType: QuestionType.peoplearoundyou),
    Prompt(
      id: 50,
      question: "Talk about your day today.",
      responseType: ResponseType.recording,
      note: Strings.researcherNote,
    ),
    Prompt(
      id: 51,
      question:
          "Talk about a time today when you felt understood or cared for by others, no matter how small.",
      responseType: ResponseType.recording,
      note: Strings.researcherNoteTwo,
    ),
  ],
  // Day Five
  4: [
    Prompt(
        id: 52,
        question: "How do you FEEL PHYSICALLY right now?",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Very bad",
            endText: "Very good",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.physically),
    Prompt(
        id: 53,
        question:
            "How do you FEEL EMOTIONALLY right now? Please use the slider to rate how PLEASANT or UNPLEASANT you feel emotionally:",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Extremely unpleasant",
            endText: "Extremely pleasant",
            choices: [
              Option(id: 0, option: "-5"),
              Option(id: 1, option: "5"),
            ]),
        questionType: QuestionType.emotionally),
    Prompt(
        id: 54,
        question:
            "Please use the slider to rate the INTENSITY of the overall emotion you are experiencing right now",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Least intense",
            endText: "Most intense",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.intensity),
    Prompt(
        id: 55,
        question: "I felt lonely today.",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "Extremely",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.lonely),
    Prompt(
        id: 56,
        question: "I felt left out today.",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "Extremely",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.leftout),
    Prompt(
        id: 57,
        question: "How much social interaction did you have today?",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "A lot",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.socialinteraction),
    Prompt(
        id: 58,
        question: "I felt understood/cared for by others today.",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "A lot",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.understood),
    Prompt(
        id: 59,
        question: "I felt stressed today.",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "A lot",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.stressed),
    Prompt(
        id: 60,
        question:
            "Which of the following best describes where you are physically right now? Check all that apply.",
        responseType: ResponseType.multiple,
        option: Options.returnOptions(
            type: OptionsType.multiple, choices: multipleOptions),
        questionType: QuestionType.whereyouare),
    Prompt(
        id: 61,
        question: "How many people are around you right now?",
        responseType: ResponseType.radio,
        option: Options.returnOptions(
            type: OptionsType.radio, choices: radioOptions),
        questionType: QuestionType.peoplearoundyou),
    Prompt(
      id: 63,
      question: "Talk about your day today.",
      responseType: ResponseType.recording,
      note: Strings.researcherNote,
    ),
    Prompt(
      id: 64,
      question:
          "Talk about a time today when you felt understood or cared for by others, no matter how small.",
      responseType: ResponseType.recording,
      note: Strings.researcherNoteTwo,
    ),
  ],
  // Day Six
  5: [
    Prompt(
        id: 65,
        question: "How do you FEEL PHYSICALLY right now?",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Very bad",
            endText: "Very good",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.physically),
    Prompt(
        id: 66,
        question:
            "How do you FEEL EMOTIONALLY right now? Please use the slider to rate how PLEASANT or UNPLEASANT you feel emotionally:",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Extremely unpleasant",
            endText: "Extremely pleasant",
            choices: [
              Option(id: 0, option: "-5"),
              Option(id: 1, option: "5"),
            ]),
        questionType: QuestionType.emotionally),
    Prompt(
        id: 67,
        question:
            "Please use the slider to rate the INTENSITY of the overall emotion you are experiencing right now",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Least intense",
            endText: "Most intense",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.intensity),
    Prompt(
        id: 68,
        question: "I felt lonely today.",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "Extremely",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.lonely),
    Prompt(
        id: 69,
        question: "I felt left out today.",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "Extremely",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.leftout),
    Prompt(
        id: 70,
        question: "How much social interaction did you have today?",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "A lot",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.socialinteraction),
    Prompt(
        id: 71,
        question: "I felt understood/cared for by others today.",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "A lot",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.understood),
    Prompt(
        id: 72,
        question: "I felt stressed today.",
        responseType: ResponseType.slider,
        option: Options.returnOptions(
            type: OptionsType.slider,
            startText: "Not at all",
            endText: "A lot",
            choices: [
              Option(id: 0, option: "0"),
              Option(id: 1, option: "10"),
            ]),
        questionType: QuestionType.stressed),
    Prompt(
        id: 73,
        question:
            "Which of the following best describes where you are physically right now? Check all that apply.",
        responseType: ResponseType.multiple,
        option: Options.returnOptions(
            type: OptionsType.multiple, choices: multipleOptions),
        questionType: QuestionType.whereyouare),
    Prompt(
        id: 74,
        question: "How many people are around you right now?",
        responseType: ResponseType.radio,
        option: Options.returnOptions(
            type: OptionsType.radio, choices: radioOptions),
        questionType: QuestionType.peoplearoundyou),
    Prompt(
      id: 76,
      question: "Talk about your day today.",
      responseType: ResponseType.recording,
      note: Strings.researcherNote,
    ),
    Prompt(
      id: 77,
      question:
          "Talk about a time today when you felt understood or cared for by others, no matter how small.",
      responseType: ResponseType.recording,
      note: Strings.researcherNoteTwo,
    ),
  ],
};

final List<Option> multipleOptions = [
  Option(id: 0, option: "At home or in my dorm room"),
  Option(id: 1, option: "In someone else's home or dorm room"),
  Option(id: 2, option: "In a car, bus, or other form of transportation"),
  Option(id: 3, option: "Outside"),
  Option(id: 4, option: "In a public place(eg., library, restaurant airport)"),
];

final List<Option> radioOptions = [
  Option(id: 0, option: "0"),
  Option(id: 1, option: "1"),
  Option(id: 2, option: "2"),
  Option(id: 3, option: "3"),
  Option(id: 4, option: "4 or more"),
];

List<Tag> fakeTags = const [
  Tag(text: "60 seconds", type: TagType.time),
  Tag(text: "Multiple questions", type: TagType.questions),
];

const Tag missedTag = Tag(text: "Missed", type: TagType.time);
const Tag onGoingTag = Tag(text: "Ongoing", type: TagType.time);
const Tag doneTag = Tag(text: "Done", type: TagType.time);

const TimeOfDay fixedTime = TimeOfDay(hour: 9, minute: 0);

final List<int> participantCodes = [
  1010,
  1011,
  1012,
  1013,
  1014,
  1015,
  1016,
  1017,
  1018,
  1019,
  1020,
  1021,
  1022,
  1023,
  1024,
  1025,
  1026,
  1027,
  1028,
  1029,
  1030,
  1031,
  1032,
  1033,
  1034,
  1035,
  1036,
  1037,
  1038,
  1039,
  1040,
  1041,
  1042,
  1043,
  1044,
  1045,
  1046,
  1047,
  1048,
  1049,
  1050,
  1051,
  1052,
  1053,
  1054,
  1055,
  1056,
  1057,
  1058,
  1059,
  1060,
  1061,
  1062,
  1063,
  1064,
  1065,
  1066,
  1067,
  1068,
  1069,
  1070,
  1071,
  1072,
  1073,
  1074,
  1075,
  1076,
  1077,
  1078,
  1079,
  1080,
  1081,
  1082,
  1083,
  1084,
  1085,
  1086,
  1087,
  1088,
  1089,
  1090,
  1091,
  1092,
  1093,
  1094,
  1095,
  1096,
  1097,
  1098,
  1099,
  1100,
  1101,
  1102,
  1103,
  1104,
  1105,
  1106,
  1107,
  1108,
  1109,
  1110,
  1111,
  1112,
  1113,
  1114,
  1115,
  1116,
  1117,
  1118,
  1119,
  1120,
  1121,
  1122,
  1123,
  1124,
  1125,
  1126,
  1127,
  1128,
  1129,
  1130,
  1131,
  1132,
  1133,
  1134,
  1135,
  1136,
  1137,
  1138,
  1139,
  1140,
  1141,
  1142,
  1143,
  1144,
  1145,
  1146,
  1147,
  1148,
  1149,
  1150,
  1151,
  1152,
  1153,
  1154,
  1155,
  1156,
  1157,
  1158,
  1159,
  1160,
  1161,
  1162,
  1163,
  1164,
  1165,
  1166,
  1167,
  1168,
  1169,
  1170,
  1171,
  1172,
  1173,
  1174,
  1175,
  1176,
  1177,
  1178,
  1179,
  1180,
  1181,
  1182,
  1183,
  1184,
  1185,
  1186,
  1187,
  1188,
  1189,
  1190,
  1191,
  1192,
  1193,
  1194,
  1195,
  1196,
  1197,
  1198,
  1199,
  1200,
  1201,
  1202,
  1203,
  1204,
  1205,
  1206,
  1207,
  1208,
  1209,
  1210,
  1211,
  1212,
  1213,
  1214,
  1215,
  1216,
  1217,
  1218,
  1219,
  1220,
  1221,
  1222,
  1223,
  1224,
  1225,
  1226,
  1227,
  1228,
  1229,
  1230,
  1231,
  1232,
  1233,
  1234,
  1235,
  1236,
  1237,
  1238,
  1239,
  1240,
  1241,
  1242,
  1243,
  1244,
  1245,
  1246,
  1247,
  1248,
  1249,
  1250,
  1251,
  1252,
  1253,
  1254,
  1255,
  1256,
  1257,
  1258,
];
