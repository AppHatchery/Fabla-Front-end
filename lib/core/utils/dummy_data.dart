import 'package:audio_diaries_flutter/screens/diary/data/option.dart';
import 'package:flutter/material.dart';

import '../../screens/diary/data/diary.dart';
import '../../screens/diary/data/options.dart';
import '../../screens/diary/data/prompt.dart';
import '../../screens/diary/data/tag.dart';
import '../../theme/resources/strings.dart';
import 'statuses.dart';
import 'types.dart';

List<Diary> exampleDiaries = [
  Diary(
      id: 0,
      prompts: fakePrompts[0] ?? [],
      tags: fakeTags,
      status: DiaryStatus.idle,
      due: DateTime.now()),
  Diary(
      id: 1,
      prompts: fakePrompts[0] ?? [],
      tags: fakeTags,
      status: DiaryStatus.ongoing,
      due: DateTime.now()),
  Diary(
      id: 2,
      prompts: fakePrompts[0] ?? [],
      tags: fakeTags,
      status: DiaryStatus.submitted,
      due: DateTime.now()),
  Diary(
      id: 3,
      prompts: fakePrompts[0] ?? [],
      tags: fakeTags,
      status: DiaryStatus.complete,
      due: DateTime.now()),
  Diary(
      id: 4,
      prompts: fakePrompts[0] ?? [],
      tags: fakeTags,
      status: DiaryStatus.ongoing,
      due: DateTime.now()),
];

