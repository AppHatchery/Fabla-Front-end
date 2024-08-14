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
      amount: json['amount'],
      bonus: json['bonus'],
      currency: json['currency'] ?? '\$',
      threshold: json['threshold'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'bonus': bonus,
      'currency': currency,
      'threshold': threshold,
    };
  }
}
