import 'package:ai_task_project_manager/controllers/auth_controller.dart';
import 'package:ai_task_project_manager/controllers/dashboard_controller.dart';
import 'package:ai_task_project_manager/pages/add_task_page.dart';
import 'package:ai_task_project_manager/pages/analytic_page.dart';
import 'package:ai_task_project_manager/pages/change_language_page.dart';
import 'package:ai_task_project_manager/pages/notification_page.dart';
import 'package:ai_task_project_manager/pages/setting/about_app_page.dart';
import 'package:ai_task_project_manager/pages/setting/change_password_page.dart';
import 'package:ai_task_project_manager/pages/setting/contact_support_page.dart';
import 'package:ai_task_project_manager/pages/setting/profile_page.dart';
import 'package:ai_task_project_manager/pages/setting/setting_page.dart';
import 'package:ai_task_project_manager/pages/task_list_page.dart';
import 'package:ai_task_project_manager/services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

// Pages
import 'pages/splash_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/register_page.dart';
import 'pages/home_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/ai_import_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('en_US', null);
  

  Get.put(AuthController());
  Get.put(DashboardController());
  Get.put(LocalizationService(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'AI Task Manager',
      debugShowCheckedModeBanner: false,
      translations: LocalizationService(),
      locale: LocalizationService.locale,
      fallbackLocale: LocalizationService.fallbackLocale,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        textTheme: GoogleFonts.kanitTextTheme(Theme.of(context).textTheme),
      ),
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => const SplashPage()),
        GetPage(name: '/login', page: () => LoginPage()),
        GetPage(name: '/register', page: () => RegisterPage()),
        GetPage(name: '/home', page: () => HomePage()),
        GetPage(name: '/dashboard', page: () => DashboardPage()),
        GetPage(name: '/tasks', page: () => TaskListPage()),
        GetPage(name: '/ai-import', page: () => AiImportPage()),
        GetPage(name: '/addtasks', page: () => const AddTaskPage()),
        GetPage(name: '/analytic', page: () => AnalyticsPage()),
        GetPage(name: '/notifications', page: () => NotificationsPage()),

        // Setting
        GetPage(name: '/settings', page: () => SettingPage()),
        GetPage(name: '/profile-detail', page: () => ProfileDetailPage()),
        GetPage(
          name: '/change-password',
          page: () => const ChangePasswordPage(),
        ),
        GetPage(name: '/about-app', page: () => const AboutAppPage()),
        GetPage(name: '/contact-support', page: () => ContactSupportPage()),
        GetPage(name: '/change-language', page: () => LanguagePage()),
      ],
    );
  }
}
