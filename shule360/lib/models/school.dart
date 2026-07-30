import 'package:equatable/equatable.dart';

enum SubscriptionTier { starter, standard, full }

class School extends Equatable {
  final String id;
  final String name;
  final String district;
  final SubscriptionTier tier;
  final DateTime subscriptionPaidUntil;
  final int gracePeriodDays;

  const School({
    required this.id,
    required this.name,
    required this.district,
    required this.tier,
    required this.subscriptionPaidUntil,
    this.gracePeriodDays = 21,
  });

  bool get isWithinGracePeriod {
    final graceEnd = subscriptionPaidUntil.add(Duration(days: gracePeriodDays));
    return DateTime.now().isBefore(graceEnd);
  }

  factory School.fromMap(String id, Map<String, dynamic> map) {
    return School(
      id: id,
      name: map['name'] as String,
      district: map['district'] as String,
      tier: SubscriptionTier.values.firstWhere(
            (t) => t.name == map['tier'],
        orElse: () => SubscriptionTier.starter,
      ),
      subscriptionPaidUntil: DateTime.parse(map['subscriptionPaidUntil'] as String),
      gracePeriodDays: map['gracePeriodDays'] as int? ?? 21,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'district': district,
    'tier': tier.name,
    'subscriptionPaidUntil': subscriptionPaidUntil.toIso8601String(),
    'gracePeriodDays': gracePeriodDays,
  };

  @override
  List<Object?> get props => [id, name, district, tier, subscriptionPaidUntil, gracePeriodDays];
}