import 'package:flutter/material.dart';

class SalonOwnerHomePage extends StatelessWidget {
  const SalonOwnerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Salon Sahibi Paneli")),
      body: const Center(
        child: Text("Salon çalışanlarını yönet"),
      ),
    );
  }
}
