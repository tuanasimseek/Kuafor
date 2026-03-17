import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _loadFcmToken();
  }

  void _loadFcmToken() {
    setState(() {
      _fcmToken = _firebaseService.fcmToken;
    });
  }

  void _copyToken() {
    if (_fcmToken != null) {
      Clipboard.setData(ClipboardData(text: _fcmToken!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('FCM Token kopyalandı!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: Colors.purple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications, color: Colors.purple),
                      const SizedBox(width: 8),
                      const Text(
                        'Firebase Cloud Messaging',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'FCM Token:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_fcmToken != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        _fcmToken!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    )
                  else
                    const Text('Token yükleniyor...'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _fcmToken != null ? _copyToken : null,
                      icon: const Icon(Icons.copy),
                      label: const Text('Token\'ı Kopyala'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.campaign, color: Colors.green),
                  title: const Text('Kampanya Bildirimleri'),
                  subtitle: const Text('Yeni kampanyalardan haberdar ol'),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) async {
                      if (value) {
                        await _firebaseService.subscribeToTopic('campaigns');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kampanya bildirimlerine abone olundu')),
                          );
                        }
                      } else {
                        await _firebaseService.unsubscribeFromTopic('campaigns');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kampanya bildirimlerinden çıkıldı')),
                          );
                        }
                      }
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.orange),
                  title: const Text('Randevu Hatırlatmaları'),
                  subtitle: const Text('Randevularınızdan önce bildirim al'),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) async {
                      if (value) {
                        await _firebaseService.subscribeToTopic('appointments');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Randevu bildirimlerine abone olundu')),
                          );
                        }
                      } else {
                        await _firebaseService.unsubscribeFromTopic('appointments');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Randevu bildirimlerinden çıkıldı')),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'ℹ️ Bu token ile backend üzerinden bildirim gönderebilirsiniz.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
