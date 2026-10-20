enum ResponseType {
  audio,
  text,
  multiple,
  radio,
  slider,
  textAudio,
  webview,
  timer,
  image,
  video,
  imageVideo,
  instruction,
  psychomotor,
  mediaImage,
  mediaVideo,
  timePicker
}

enum OptionType {
  radio,
  slider,
  multiple,
}

enum TagType {
  time,
  questions,
  remainder,
}

enum ConditionType {
  equals, // equals to a specific value
  notEquals, // not equals to a specific value

  greaterThan,
  lessThan,
  between, // within a range of values

  contains,
  notContains,

  beforeTime, // before a specific time
  afterTime, // after a specific time

  answered, // has been answered
  notAnswered, // has not been answered - probably skipped
}

enum ConditionLogic {
  and,
  or,
}
