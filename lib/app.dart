import 'package:flutter/material.dart';
import 'package:taxi_app/core/theme/app_theme.dart';
import 'package:taxi_app/shared/widgets/role_router.dart';

class TaxiApp extends StatelessWidget {
  const TaxiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyTown Cabs',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const RoleRouter(),
    );
  }
}
