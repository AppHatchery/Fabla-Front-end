import 'dart:convert';

class Strings {
  static String lorem =
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc cursus orci est, nec pretium diam elementum ut. Donec a metus lobortis, vestibulum elit at, tincidunt sapien. Praesent eget urna id augue elementum mattis non quis turpis. Vivamus lacinia gravida nulla, ac efficitur magna consectetur non. Praesent laoreet turpis tortor, sit amet cursus libero sollicitudin ac. Proin sed mauris quis ipsum dapibus sagittis. Aenean a iaculis lacus. Pellentesque sed ante vel tortor bibendum egestas. \n \n Suspendisse nisl urna, volutpat at elit varius, mollis fermentum ante. Sed iaculis, dolor eu pharetra faucibus, dui sapien elementum ante, eu interdum neque ipsum commodo purus. Vivamus ac urna consequat, placerat libero sit amet, aliquam dui. Quisque efficitur id orci in tempus. Cras tincidunt ante nec congue sollicitudin. Phasellus placerat placerat ligula, sit amet accumsan dolor aliquam ac. Sed in nunc et nisl pretium rhoncus a eget odio. Suspendisse efficitur luctus accumsan. Phasellus blandit metus ut velit rutrum, sed lacinia enim volutpat. Nam mollis, ligula eget dictum ornare, diam nibh sodales mi, vel convallis turpis est vel risus.";

  static String loremHalf =
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc cursus orci est, nec pretium diam elementum ut. Donec a metus lobortis, vestibulum elit at, tincidunt sapien. Praesent eget urna id augue elementum mattis non quis turpis.";

  static String studyDescription =
      'The purpose of this study is to test a smartphone app for daily diary research called Fabla, to find out how well it works and how easy it is for people to use. Fabla is a new app developed by the Georgia CTSA AppHatchery. The study will also assess how people’s spoken reports about their day compare to their written reports about their day. Participation in this study takes about two weeks to complete. \n\nDuring the daily diary study, you will be asked to respond to some questions every day before you go to bed for two weeks. The daily diary will take about 10 minutes to complete each time, and it asks you to share about:\n\n\u2022 how your day was,\n\u2022 your interactions with other people that day,\n\u2022 and whether anything stressful happened.\n\nIf you have questions about the study procedures, appointments, research-related injuries or bad reactions, or other questions or concerns about the research or your part in it, contact the Principal Investigator at 404-727-1360.';

  static String studyName = "CCSH Encounters";

  static String studyDuration = "July 2024";

  static String researcherName = "Rev. Caroline Peacock";

  static String organisation = "Winship Cancer Institute";

  static String wavingEmoji = "👋";

  static String telescope = "🔬";

  static String confetti = "🎉";

  static String champagne = "🍾";

  static String researcherNote =
      "Please try to talk without stopping for about 5 minutes. Talk about whatever comes to your mind, as if you were sharing with a friend. Do not worry about pauses, stutters, or having the right things to say. We are interested in anything about your experience today that you are willing to share.";

  static String researcherNoteTwo =
      "Please try to talk without stopping for about 5 minutes. Talk about whatever comes to your mind, as if you were sharing with a friend. Do not worry about pauses, stutters, or having the right things to say. We are interested in anything about your experience today that you are willing to share. \n \nIt is OK if there is overlap with what you talked about for the previous question.";

  //Ttitle and subheader text for when deleting responses from diary page
  static String deletePopUpTitle = "Do you want to delete your response?";
  static String deletePopUpSubheader = "You won't be able to undo this action";

  //Subheader text for deleting responses from history page
  static String deleteTextResponse =
      "Deleting a reply only deletes the written response on the device. Continue deleting?";

  /// Generates a participant metadata string based on provided code and date.
  ///
  /// This function takes a participant [code] and a [date] as input and generates
  /// a metadata string that describes the participant's study details. The metadata
  /// includes the participant's code and the date on which they started the study.
  ///
  /// Parameters:
  /// - [code]: The participant's unique code.
  /// - [date]: The date when the participant started the study.
  ///
  /// Returns:
  /// - A formatted string containing the participant's code and study start date.
  ///
  /// Example usage:
  /// ```dart
  /// String metadata = participantMetadata("ABC123", "2023-08-31");
  /// // Output: "Participant ABC123 \n started study on 2023-08-31"
  /// ```

  String participantMetadata(String code, String date, String nextStudyDate) {
    Map<String, dynamic> nestedObject = {
      'participant': code,
      'start_study_date': date,
      'next_study_date': nextStudyDate,
      'recent_submit_date': null,
      'diaries': {
        'day1': null,
        'day2': null,
        'day3': null,
        'day4': null,
        'day5': null,
        'day6': null,
      },
    };
    return jsonEncode(nestedObject);
  }
}
