import '../../screens/diary/data/diary.dart';
import '../../screens/diary/data/prompt.dart';
import '../../screens/diary/data/tag.dart';
import 'statuses.dart';
import 'types.dart';

List<Diary> exampleDiaries = [
  Diary(id: 0, prompts: fakePrompts, tags: fakeTags,status: DiaryStatus.idle, due: DateTime.now()),
  Diary(id: 1, prompts: fakePrompts, tags: fakeTags,status: DiaryStatus.ongoing, due: DateTime.now()),
  Diary(id: 2, prompts: fakePrompts, tags: fakeTags,status: DiaryStatus.submitted, due: DateTime.now()),
  Diary(id: 3, prompts: fakePrompts, tags: fakeTags,status: DiaryStatus.complete, due: DateTime.now()),
  Diary(id: 4, prompts: fakePrompts, tags: fakeTags,status: DiaryStatus.ongoing, due: DateTime.now()),
];

final List<Prompt> fakePrompts = [
    Prompt(
      id: 0,
      question: "How was your day?",
      responseType: ResponseType.recording,
    ),
    Prompt(
      id: 1,
      question: "How did you overcome an embarrassing moment today",
      responseType: ResponseType.recording,
    ),
    Prompt(
      id: 2,
      question: "How was your day?",
      responseType: ResponseType.recording,
    ),
    Prompt(
      id: 3,
      question: "How did you overcome an embarrassing moment today",
      responseType: ResponseType.recording,
    ),
    Prompt(
      id: 4,
      question: "How was your day?",
      responseType: ResponseType.recording,
    ),
    Prompt(
      id: 5,
      question: "How did you overcome an embarrassing moment today",
      responseType: ResponseType.recording,
    ),
    Prompt(
      id: 6,
      question: "How was your day?",
      responseType: ResponseType.recording,
    ),
    Prompt(
      id: 7,
      question: "How did you overcome an embarrassing moment today",
      responseType: ResponseType.recording,
    ),
    Prompt(
      id: 8,
      question: "How was your day?",
      responseType: ResponseType.recording,
    ),
    Prompt(
      id: 9,
      question: "How did you overcome an embarrassing moment today",
      responseType: ResponseType.recording,
    ),
  ];
List<Tag> fakeTags = const [
  Tag(text: "60 seconds", type: TagType.time),
  Tag(text: "Multiple questions", type: TagType.questions),
];