import 'package:equatable/equatable.dart';

enum SubscriptionTier { starter, standard, full }
enum SchoolLevel { primary, secondary, both }

class School extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String district;
  final SchoolLevel level;
  final SubscriptionTier tier;
  final DateTime subscriptionPaidUntil;
  final int gracePeriodDays;
  final String? logoUrl;
  final String primaryColorHex;
  final String? contactPersonName;
  final String? contactPersonPhone;
  final String? contactPersonEmail;

  const School({
    required this.id,
    required this.name,
    required this.slug,
    required this.district,
    required this.level,
    required this.tier,
    required this.subscriptionPaidUntil,
    this.gracePeriodDays = 21,
    this.logoUrl,
    this.primaryColorHex = '#1F4E5C',
    this.contactPersonName,
    this.contactPersonPhone,
    this.contactPersonEmail,
  });

  bool get isWithinGracePeriod {
    final graceEnd = subscriptionPaidUntil.add(Duration(days: gracePeriodDays));
    return DateTime.now().isBefore(graceEnd);
  }

  factory School.fromMap(String id, Map<String, dynamic> map) {
    return School(
      id: id,
      name: map['name'] as String,
      slug: map['slug'] as String,
      district: map['district'] as String,
      level: SchoolLevel.values.firstWhere(
            (l) => l.name == map['level'],
        orElse: () => SchoolLevel.both,
      ),
      tier: SubscriptionTier.values.firstWhere(
            (t) => t.name == map['tier'],
        orElse: () => SubscriptionTier.starter,
      ),
      subscriptionPaidUntil: DateTime.parse(map['subscriptionPaidUntil'] as String),
      gracePeriodDays: map['gracePeriodDays'] as int? ?? 21,
      logoUrl: map['logoUrl'] as String?,
      primaryColorHex: map['primaryColorHex'] as String? ?? '#1F4E5C',
      contactPersonName: map['contactPersonName'] as String?,
      contactPersonPhone: map['contactPersonPhone'] as String?,
      contactPersonEmail: map['contactPersonEmail'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'slug': slug,
    'district': district,
    'level': level.name,
    'tier': tier.name,
    'subscriptionPaidUntil': subscriptionPaidUntil.toIso8601String(),
    'gracePeriodDays': gracePeriodDays,
    'logoUrl': logoUrl,
    'primaryColorHex': primaryColorHex,
    'contactPersonName': contactPersonName,
    'contactPersonPhone': contactPersonPhone,
    'contactPersonEmail': contactPersonEmail,
  };

  @override
  List<Object?> get props => [
    id, name, slug, district, level, tier, subscriptionPaidUntil, gracePeriodDays,
    logoUrl, primaryColorHex, contactPersonName, contactPersonPhone, contactPersonEmail,
  ];
}