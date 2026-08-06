import 'role.dart';

enum Capability {
  viewFinance,
  editFees,
  viewPayroll,
  editPayroll,
  viewProcurement,
  editProcurement,
  manageStaff,
  manageOwnClassStudents,
  enterMarks,
  viewAllAcademics,
  viewOwnDepartmentAcademics,
  editSyllabusCoverage,
  approveSyllabusCoverage,
  setSyllabusTargets,
  triggerMidTermReport,
  checkInAttendance,
  viewOwnChildRecords,
  manageTimetable,
  manageAnnouncements,
  manageSchoolBranding,
  manageUserAccounts,
  manageSports,
}

class Permissions {
  Permissions._();

  static const Map<UserRole, Set<Capability>> matrix = {
    UserRole.headTeacher: {
      Capability.viewFinance,
      Capability.editFees,
      Capability.viewPayroll,
      Capability.editPayroll,
      Capability.viewProcurement,
      Capability.editProcurement,
      Capability.manageStaff,
      Capability.manageOwnClassStudents,
      Capability.viewAllAcademics,
      Capability.manageTimetable,
      Capability.manageAnnouncements,
      Capability.manageSchoolBranding,
      Capability.manageUserAccounts,
      Capability.manageSports,
    },
    UserRole.director: {
      Capability.viewFinance,
      Capability.editFees,
      Capability.viewPayroll,
      Capability.editPayroll,
      Capability.viewProcurement,
      Capability.editProcurement,
      Capability.manageStaff,
      Capability.manageOwnClassStudents,
      Capability.viewAllAcademics,
      Capability.manageTimetable,
      Capability.manageAnnouncements,
      Capability.manageSchoolBranding,
      Capability.manageUserAccounts,
      Capability.manageSports,
    },
    // School admin sees/manages everything in the school — same
    // operational reach as headTeacher/director. The one restriction
    // (can't create another schoolAdmin account) is enforced in
    // ManageUsersScreen's role picker, not here, since Permissions only
    // gates capabilities, not which roles a capability can target.
    UserRole.schoolAdmin: {
      Capability.viewFinance,
      Capability.editFees,
      Capability.viewPayroll,
      Capability.editPayroll,
      Capability.viewProcurement,
      Capability.editProcurement,
      Capability.manageStaff,
      Capability.manageOwnClassStudents,
      Capability.viewAllAcademics,
      Capability.editSyllabusCoverage,
      Capability.approveSyllabusCoverage,
      Capability.setSyllabusTargets,
      Capability.triggerMidTermReport,
      Capability.manageTimetable,
      Capability.manageAnnouncements,
      Capability.manageSchoolBranding,
      Capability.manageUserAccounts,
      Capability.manageSports,
    },
    UserRole.dos: {
      Capability.viewAllAcademics,
      Capability.editSyllabusCoverage,
      Capability.triggerMidTermReport,
      Capability.manageTimetable,
      Capability.manageOwnClassStudents,
    },
    UserRole.hod: {
      Capability.viewOwnDepartmentAcademics,
      Capability.enterMarks,
      Capability.checkInAttendance,
      Capability.editSyllabusCoverage,
      Capability.approveSyllabusCoverage,
      Capability.setSyllabusTargets,
    },
    UserRole.classTeacher: {
      Capability.manageOwnClassStudents,
      Capability.enterMarks,
      Capability.checkInAttendance,
      Capability.editSyllabusCoverage,
    },
    UserRole.teacher: {
      Capability.enterMarks,
      Capability.checkInAttendance,
      Capability.editSyllabusCoverage,
    },
    UserRole.bursar: {
      Capability.viewFinance,
      Capability.editFees,
      Capability.viewPayroll,
      Capability.editPayroll,
      Capability.viewProcurement,
      Capability.editProcurement,
    },
    UserRole.hrOfficer: {
      Capability.manageStaff,
      Capability.viewPayroll,
      Capability.editPayroll,
    },
    UserRole.parent: {
      Capability.viewOwnChildRecords,
    },
    UserRole.student: {
      Capability.viewOwnChildRecords,
    },
    UserRole.platformAdmin: <Capability>{},
  };

  static bool can(UserRole role, Capability capability) {
    return matrix[role]?.contains(capability) ?? false;
  }

  /// Which roles [creatorRole] is allowed to assign when creating a new
  /// staff account. School admins can create any staff role EXCEPT
  /// another school admin (or platform admin) — prevents an admin from
  /// spawning a peer with equal reach. Head teacher/director, being the
  /// top of the school hierarchy, can create anyone including schoolAdmin.
  static List<UserRole> assignableRoles(UserRole creatorRole) {
    const allStaffRoles = [
      UserRole.schoolAdmin,
      UserRole.dos,
      UserRole.hod,
      UserRole.classTeacher,
      UserRole.teacher,
      UserRole.bursar,
      UserRole.hrOfficer,
    ];

    switch (creatorRole) {
      case UserRole.headTeacher:
      case UserRole.director:
        return allStaffRoles;
      case UserRole.schoolAdmin:
        return allStaffRoles.where((r) => r != UserRole.schoolAdmin).toList();
      default:
        return const [];
    }
  }
}