final Map<int, List<Prompt>> fakePrompts = {
  // Day One
  0: [
    Prompt(
      id: 0,
      question: "How do yo FEEL PHYSICALLY right now?",
      responseType: ResponseType.slider,
      option: Options.returnOptions(
          type: OptionsType.slider,
          startText: "Very bad",
          endText: "Very good",
          choices: [
            Option(id: 0, option: "0"),
            Option(id: 1, option: "10"),
          ]),
    ),
    Prompt(
      id: 1,
      question:
          "How do yo FEEL EMOTIONALLY right now? Please use the slider to rate how PLEASANT or UNPLEASANT you feel emotionally:",
      responseType: ResponseType.slider,
      option: Options.returnOptions(
          type: OptionsType.slider,
          startText: "Extremely unpleasant",
          endText: "Extremely pleasant",
          choices: [
            Option(id: 0, option: "-5"),
            Option(id: 1, option: "5"),
          ]),
    ),
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
    ),
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
    ),
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
    ),
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
    ),
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
    ),
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
    ),
    Prompt(
      id: 8,
      question:
          "Which of the following best describes where you are physically right now? Check all that apply.",
      responseType: ResponseType.multiple,
      option: Options.returnOptions(
          type: OptionsType.multiple, choices: multipleOptions),
    ),
    Prompt(
      id: 9,
      question: "How many people are around you right now?",
      responseType: ResponseType.radio,
      option:
          Options.returnOptions(type: OptionsType.radio, choices: radioOptions),
    ),
    Prompt(
      id: 10,
      question:
          "How many drinks of alcohol have you had in the last 24 hours? A drink is 12 ounces of beer, 5 ounces of wine, or 1.5 ounces of distilled spitits.",
      responseType: ResponseType.slider,
      option: Options.returnOptions(
          type: OptionsType.slider,
          startText: "Not at all",
          endText: "A lot",
          choices: [
            Option(id: 0, option: "0"),
            Option(id: 1, option: "12"),
          ]),
    ),
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
      question: "How do yo FEEL PHYSICALLY right now?",
      responseType: ResponseType.slider,
      option: Options.returnOptions(
          type: OptionsType.slider,
          startText: "Very bad",
          endText: "Very good",
          choices: [
            Option(id: 0, option: "0"),
            Option(id: 1, option: "10"),
          ]),
    ),
    Prompt(
      id: 14,
      question:
          "How do yo FEEL EMOTIONALLY right now? Please use the slider to rate how PLEASANT or UNPLEASANT you feel emotionally:",
      responseType: ResponseType.slider,
      option: Options.returnOptions(
          type: OptionsType.slider,
          startText: "Extremely unpleasant",
          endText: "Extremely pleasant",
          choices: [
            Option(id: 0, option: "-5"),
            Option(id: 1, option: "5"),
          ]),
    ),
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
    ),
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
    ),
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
    ),
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
    ),
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
    ),
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
    ),
    Prompt(
      id: 21,
      question:
          "Which of the following best describes where you are physically right now? Check all that apply.",
      responseType: ResponseType.multiple,
      option: Options.returnOptions(
          type: OptionsType.multiple, choices: multipleOptions),
    ),
    Prompt(
      id: 22,
      question: "How many people are around you right now?",
      responseType: ResponseType.radio,
      option:
          Options.returnOptions(type: OptionsType.radio, choices: radioOptions),
    ),
    Prompt(
      id: 23,
      question:
          "How many drinks of alcohol have you had in the last 24 hours? A drink is 12 ounces of beer, 5 ounces of wine, or 1.5 ounces of distilled spitits.",
      responseType: ResponseType.slider,
      option: Options.returnOptions(
          type: OptionsType.slider,
          startText: "Not at all",
          endText: "A lot",
          choices: [
            Option(id: 0, option: "0"),
            Option(id: 1, option: "12"),
          ]),
    ),
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
      question: "How do yo FEEL PHYSICALLY right now?",
      responseType: ResponseType.slider,
      option: Options.returnOptions(
          type: OptionsType.slider,
          startText: "Very bad",
          endText: "Very good",
          choices: [
            Option(id: 0, option: "0"),
            Option(id: 1, option: "10"),
          ]),
    ),
    Prompt(
      id: 27,
      question:
          "How do yo FEEL EMOTIONALLY right now? Please use the slider to rate how PLEASANT or UNPLEASANT you feel emotionally:",
      responseType: ResponseType.slider,
      option: Options.returnOptions(
          type: OptionsType.slider,
          startText: "Extremely unpleasant",
          endText: "Extremely pleasant",
          choices: [
            Option(id: 0, option: "-5"),
            Option(id: 1, option: "5"),
          ]),
    ),
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
    ),
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
    ),
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
    ),
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
    ),
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
    ),
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
    ),
    Prompt(
      id: 34,
      question:
          "Which of the following best describes where you are physically right now? Check all that apply.",
      responseType: ResponseType.multiple,
      option: Options.returnOptions(
          type: OptionsType.multiple, choices: multipleOptions),
    ),
    Prompt(
      id: 35,
      question: "How many people are around you right now?",
      responseType: ResponseType.radio,
      option:
          Options.returnOptions(type: OptionsType.radio, choices: radioOptions),
    ),
    Prompt(
      id: 36,
      question:
          "How many drinks of alcohol have you had in the last 24 hours? A drink is 12 ounces of beer, 5 ounces of wine, or 1.5 ounces of distilled spitits.",
      responseType: ResponseType.slider,
      option: Options.returnOptions(
          type: OptionsType.slider,
          startText: "Not at all",
          endText: "A lot",
          choices: [
            Option(id: 0, option: "0"),
            Option(id: 1, option: "12"),
          ]),
    ),
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
      question: "How do yo FEEL PHYSICALLY right now?",
      responseType: ResponseType.slider,
      option: Options.returnOptions(
          type: OptionsType.slider,
          startText: "Very bad",
          endText: "Very good",
          choices: [
            Option(id: 0, option: "0"),
            Option(id: 1, option: "10"),
          ]),
    ),
    Prompt(
      id: 40,
      question:
          "How do yo FEEL EMOTIONALLY right now? Please use the slider to rate how PLEASANT or UNPLEASANT you feel emotionally:",
      responseType: ResponseType.slider,
      option: Options.returnOptions(
          type: OptionsType.slider,
          startText: "Extremely unpleasant",
          endText: "Extremely pleasant",
          choices: [
            Option(id: 0, option: "-5"),
            Option(id: 1, option: "5"),
          ]),
    ),
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
    ),
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
    ),
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
    ),
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
    ),
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
    ),
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
    ),
    Prompt(
      id: 47,
      question:
          "Which of the following best describes where you are physically right now? Check all that apply.",
      responseType: ResponseType.multiple,
      option: Options.returnOptions(
          type: OptionsType.multiple, choices: multipleOptions),
    ),
    Prompt(
      id: 48,
      question: "How many people are around you right now?",
      responseType: ResponseType.radio,
      option:
          Options.returnOptions(type: OptionsType.radio, choices: radioOptions),
    ),
    Prompt(
      id: 49,
      question:
          "How many drinks of alcohol have you had in the last 24 hours? A drink is 12 ounces of beer, 5 ounces of wine, or 1.5 ounces of distilled spitits.",
      responseType: ResponseType.slider,
      option: Options.returnOptions(
          type: OptionsType.slider,
          startText: "Not at all",
          endText: "A lot",
          choices: [
            Option(id: 0, option: "0"),
            Option(id: 1, option: "12"),
          ]),
    ),
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
      question: "How do yo FEEL PHYSICALLY right now?",
      responseType: ResponseType.slider,
      option: Options.returnOptions(
          type: OptionsType.slider,
          startText: "Very bad",
          endText: "Very good",
          choices: [
            Option(id: 0, option: "0"),
            Option(id: 1, option: "10"),
          ]),
    ),
    Prompt(
      id: 53,
      question:
          "How do yo FEEL EMOTIONALLY right now? Please use the slider to rate how PLEASANT or UNPLEASANT you feel emotionally:",
      responseType: ResponseType.slider,
      option: Options.returnOptions(
          type: OptionsType.slider,
          startText: "Extremely unpleasant",
          endText: "Extremely pleasant",
          choices: [
            Option(id: 0, option: "-5"),
            Option(id: 1, option: "5"),
          ]),
    ),
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
    ),
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
    ),
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
    ),
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
    ),
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
    ),
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
    ),
    Prompt(
      id: 60,
      question:
          "Which of the following best describes where you are physically right now? Check all that apply.",
      responseType: ResponseType.multiple,
      option: Options.returnOptions(
          type: OptionsType.multiple, choices: multipleOptions),
    ),
    Prompt(
      id: 61,
      question: "How many people are around you right now?",
      responseType: ResponseType.radio,
      option:
          Options.returnOptions(type: OptionsType.radio, choices: radioOptions),
    ),
    Prompt(
      id: 62,
      question:
          "How many drinks of alcohol have you had in the last 24 hours? A drink is 12 ounces of beer, 5 ounces of wine, or 1.5 ounces of distilled spitits.",
      responseType: ResponseType.slider,
      option: Options.returnOptions(
          type: OptionsType.slider,
          startText: "Not at all",
          endText: "A lot",
          choices: [
            Option(id: 0, option: "0"),
            Option(id: 1, option: "12"),
          ]),
    ),
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
      question: "How do yo FEEL PHYSICALLY right now?",
      responseType: ResponseType.slider,
      option: Options.returnOptions(
          type: OptionsType.slider,
          startText: "Very bad",
          endText: "Very good",
          choices: [
            Option(id: 0, option: "0"),
            Option(id: 1, option: "10"),
          ]),
    ),
    Prompt(
      id: 66,
      question:
          "How do yo FEEL EMOTIONALLY right now? Please use the slider to rate how PLEASANT or UNPLEASANT you feel emotionally:",
      responseType: ResponseType.slider,
      option: Options.returnOptions(
          type: OptionsType.slider,
          startText: "Extremely unpleasant",
          endText: "Extremely pleasant",
          choices: [
            Option(id: 0, option: "-5"),
            Option(id: 1, option: "5"),
          ]),
    ),
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
    ),
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
    ),
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
    ),
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
    ),
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
    ),
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
    ),
    Prompt(
      id: 73,
      question:
          "Which of the following best describes where you are physically right now? Check all that apply.",
      responseType: ResponseType.multiple,
      option: Options.returnOptions(
          type: OptionsType.multiple, choices: multipleOptions),
    ),
    Prompt(
      id: 74,
      question: "How many people are around you right now?",
      responseType: ResponseType.radio,
      option:
          Options.returnOptions(type: OptionsType.radio, choices: radioOptions),
    ),
    Prompt(
      id: 75,
      question:
          "How many drinks of alcohol have you had in the last 24 hours? A drink is 12 ounces of beer, 5 ounces of wine, or 1.5 ounces of distilled spitits.",
      responseType: ResponseType.slider,
      option: Options.returnOptions(
          type: OptionsType.slider,
          startText: "Not at all",
          endText: "A lot",
          choices: [
            Option(id: 0, option: "0"),
            Option(id: 1, option: "12"),
          ]),
    ),
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

