import 'package:flutter/material.dart';

class StylistHomePage extends StatelessWidget {
  const StylistHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kuaför Paneli")),
      body: const Center(
        child: Text("Randevularını yönet, hizmet ekle ✂️"),
      ),
    );
  }
}
