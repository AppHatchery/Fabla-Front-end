class Incentive {
  final double amount;
  final double bonus;
  final String currency;
  final int threshold;

  Incentive(
      {required this.amount,
      required this.bonus,
      required this.currency,
      required this.threshold});

  factory Incentive.fromJson(Map<String, dynamic> json) {
    return Incentive(
      amount: json['amount'] ?? 0,
      bonus: json['bonus'] ?? 0,
      currency: json['currency'] ?? '\$',
      threshold: json['threshold'] ?? 0,
    );
  }
}