const TimeOfDay fixedTime = TimeOfDay(hour: 9, minute: 0);

final List<String> studyCodes = [
  "X8R3Z9",
  "P2F7G6",
  "Q9S5T2",
  "E6D1C4",
  "M7N0B8",
  "H4J6K5",
  "V5W8L3",
  "A3E2R1",
  "T0U9F7",
  "Y1I4O2",
  "B8Q3X6",
  "L2Z7P9",
  "G9M5S2",
  "C6K1D4",
  "N7H0J8",
  "O4V6L5",
  "W5A8E3",
  "F3T2U1",
  "R0Y9I7",
  "X1B4Q6",
  "P8N2Z7",
  "Q5E9M3",
  "H2C6K5",
  "M9L0J8",
  "S6V4W3",
  "B1R3X6",
  "T7G2F9",
  "O4U1Y2",
  "I8D7C5",
  "K5F2T1",
  "J2W9A0",
  "V6Z8P3",
  "E3B4Q7",
  "N0M6H5",
  "L7K1D9",
  "C4S2T8",
  "X1R9I0",
  "P8U6Y2",
  "Q5G3F7",
  "H2N1B6",
  "M9W8L4",
  "S6E5C3",
  "B3K7J0",
  "T0Z9A8",
  "O7Q6X4",
  "I4M2H1",
  "F1T8U5",
  "R8D0Y3",
  "C5B4P6",
  "V2G9Z1",
  "N9K7S3",
  "L6H2C8",
  "W3J1V0",
  "E0N5M4",
  "Y7W6A9",
  "K4Z3P8",
  "J1R2X0",
  "U8T9F6",
  "G5I7O4",
  "X2E4B1",
  "P9Q7Z5",
  "Q6U3L0",
  "H3M2S9",
  "T0K9D8",
  "O7J5C1",
  "I4W8V6",
  "F1A0G3",
  "R8Z6P2",
  "C5X4N9",
  "V2B1T7",
  "N9R7H5",
  "L6U2F8",
  "W3M1Y0",
  "E0K5J4",
  "Y7D3C9",
  "K4G9Q6",
  "J1N8Z2",
  "U8L7X0",
  "G5V6W4",
  "X2S1P3",
  "P9I0O7",
  "Q6F5B2",
  "H3T2U8",
  "T0R9E6",
  "O7Y4A1",
  "I4Q1C8",
  "F1X0N5",
  "R8M7K3",
  "C5J6H9",
  "V2W5D4",
  "N9G4V0",
  "L6U3Z8",
  "W3N2P1",
  "E0L9S7",
  "Y7K8B6",
  "K4F7T2",
  "J1R6U0",
  "U8O5I3",
  "G5D2Q9",
  "X2C1E8",
  "P9Z0M6",
  "Q6P5H4",
  "H3W4J2",
  "T0V9F1",
  "O7B6N8",
  "I4K3T7",
  "F1Z2A0",
  "R8Q1X9",
  "C5U0O6",
  "V2I9G7",
  "N9E8Y5",
  "L6M7C4",
  "W3H6U2",
  "E0T5W1",
  "Y7R4P0",
  "K4D3B9",
  "J1A2N6",
  "U8X1L5",
  "G5K0F8",
  "X2V9S7",
  "P9N8J6",
  "Q6L7Y5",
  "H3U6T4",
  "T0M5K3",
  "O7H4Z2",
  "I4E3X1",
  "F1B2Q0",
  "R8W9O9",
  "C5P8I7",
  "V2F7G6",
  "N9T6U5",
  "L6O5N4",
  "W3M4L3",
  "E0K3J2",
  "Y7H2D1",
  "K4G1C0",
  "J1V9B9",
  "U8Q8Z7",
  "G5N7P6",
  "X2M6S5",
  "P9J5H4",
  "Q6U4T3",
  "H3G3R2",
  "T0E2Q1",
  "O7B1P0",
  "I4Y9N9",
  "F1X8L8",
  "R8W7K6",
  "C5T6I5",
  "V2O5G4",
  "1000",
  "1001",
  "1002",
  "1003",
  "1004",
  "1005",
  "1006",
  "1007",
  "1008",
  "1009",
  "1010",
  "2000",
  "2001",
  "2002",
  "2003",
  "2004",
  "2005",
  "2006",
  "2007",
  "2008",
  "2009",
  "2010",
  "0000"
];
