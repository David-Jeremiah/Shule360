import 'package:equatable/equatable.dart';

enum SubscriptionTier { starter, standard, full }

class School extends Equatable {
  final String id;
  final String name;
  final String district;
  final SubscriptionTier tier;
  final DateTime subscriptionPaidUntil;
  final int gracePeriodDays;
  final String? logoUrl;
  final String primaryColorHex; // e.g. "#1F4E5C"

  const School({
    required this.id,
    required this.name,
    required this.district,
    required this.tier,
    required this.subscriptionPaidUntil,
    this.gracePeriodDays = 21,
    this.logoUrl,
    this.primaryColorHex = '#1F4E5C',
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
      logoUrl: map['logoUrl'] as String?,
      primaryColorHex: map['primaryColorHex'] as String? ?? '#1F4E5C',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'district': district,
    'tier': tier.name,
    'subscriptionPaidUntil': subscriptionPaidUntil.toIso8601String(),
    'gracePeriodDays': gracePeriodDays,
    'logoUrl': logoUrl,
    'primaryColorHex': primaryColorHex,
  };

  @override
  List<Object?> get props =>
      [id, name, district, tier, subscriptionPaidUntil, gracePeriodDays, logoUrl, primaryColorHex];
}