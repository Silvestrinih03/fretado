import 'package:flutter/material.dart';

import 'client_profile_page.dart';

class DriverProfilePage extends StatelessWidget {
  final int userId;

  const DriverProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return UserProfilePage(userId: userId, roleLabel: 'Motorista');
  }
}
