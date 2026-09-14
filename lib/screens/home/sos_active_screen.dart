import 'package:flutter/material.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/sos_event_model.dart';
import '../../models/user_model.dart';
import '../../services/sos_service.dart';
import '../../services/location_service.dart';
import '../../services/responder_service.dart';

class SOSActiveScreen extends StatefulWidget {
  final SOSEvent sosEvent;
  final UserModel user;

  const SOSActiveScreen({super.key, required this.sosEvent, required this.user});

  @override
  State<SOSActiveScreen> createState() => _SOSActiveScreenState();
}

class _SOSActiveScreenState extends State<SOSActiveScreen>
    with SingleTickerProviderStateMixin {
  final SOSService _sosService = SOSService();
  final LocationService _locationService = LocationService();
  final ResponderService _responderService = ResponderService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  Timer? _timer;
  int _elapsedSeconds = 0;
  String _currentAddress = '';
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _currentAddress = widget.sosEvent.address;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _elapsedSeconds++);
    });
    _trackLocation();
  }

  void _trackLocation() {
    _locationService.getPositionStream().listen((position) {
      _locationService.getAddressFromCoordinates(position.latitude, position.longitude)
          .then((address) {
        if (mounted) setState(() => _currentAddress = address);
      });
    });
  }

  String _formatElapsedTime() {
    int minutes = _elapsedSeconds ~/ 60;
    int seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _cancelSOS() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel SOS?'),
        content: const Text('Are you sure you want to cancel the emergency alert?\n\nYour emergency contacts have already been notified.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No, Keep Active')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Yes, Cancel')),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isCancelling = true);
      await _sosService.cancelSOS();
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _markAsSafe() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Safe?'),
        content: const Text('This will deactivate the SOS alert and notify your contacts that you are safe.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text("I'm Safe")),
        ],
      ),
    );
    if (confirm == true) {
      await _sosService.resolveSOS(widget.sosEvent.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('SOS resolved. Your contacts have been notified.'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      }
    }
  }

  Future<void> _openInMaps() async {
    final Uri mapsUri = Uri.parse(
        'https://maps.google.com/?q=${widget.sosEvent.latitude},${widget.sosEvent.longitude}');
    if (await canLaunchUrl(mapsUri)) await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
  }

  Future<void> _shareLocation() async {
    String message = 'My current location:\n$_currentAddress\n\nhttps://maps.google.com/?q=${widget.sosEvent.latitude},${widget.sosEvent.longitude}';
    final Uri smsUri = Uri(scheme: 'sms', path: '', queryParameters: {'body': message});
    if (await canLaunchUrl(smsUri)) await launchUrl(smsUri);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please use "Cancel SOS" or "I\'m Safe" button'),
          duration: Duration(seconds: 2),
        ));
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.red.shade50,
        appBar: AppBar(
          title: const Text('SOS ACTIVE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
          centerTitle: true,
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  height: 150, width: 150,
                  decoration: BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 40, spreadRadius: 20)],
                  ),
                  child: const Icon(Icons.warning_rounded, size: 80, color: Colors.white),
                ),
              ),
              const SizedBox(height: 30),
              const Text('EMERGENCY ALERT ACTIVE',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(_formatElapsedTime(),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _buildInfoCard(Icons.notifications_active, 'Alerts Sent',
                  '${widget.user.emergencyContacts.length} emergency contacts notified', Colors.orange),
              const SizedBox(height: 12),
              _buildInfoCard(Icons.location_on, 'Your Location', _currentAddress, Colors.blue, onTap: _openInMaps),
              const SizedBox(height: 12),
              _buildInfoCard(Icons.local_police, 'Police Notified', 'Nearest station has been alerted', Colors.indigo),
              const SizedBox(height: 12),

              // Responders Section
              StreamBuilder<QuerySnapshot>(
                stream: _responderService.getRespondersForSOS(widget.sosEvent.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('Help On The Way',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                      ),
                      const SizedBox(height: 8),
                      ...snapshot.data!.docs.map((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        String responderName = data['responderName'] ?? 'Helper';
                        String status = data['status'] ?? 'on_way';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: Colors.green.shade50,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Icon(status == 'arrived' ? Icons.check : Icons.directions_run,
                                  color: Colors.white),
                            ),
                            title: Text(responderName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(status == 'arrived' ? '✓ Arrived' : '→ On the way',
                                style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w500)),
                            trailing: const Icon(Icons.location_on, color: Colors.green),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),

              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _shareLocation,
                      icon: const Icon(Icons.share_location),
                      label: const Text('Share Location'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _sosService.makeEmergencyCall('112'),
                      icon: const Icon(Icons.phone),
                      label: const Text('Call 112'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton.icon(
                  onPressed: _markAsSafe,
                  icon: const Icon(Icons.check_circle),
                  label: const Text("I'M SAFE",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _isCancelling ? null : _cancelSOS,
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel SOS'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String subtitle, Color color, {VoidCallback? onTap}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
              if (onTap != null) const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
