import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kuaför App',
      theme: ThemeData(primarySwatch: Colors.purple),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        // token olmadığı için HomePage burada const olamaz!
        '/home': (context) => HomePage(token: ''), // geçici boş token
      },
    );
  }
}
