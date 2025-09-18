// import 'package:flutter/material.dart';
// import 'package:timesheetapp/views/Home/home_screen.dart';
//
// import '../views/Reviews/reviews.dart';
// import '../views/Settings/settings.dart';
// import '../views/earnings/earnings.dart';
// import '../views/history/hsitory.dart';
// import '../views/holidays/holidays.dart';
// import '../views/leavemanagement/leave.dart';
// import '../views/manualtimesheet/manual.dart';
// import '../views/messages/chat_screen.dart';
// import '../views/modules/modules.dart';
// import '../views/payroll/payroll.dart';
// import '../views/policies/policies.dart';
// import '../views/projectmanagement/project.dart';
// import '../views/punch/punch.dart';
// import '../views/reports/reports.dart';
// import '../views/schedule/shedule.dart';
// import '../views/tasks/tasks.dart';
// import '../views/teammembers/teammemembers.dart';
// import '../views/timesheet1/timesheet1.dart';
// import '../views/timesheet2/timesheet2.dart';
// import '../views/timesheetsubmision/timesheetsubm.dart';
// import '../views/timtracking/timtracking.dart';
// import '../views/transactions/transactions.dart';
// import 'detailstext1.dart';
//
// class DrawerWidget extends StatefulWidget {
//   const DrawerWidget({super.key});
//
//   @override
//   State<DrawerWidget> createState() => _DrawerWidgetState();
// }
//
// class _DrawerWidgetState extends State<DrawerWidget> {
//   String selectedMenuItem = '';
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(right: 60),
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.only(
//           bottomRight: Radius.circular(30),
//           topRight: Radius.circular(30),
//         ),
//       ),
//       padding: const EdgeInsets.only(left: 20, right: 5, top: 3),
//       child: ListView(
//         physics: const BouncingScrollPhysics(),
//         children: [
//           ListTile(
//             leading: ClipRRect(
//               borderRadius: BorderRadius.circular(40),
//               child: Image.asset('images/c3.png'),
//             ),
//             title: const Text('Hey!'),
//             subtitle: const Text1(text1: 'James Powell'),
//           ),
//           const SizedBox(height: 2.0),
//           buildMenuItem(title: "Homepage", icon: Icons.home, onTap: () => navigateTo(Home())),
//           buildMenuItem(title: "Timesheet Schedule", icon: Icons.calendar_month, onTap: () => navigateTo(const TimeSheetScheduleScreen())),
//           buildMenuItem(title: "Time Off", icon: Icons.free_breakfast, onTap: () => navigateTo(const TimeOffScreen())),
//           buildMenuItem(title: "Holidays", icon: Icons.beach_access, onTap: () => navigateTo(const HolidaysScreen())),
//           buildMenuItem(title: "Leave Management", icon: Icons.event_busy, onTap: () => navigateTo(const LeaveManagementScreen())),
//           buildMenuItem(title: "Manual Timesheet", icon: Icons.timer, onTap: () => navigateTo(const ManualTimesheetScreen())),
//           buildMenuItem(title: "Modules", icon: Icons.view_module, onTap: () => navigateTo(const ModulesScreen())),
//           buildMenuItem(title: "Payroll Management", icon: Icons.payments, onTap: () => navigateTo(const PayrollManagementScreen())),
//           buildMenuItem(title: "Policies", icon: Icons.description, onTap: () => navigateTo(const PoliciesScreen())),
//           buildMenuItem(title: "Earnings", icon: Icons.attach_money, onTap: () => navigateTo(const EarningsScreen())),
//           buildMenuItem(title: "Project Management", icon: Icons.business_center, onTap: () => navigateTo(ProjectManagementScreen())),
//           buildMenuItem(title: "Punch", icon: Icons.fingerprint, onTap: () => navigateTo(const PunchScreen())),
//           buildMenuItem(title: "Reports", icon: Icons.bar_chart, onTap: () => navigateTo(const ReportScreen())),
//           buildMenuItem(title: "TimeSheet Schedule", icon: Icons.schedule, onTap: () => navigateTo(const TimeSheetScheduleScreen())),
//           buildMenuItem(title: "Tasks", icon: Icons.task, onTap: () => navigateTo(const TasksScreen())),
//           buildMenuItem(title: "Team Members", icon: Icons.group, onTap: () => navigateTo(const TeamMembersScreen())),
//           buildMenuItem(title: "Timesheets 1", icon: Icons.insert_chart, onTap: () => navigateTo(const Timesheets1Screen())),
//           buildMenuItem(title: "Timesheets 2", icon: Icons.timeline, onTap: () => navigateTo(const TimesheetScreen2())),
//           buildMenuItem(title: "Timesheet Submission", icon: Icons.upload_file, onTap: () => navigateTo(const TimesheetSubmisionScreen())),
//           buildMenuItem(title: "Time Log", icon: Icons.history, onTap: () => navigateTo(const TimeLogScreen())),
//           buildMenuItem(title: "Transactions", icon: Icons.swap_horiz, onTap: () => navigateTo(TransactionScreen())),
//           buildMenuItem(title: "Messages", icon: Icons.message, onTap: () => navigateTo(const ChatScreen())),
//           buildMenuItem(title: "Reviews", icon: Icons.rate_review, onTap: () => navigateTo(const Reviews())),
//           buildMenuItem(title: "Settings", icon: Icons.settings, onTap: () => navigateTo(const Settings())),
//           const Divider(thickness: 1),
//           ListTile(
//             onTap: () {},
//             leading: const Icon(Icons.logout, color: Colors.redAccent),
//             title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget buildMenuItem({required String title, required IconData icon, required VoidCallback onTap}) {
//
//
//
//     return  GestureDetector(
//       onTap:onTap,
//       child: Padding(
//         padding: const EdgeInsets.only(top: 12),
//         child: Row(
//           children: [
//             Icon(icon, size: 24),
//             SizedBox(width: 10,),
//             Text(title, style: const TextStyle(fontSize: 16)),
//             Spacer(),
//
//             Icon(Icons.navigate_next)
//           ],
//
//         ),
//       ),
//     );
//   }
//
//   void navigateTo(Widget page) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => page),
//     );
//   }
// }
