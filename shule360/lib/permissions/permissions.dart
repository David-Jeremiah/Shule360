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
    UserRole.platformAdmin: <Capability>{}, // platform admin bypasses per-school capability checks entirely
    
    UserRole.headTeacher: {
      Capability.viewFinance,
      Capability.editFees,
      Capability.viewPayroll,
      Capability.editPayroll,
      Capability.viewProcurement,
      Capability.editProcurement,
      Capability.manageStaff,
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
      Capability.viewAllAcademics,
      Capability.manageTimetable,
      Capability.manageAnnouncements,
      Capability.manageSchoolBranding,
      Capability.manageUserAccounts,
      Capability.manageSports,
    },
    UserRole.schoolAdmin: {
      Capability.manageSchoolBranding,
      Capability.manageUserAccounts,
    },
    UserRole.dos: {
      Capability.viewAllAcademics,
      Capability.editSyllabusCoverage,
      Capability.triggerMidTermReport,
      Capability.manageTimetable,
    },
    UserRole.hod: {
      Capability.viewOwnDepartmentAcademics,
      Capability.editSyllabusCoverage,
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
  };

  static bool can(UserRole role, Capability capability) {
    return matrix[role]?.contains(capability) ?? false;
  }
}