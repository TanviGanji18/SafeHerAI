import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../providers/route_provider.dart';
import '../models/amenity_model.dart';

class NearbyAmenitiesScreen extends StatelessWidget {
  const NearbyAmenitiesScreen({Key? key}) : super(key: key);

  void _callPhone(String phone) async {
    final cleanPhone = phone.split('/')[0].trim();
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeProv = Provider.of<RouteProvider>(context);
    final safeSpots = routeProv.nearbySafeSpots;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Nearby Safe Spots'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.local_police), text: 'Police (100)'),
              Tab(icon: Icon(Icons.local_hospital), text: 'Hospitals (108)'),
              Tab(icon: Icon(Icons.directions_subway), text: 'Metro / Bus'),
              Tab(icon: Icon(Icons.warning), text: 'Black Spots'),
            ],
          ),
        ),
        body: safeSpots == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildAmenityList(safeSpots.policeStations, Icons.local_police, Colors.blue),
                  _buildAmenityList(safeSpots.hospitals, Icons.local_hospital, Colors.red),
                  _buildAmenityList(safeSpots.transitStations, Icons.directions_subway, Colors.orange),
                  _buildAmenityList(safeSpots.accidentBlackspots, Icons.warning_amber, Colors.purple, isHazard: true),
                ],
              ),
      ),
    );
  }

  Widget _buildAmenityList(List<AmenityItem> items, IconData icon, Color iconColor, {bool isHazard = false}) {
    if (items.isEmpty) {
      return const Center(child: Text('No infrastructure recorded within search radius.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.12),
              child: Icon(icon, color: iconColor),
            ),
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item.category} • ${item.distanceKm.toStringAsFixed(2)} km away', style: const TextStyle(fontSize: 12)),
                if (item.extraDetails != null)
                  Text(item.extraDetails!, style: TextStyle(fontSize: 11, color: isHazard ? Colors.red.shade800 : Colors.grey.shade600)),
              ],
            ),
            trailing: item.phone != null && !isHazard
                ? IconButton(
                    icon: const Icon(Icons.phone, color: AppColors.safeGreen),
                    onPressed: () => _callPhone(item.phone!),
                  )
                : null,
          ),
        );
      },
    );
  }
}
