import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/user_model.dart';
import '../../models/sos_event_model.dart';
import '../../services/auth_service.dart';
import '../../services/sos_service.dart';
import '../../services/location_service.dart';
import '../../services/nearby_alert_service.dart';
import '../../services/shake_sos_service.dart';
import '../../services/volume_sos_service.dart';
import 'sos_active_screen.dart';
import 'nearby_alert_dialog.dart';
import '../map/safe_route_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  final AuthService _authService = AuthService();
  final SOSService _sosService = SOSService();
  final LocationService _locationService = LocationService();
  final NearbyAlertService _nearbyAlertService = NearbyAlertService();
  final ShakeSOSService _shakeSOSService = ShakeSOSService();
  final VolumeSOSService _volumeSOSService = VolumeSOSService();

  String? _currentUserId;
  bool _isSOSActive = false;
  bool _isLoading = false;
  final Set<String> _shownAlertIds = {};
  bool _isAlertShowing = false;
  int _nearbyUsersCount = 0;
  String _userName = '';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _checkSOSStatus();
    _listenToNearbyAlerts();
    _loadUserData();
    _loadNearbyUsersCount();

    _shakeSOSService.startListening(onSOSTrigger: _handleEmergencyTrigger);
    _volumeSOSService.startListening(onSOSTrigger: _handleEmergencyTrigger);
  }

  Future<void> _loadUserData() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      final userData = await _authService.getUserData(currentUser.uid);
      if (mounted) {
        setState(() => _userName = userData?.name.split(' ').first ?? 'User');
      }
    }
  }

  Future<void> _loadNearbyUsersCount() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    Future.doWhile(() async {
      if (!mounted) return false;
      try {
        Position? position = await _locationService.getCurrentLocation();
        if (position != null) {
          List nearby = await _locationService.getNearbyUsers(
            currentUserId: currentUser.uid,
            currentLat: position.latitude,
            currentLong: position.longitude,
          );
          if (mounted) setState(() => _nearbyUsersCount = nearby.length);
        }
      } catch (e) {
        debugPrint('Error getting nearby count: $e');
      }
      await Future.delayed(const Duration(seconds: 30));
      return mounted;
    });
  }

  void _checkSOSStatus() {
    setState(() => _isSOSActive = _sosService.isSOSActive);
  }

  void _listenToNearbyAlerts() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      _currentUserId = currentUser.uid;
      _nearbyAlertService.listenToNearbyAlerts(_currentUserId!).listen((snapshot) {
        if (!mounted) return;
        for (var doc in snapshot.docs) {
          String alertId = doc.id;
          var alertData = doc.data() as Map<String, dynamic>;
          if (_shownAlertIds.contains(alertId)) continue;
          if (_isAlertShowing) continue;
          if (alertData['status'] != 'pending') continue;
          _shownAlertIds.add(alertId);
          _isAlertShowing = true;
          _showNearbyAlertDialog(alertId, alertData);
        }
      });
    }
  }

  void _showNearbyAlertDialog(String alertId, Map<String, dynamic> alertData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NearbyAlertDialog(alertId: alertId, alertData: alertData),
    ).then((_) {
      if (mounted) setState(() => _isAlertShowing = false);
    });
  }

  Future<UserModel?> _getCurrentUser() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) return await _authService.getUserData(currentUser.uid);
    return null;
  }

  Future<void> _handleEmergencyTrigger() async {
    if (_isSOSActive) return;
    bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _EmergencyCountdownDialog(),
    );
    if (confirm == true) _triggerSOS();
  }

  Future<void> _triggerSOS() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.warning_rounded, color: Colors.red, size: 28),
          SizedBox(width: 12),
          Text('Trigger SOS?'),
        ]),
        content: const Text(
            'This will:\n• Alert nearby users\n• Notify emergency contacts\n• Share your live location\n• Alert nearest police station'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Trigger SOS'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _isLoading = true);

    var permission = await _locationService.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await _locationService.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        return;
      }
    }

    UserModel? currentUser = await _getCurrentUser();
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    SOSEvent? sosEvent = await _sosService.triggerSOS(currentUser);
    setState(() => _isLoading = false);

    if (sosEvent != null) {
      setState(() => _isSOSActive = true);
      WakelockPlus.enable();
      if (mounted) {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => SOSActiveScreen(sosEvent: sosEvent, user: currentUser)))
            .then((_) {
          _checkSOSStatus();
          WakelockPlus.disable();
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to trigger SOS. Please try again.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _shakeSOSService.stopListening();
    _volumeSOSService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildSOSSection(),
              _buildStatsSection(),
              _buildQuickActions(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(20)),
                  child: const Row(children: [
                    Icon(Icons.shield, color: Colors.red, size: 14),
                    SizedBox(width: 4),
                    Text('SHAKTI', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
                  ]),
                ),
                const SizedBox(height: 6),
                Text('Hello, $_userName 👋',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                const Text('Stay safe today', style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Column(
              children: [
                Text('$_nearbyUsersCount',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                Text('Nearby\nHelpers', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Colors.green.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Text(
            _isSOSActive ? 'SOS is Active - Help is Coming!' : 'Press for Emergency',
            style: TextStyle(fontSize: 14, color: _isSOSActive ? Colors.red : Colors.grey,
                fontWeight: _isSOSActive ? FontWeight.bold : FontWeight.normal),
          ),
          const SizedBox(height: 30),
          _isLoading
              ? const CircularProgressIndicator(color: Colors.red)
              : ScaleTransition(
                  scale: _scaleAnimation,
                  child: GestureDetector(
                    onTap: _isSOSActive ? null : _triggerSOS,
                    child: Container(
                      height: 200,
                      width: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: _isSOSActive
                              ? [Colors.orange.shade300, Colors.orange.shade600]
                              : [Colors.red.shade400, Colors.red.shade700],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isSOSActive ? Colors.orange : Colors.red).withOpacity(0.4),
                            blurRadius: 40, spreadRadius: 15,
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_isSOSActive ? Icons.shield : Icons.warning_rounded,
                              color: Colors.white, size: 50),
                          const SizedBox(height: 8),
                          Text(_isSOSActive ? 'ACTIVE' : 'SOS',
                              style: const TextStyle(color: Colors.white, fontSize: 36,
                                  fontWeight: FontWeight.bold, letterSpacing: 3)),
                        ],
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _buildStatCard(Icons.people, '$_nearbyUsersCount', 'Nearby Users', Colors.blue)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard(Icons.shield_outlined, '2km', 'Alert Radius', Colors.green)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard(Icons.timer_outlined, '< 2min', 'Response', Colors.orange)),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(label, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text('Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 16),
          _buildActionCard(Icons.phone, 'Emergency Number', 'Call 112 immediately',
              Colors.orange, () => _sosService.makeEmergencyCall('112')),
          const SizedBox(height: 12),
          _buildActionCard(Icons.support_agent, 'Mahila Helpline', 'Call 1091 for women safety',
              Colors.purple, () => _sosService.makeEmergencyCall('1091')),
          const SizedBox(height: 12),
          _buildActionCard(Icons.map_outlined, 'Safe Places Near Me',
              'Police stations, hospitals nearby', Colors.blue, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SafeRouteScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade300, size: 16),
          ],
        ),
      ),
    );
  }
}

class _EmergencyCountdownDialog extends StatefulWidget {
  @override
  State<_EmergencyCountdownDialog> createState() => _EmergencyCountdownDialogState();
}

class _EmergencyCountdownDialogState extends State<_EmergencyCountdownDialog> {
  int _countdown = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _countdown--);
      if (_countdown <= 0) {
        timer.cancel();
        if (mounted) Navigator.pop(context, true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.red.shade50,
      title: const Row(children: [
        Icon(Icons.warning_rounded, color: Colors.red, size: 28),
        SizedBox(width: 8),
        Text('SOS Triggered!', style: TextStyle(color: Colors.red)),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Emergency SOS will activate in:', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 20),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 20, spreadRadius: 5)]),
            child: Center(child: Text('$_countdown',
                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(height: 16),
          const Text('Shake/Volume detected!', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
      actions: [
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () => Navigator.pop(context, false),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('CANCEL - I\'M SAFE'),
        )),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('TRIGGER NOW!'),
        )),
      ],
    );
  }
}
