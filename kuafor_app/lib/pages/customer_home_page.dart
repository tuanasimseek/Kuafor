import 'package:flutter/material.dart';

class CustomerHomePage extends StatelessWidget {
  const CustomerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Müşteri Ana Sayfası")),
      body: const Center(
        child: Text("Randevu al, kuaförleri görüntüle 💇‍♀️"),
      ),
    );
  }
}
