import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/nearby_alert_service.dart';
import '../../services/notification_service.dart';
import '../../services/responder_service.dart';
import '../../services/auth_service.dart';

class NearbyAlertDialog extends StatefulWidget {
  final String alertId;
  final Map<String, dynamic> alertData;

  const NearbyAlertDialog({super.key, required this.alertId, required this.alertData});

  @override
  State<NearbyAlertDialog> createState() => _NearbyAlertDialogState();
}

class _NearbyAlertDialogState extends State<NearbyAlertDialog> {
  final NearbyAlertService _nearbyAlertService = NearbyAlertService();
  final NotificationService _notificationService = NotificationService();
  final ResponderService _responderService = ResponderService();
  final AuthService _authService = AuthService();
  bool _isResponding = false;

  @override
  void initState() {
    super.initState();
    _notificationService.showNearbyAlert(
      widget.alertData['victimName'] ?? 'Someone',
      widget.alertData['distanceText'] ?? 'nearby',
    );
  }

  Future<void> _acceptAlert() async {
    setState(() => _isResponding = true);

    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      setState(() => _isResponding = false);
      return;
    }

    final userData = await _authService.getUserData(currentUser.uid);

    await _nearbyAlertService.acceptAlert(widget.alertId, currentUser.uid);

    await _responderService.acceptSOSAndTrack(
      alertId: widget.alertId,
      sosEventId: widget.alertData['sosEventId'] ?? '',
      responderId: currentUser.uid,
      responderName: userData?.name ?? 'Helper',
    );

    await _notificationService.cancelNearbyAlert();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You are now responding! Your location is being shared.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ));
      _openInMaps();
    }
  }

  Future<void> _ignoreAlert() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      await _nearbyAlertService.ignoreAlert(widget.alertId, currentUser.uid);
    }
    await _notificationService.cancelNearbyAlert();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _openInMaps() async {
    final Uri mapsUri = Uri.parse(
        'https://maps.google.com/?q=${widget.alertData['latitude']},${widget.alertData['longitude']}');
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.warning, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text('🚨 EMERGENCY NEARBY',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${widget.alertData['victimName'] ?? 'Someone'} needs help!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.location_on, 'Distance',
                widget.alertData['distanceText'] ?? 'Nearby'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.place, 'Location',
                widget.alertData['victimAddress'] ?? 'Unknown location'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Your help can save a life!',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _ignoreAlert,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Not Now'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isResponding ? null : _acceptAlert,
                    icon: _isResponding
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.directions_run),
                    label: const Text("I'M COMING TO HELP",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.red, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}
