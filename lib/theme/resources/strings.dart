class Strings {
  static String lorem =
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc cursus orci est, nec pretium diam elementum ut. Donec a metus lobortis, vestibulum elit at, tincidunt sapien. Praesent eget urna id augue elementum mattis non quis turpis. Vivamus lacinia gravida nulla, ac efficitur magna consectetur non. Praesent laoreet turpis tortor, sit amet cursus libero sollicitudin ac. Proin sed mauris quis ipsum dapibus sagittis. Aenean a iaculis lacus. Pellentesque sed ante vel tortor bibendum egestas. \n \n Suspendisse nisl urna, volutpat at elit varius, mollis fermentum ante. Sed iaculis, dolor eu pharetra faucibus, dui sapien elementum ante, eu interdum neque ipsum commodo purus. Vivamus ac urna consequat, placerat libero sit amet, aliquam dui. Quisque efficitur id orci in tempus. Cras tincidunt ante nec congue sollicitudin. Phasellus placerat placerat ligula, sit amet accumsan dolor aliquam ac. Sed in nunc et nisl pretium rhoncus a eget odio. Suspendisse efficitur luctus accumsan. Phasellus blandit metus ut velit rutrum, sed lacinia enim volutpat. Nam mollis, ligula eget dictum ornare, diam nibh sodales mi, vel convallis turpis est vel risus.";

  static String loremHalf =
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc cursus orci est, nec pretium diam elementum ut. Donec a metus lobortis, vestibulum elit at, tincidunt sapien. Praesent eget urna id augue elementum mattis non quis turpis.";

  static String studyDescription =
      "Hi, welcome to our study! In this study, participants will use audio diaries to record their daily thoughts, feelings, and experiences, providing invaluable insights into how everyday life impacts our emotional well-being. \n \n By participating, you are not only contributing to groundbreaking mental health research but also embarking on a journey of self-discovery. Your audio diary entries will serve as a personal chronicle of your emotional journey, fostering a deeper understanding of your own emotional patterns. We appreciate your time and commitment, and thank you for your contribution to this crucial study.";

  static String wavingEmoji = "👋";

  static String telescope = "🔬";

  static String confetti = "🎉";

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
  String participantMetadata(String code, String date) {
    return "Participant $code \n started study on $date";
  }
}
