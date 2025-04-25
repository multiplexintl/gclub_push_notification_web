// lib/routes/app_pages.dart
import 'package:get/get.dart';

import '../view/home_screen.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.home;

  static final routes = [
    GetPage(
      name: _Paths.home,
      page: () => const HomeScreen(),
    ),
  ];
}
