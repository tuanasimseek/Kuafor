import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'pages/customer_home_page.dart';
import 'pages/stylist_home_page.dart';
import 'pages/salon_owner_home_page.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().initLocalNotifications();

  if (!kIsWeb) {
    await FirebaseService().initialize();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kuaför Uygulaması',
      home: const SplashDecider(),
    );
  }
}

class SplashDecider extends StatefulWidget {
  const SplashDecider({super.key});

  @override
  State<SplashDecider> createState() => _SplashDeciderState();
}

class _SplashDeciderState extends State<SplashDecider> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final token = await _authService.getToken();

    // Token yok → misafir olarak CustomerHomePage'e git
    if (token == null || token.isEmpty) {
      _goTo(const CustomerHomePage(guestMode: true));
      return;
    }

    final user = await _authService.getUserInfo(token);

    if (user == null) {
      await _authService.deleteToken();
      _goTo(const CustomerHomePage(guestMode: true));
      return;
    }

    final role = user['role']?.toString() ?? '';
    final page = _getHomePageByRole(role);

    if (page != null) {
      _goTo(page);
    } else {
      await _authService.deleteToken();
      _goTo(const CustomerHomePage(guestMode: true));
    }
  }

  Widget? _getHomePageByRole(String role) {
    switch (role) {
      case 'Customer':
        return const CustomerHomePage(guestMode: false);
      case 'Hairdresser':
        return const StylistHomePage();
      case 'SalonOwner':
        return const SalonOwnerHomePage();
      default:
        return const CustomerHomePage(guestMode: false);
    }
  }

  void _goTo(Widget page) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
