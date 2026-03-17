import 'package:flutter/material.dart';
import '../services/campaign_service.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  final CampaignService _campaignService = CampaignService();
  late Future<List<dynamic>> _campaignsFuture;

  @override
  void initState() {
    super.initState();
    _campaignsFuture = _campaignService.getCampaigns();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kampanyalar')),
      body: FutureBuilder<List<dynamic>>(
        future: _campaignsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aktif kampanya bulunmuyor'));
          }
          final campaigns = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: campaigns.length,
            itemBuilder: (context, index) {
              final campaign = campaigns[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Text(
                      '%${campaign['discountPercent'] ?? 0}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  title: Text(
                    campaign['title'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(campaign['description'] ?? ''),
                  trailing: campaign['endDate'] != null
                      ? Text(
                          campaign['endDate'].toString().substring(0, 10),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}