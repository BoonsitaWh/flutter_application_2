// กำหนดเส้นทางและหน้าปลายทางที่ใช้เดินทางระหว่างหน้าจอของแอป
//import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/features/auth/views/login_screen.dart';
import 'package:flutter_application_1/features/product/views/product_list_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String products = '/products';

  static final router = GoRouter(
    initialLocation: products,
    routes: [
      GoRoute(path: login, builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: products,
        builder: (context, state) => const ProductListScreen(),
      ),
    ],
  );
}
