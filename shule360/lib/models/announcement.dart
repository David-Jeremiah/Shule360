import 'package:equatable/equatable.dart';

class Announcement extends Equatable {
  final String id;
  final String schoolId;
  final String title;
  final String message;
  final DateTime postedAt;
  final String postedByUserId;
  final DateTime? eventDate; // set for "important dates", null for general announcements

  const Announcement({
    required this.id,
    required this.schoolId,
    required this.title,
    required this.message,
    required this.postedAt,
    required this.postedByUserId,
    this.eventDate,
  });

  factory Announcement.fromMap(String id, Map<String, dynamic> map) {
    return Announcement(
      id: id,
      schoolId: map['schoolId'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      postedAt: DateTime.parse(map['postedAt'] as String),
      postedByUserId: map['postedByUserId'] as String,
      eventDate: map['eventDate'] != null ? DateTime.parse(map['eventDate'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'schoolId': schoolId,
    'title': title,
    'message': message,
    'postedAt': postedAt.toIso8601String(),
    'postedByUserId': postedByUserId,
    'eventDate': eventDate?.toIso8601String(),
  };

  @override
  List<Object?> get props =>
      [id, schoolId, title, message, postedAt, postedByUserId, eventDate];
}