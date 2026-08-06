import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/school_class.dart';
import '../models/subject.dart';
import '../models/teacher_attendance_record.dart';
import '../models/timetable_slot.dart';
import '../services/class_service.dart';
import '../services/teacher_attendance_service.dart';
import '../services/timetable_service.dart';
import '../widgets/sign_out_button.dart';

class TeacherAttendanceScreen extends StatelessWidget {
  final AppUser currentUser;

  const TeacherAttendanceScreen({super.key, required this.currentUser});

  Future<void> _checkIn(BuildContext context, TimetableSlot slot) async {
    final service = TeacherAttendanceService();
    final now = DateTime.now();
    final scheduledStart = DateTime(now.year, now.month, now.day, slot.startMinutes ~/ 60, slot.startMinutes % 60);
    final scheduledEnd = DateTime(now.year, now.month, now.day, slot.endMinutes ~/ 60, slot.endMinutes % 60);
    final isLate = now.isAfter(scheduledStart.add(const Duration(minutes: 5)));

    final id = '${slot.id}_${now.toIso8601String().split('T')[0]}';
    await service.checkIn(TeacherAttendanceRecord(
      id: id,
      schoolId: currentUser.schoolId,
      teacherId: currentUser.id,
      classId: slot.classId,
      subjectId: slot.subjectId,
      timetableSlotId: slot.id,
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
      actualCheckIn: now,
      status: isLate ? AttendanceStatus.late : AttendanceStatus.onTime,
    ));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isLate ? 'Checked in — marked late' : 'Checked in — on time')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final timetableService = TimetableService();
    final classService = ClassService();
    final today = DateTime.now().weekday; // 1 = Monday ... 7 = Sunday, matches our dayOfWeek

    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Check-In'), actions: const [SignOutButton()]),
      body: StreamBuilder<List<SchoolClass>>(
        stream: classService.watchClasses(currentUser.schoolId),
        builder: (context, classSnapshot) {
          final classNames = {for (final c in classSnapshot.data ?? <SchoolClass>[]) c.id: c.name};

          return StreamBuilder<List<Subject>>(
            stream: classService.watchSubjects(currentUser.schoolId),
            builder: (context, subjectSnapshot) {
              final subjectNames = {for (final s in subjectSnapshot.data ?? <Subject>[]) s.id: s.name};

              return StreamBuilder<List<TimetableSlot>>(
                stream: timetableService.watchSlotsForTeacher(currentUser.schoolId, currentUser.id),
                builder: (context, snapshot) {
                  final todaysSlots = [...(snapshot.data ?? [])]
                      .where((s) => s.dayOfWeek == today)
                      .toList()
                    ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

                  if (todaysSlots.isEmpty) {
                    return const Center(child: Text('No classes scheduled for you today.'));
                  }

                  final nowMinutes = TimeOfDay.now().hour * 60 + TimeOfDay.now().minute;

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: todaysSlots.length,
                    itemBuilder: (context, index) {
                      final slot = todaysSlots[index];
                      final isCurrent = nowMinutes >= slot.startMinutes - 10 && nowMinutes <= slot.endMinutes;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isCurrent ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4) : null,
                        child: ListTile(
                          leading: Icon(isCurrent ? Icons.play_circle_fill : Icons.schedule),
                          title: Text('${slot.startLabel} – ${slot.endLabel}'),
                          subtitle: Text(
                            '${classNames[slot.classId] ?? slot.classId}  •  '
                                '${subjectNames[slot.subjectId] ?? slot.subjectId}',
                          ),
                          trailing: FilledButton(
                            onPressed: () => _checkIn(context, slot),
                            child: const Text('Check In'),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}