import 'package:flutter/material.dart';
import 'package:cakeu/app/router.dart';
import 'package:cakeu/core/theme/app_theme.dart';
import 'package:cakeu/core/constants/app_constants.dart';

/// Root widget of the CAKEU application.
///
/// Configures MaterialApp.router with the app theme and GoRouter.
class CakeuApp extends StatelessWidget {
  const CakeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
