import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/duty_planning/presentation/pages/duty_creation_page.dart';
import '../../features/duty_planning/presentation/pages/duty_result_page.dart';
import '../../features/butterfly_system/presentation/pages/student_entry_page.dart';
import '../../features/butterfly_system/presentation/pages/exam_hall_page.dart';
import '../../features/butterfly_system/presentation/pages/exam_result_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/teachers/presentation/pages/teacher_management_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardPage(),
        routes: [
          GoRoute(
            path: 'duty-create',
            builder: (context, state) => const DutyCreationPage(),
          ),
          GoRoute(
            path: 'duty-result',
            builder: (context, state) => const DutyResultPage(),
          ),
          GoRoute(
            path: 'student-entry',
            builder: (context, state) => const StudentEntryPage(),
          ),
          GoRoute(
            path: 'exam-hall',
            builder: (context, state) => const ExamHallPage(),
          ),
          GoRoute(
            path: 'exam-result',
            builder: (context, state) => const ExamResultPage(),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: 'teachers',
            builder: (context, state) => const TeacherManagementPage(),
          ),
        ],
      ),
    ],
  );
});
