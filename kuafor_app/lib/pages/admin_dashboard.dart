import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Yönetim Paneli")),
      body: const Center(
        child: Text("Kullanıcıları görüntüle ve istatistikleri yönet 📊"),
      ),
    );
  }
}
