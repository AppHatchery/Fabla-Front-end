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
      amount: double.parse(json['amount']),
      bonus: double.parse(json['bonus']),
      currency: json['currency'] ?? '\$',
      threshold: json['threshold'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount.toString(),
      'bonus': bonus.toString(),
      'currency': currency,
      'threshold': threshold,
    };
  }
}
