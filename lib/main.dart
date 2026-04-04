import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'dart:math' as math;

void main() => runApp(const DamsApp());

class DamsApp extends StatelessWidget {
  const DamsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'D.A.M.S.',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF8B0000),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        fontFamily: 'Roboto',
      ),
      home: const MainFlowController(),
    );
  }
}

class MainFlowController extends StatefulWidget {
  const MainFlowController({super.key});

  @override
  State<MainFlowController> createState() => _MainFlowControllerState();
}

class _MainFlowControllerState extends State<MainFlowController> {
  int _currentStep = 0;
  String? _userName;
  String? _selectedRole;

  void _nextStep() => setState(() => _currentStep++);

  @override
  void initState() {
    super.initState();
    // Splash screen timer
    Future.delayed(const Duration(seconds: 3), () {
      if (_currentStep == 0) _nextStep();
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentStep) {
      case 0: return _buildSplashScreen();
      case 1: return _buildRoleSelection();
      case 2: return _buildHowItWorks();
      case 3: return DashboardScreen(userName: _userName!, role: _selectedRole!);
      default: return _buildSplashScreen();
    }
  }

  Widget _buildSplashScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sensors, size: 80, color: Color(0xFFE53935)),
            const SizedBox(height: 30),
            const Text("D.A.M.S", style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 4)),
            const Text("Offline Emergency Coordination", style: TextStyle(fontSize: 14, color: Colors.white70, letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelection() {
    final TextEditingController nameCtrl = TextEditingController(text: _userName);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text("Welcome to D.A.M.S", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const Text("Identify yourself to join the local mesh", style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 40),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Enter your name or callsign",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF8B0000))),
                ),
              ),
              const SizedBox(height: 30),
              _roleCard("Rescue Team", "rescue", Icons.shield_outlined, "I am here to provide aid"),
              const SizedBox(height: 15),
              _roleCard("Survivor", "survivor", Icons.location_on_outlined, "I need assistance or info"),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B0000),
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 8,
                ),
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty && _selectedRole != null) {
                    _userName = nameCtrl.text;
                    _nextStep();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter a name and select a role")),
                    );
                  }
                },
                child: const Text("INITIALIZE NETWORK →", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard(String title, String role, IconData icon, String subtitle) {
    bool isSel = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSel ? const Color(0xFFE53935) : Colors.grey.shade800, width: 2),
          color: isSel ? const Color(0xFFE53935).withOpacity(0.1) : const Color(0xFF1E1E1E),
          boxShadow: isSel ? [BoxShadow(color: const Color(0xFFE53935).withOpacity(0.2), blurRadius: 10)] : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: isSel ? const Color(0xFFE53935) : Colors.black26, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            if (isSel) const Icon(Icons.check_circle, color: Color(0xFFE53935)),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hub_outlined, size: 100, color: Color(0xFF8B0000)),
            const SizedBox(height: 30),
            const Text("Mesh Network Protocol", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            _stepInfo("1", "Rescue Teams create a local hotspot"),
            _stepInfo("2", "Survivors connect via Bluetooth/WiFi"),
            _stepInfo("3", "Real-time GPS & Chat without Internet"),
            const SizedBox(height: 60),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000), 
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: _nextStep,
              child: const Text("ESTABLISH CONNECTION", style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _stepInfo(String num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: const Color(0xFF8B0000), radius: 12, child: Text(num, style: const TextStyle(fontSize: 12, color: Colors.white))),
          const SizedBox(width: 15),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15, color: Colors.white70))),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final String userName;
  final String role;
  const DashboardScreen({super.key, required this.userName, required this.role});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final Strategy strategy = Strategy.P2P_CLUSTER;
  final MapController _mapController = MapController();
  Map<String, Map<String, dynamic>> peers = {}; 
  List<Map<String, dynamic>> chatMessages = [];
  List<String> liveFeedLogs = [];
  Set<String> connectedEndPoints = {};
  bool isMeshActive = false;
  bool isDownloadingMap = false;
  double downloadProgress = 0.0;
  Position? _myPos;
  Timer? _locationTimer;

  // FIXED: Reliable tile URL and User-Agent
  final String mapUrl = "https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png";
  final String userAgent = "com.dams.emergency.app";

  @override
  void initState() {
    super.initState();
    _initMesh();
    _getCurrentLocation();
    // Periodic location broadcast for survivors
    if (widget.role == 'survivor') {
      _locationTimer = Timer.periodic(const Duration(seconds: 15), (timer) => _broadcastLocation());
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
    super.dispose();
  }

  void _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _myPos = position;
      });
      _mapController.move(LatLng(position.latitude, position.longitude), 15);
    } catch (e) {
      debugPrint("Location Error: $e");
    }
  }

  void _initMesh() async {
    await [Permission.location, Permission.bluetooth, Permission.bluetoothScan, Permission.bluetoothConnect, Permission.bluetoothAdvertise, Permission.nearbyWifiDevices].request();
    
    if (widget.role == 'rescue') {
      await Nearby().startAdvertising(widget.userName, strategy,
        onConnectionInitiated: (id, info) => Nearby().acceptConnection(id, onPayLoadRecieved: _onPayload),
        onConnectionResult: (id, status) { 
          if (status == Status.CONNECTED) {
            setState(() {
              isMeshActive = true;
              connectedEndPoints.add(id);
              liveFeedLogs.insert(0, "NEW PEER: $id joined the mesh");
            });
          }
        },
        onDisconnected: (id) => setState(() {
          peers.remove(id);
          connectedEndPoints.remove(id);
          liveFeedLogs.insert(0, "PEER LOST: $id disconnected");
        }),
      );
    } else {
      await Nearby().startDiscovery(widget.userName, strategy,
        onEndpointFound: (id, name, serviceId) {
          Nearby().requestConnection(
            widget.userName,
            id,
            onConnectionInitiated: (id, info) => Nearby().acceptConnection(id, onPayLoadRecieved: _onPayload),
            onConnectionResult: (id, status) {
              if (status == Status.CONNECTED) {
                setState(() {
                  isMeshActive = true;
                  connectedEndPoints.add(id);
                  liveFeedLogs.insert(0, "CONNECTED: Linked to $id");
                });
              }
            },
            onDisconnected: (id) => setState(() {
              peers.remove(id);
              connectedEndPoints.remove(id);
              liveFeedLogs.insert(0, "DISCONNECTED: Link to $id lost");
            }),
          );
        },
        onEndpointLost: (id) {},
      );
    }
  }

  void _onPayload(String id, Payload payload) {
    if (payload.type == PayloadType.BYTES) {
      final data = jsonDecode(String.fromCharCodes(payload.bytes!));
      setState(() {
        if (data['type'] == 'LOC' || data['type'] == 'SOS') {
          peers[id] = {
            'name': data['sender'],
            'lat': data['lat'],
            'lng': data['lng'],
            'role': data['role'],
            'type': data['type'],
            'time': DateTime.now()
          };
          liveFeedLogs.insert(0, "${data['type']} SIGNAL: ${data['sender']} (${data['role']})");
        } else if (data['type'] == 'CHAT') {
          chatMessages.add({'sender': data['sender'], 'text': data['text'], 'isMe': false});
        }
      });
    }
  }

  void _broadcast(String data) {
    Uint8List bytes = Uint8List.fromList(data.codeUnits);
    for (String id in connectedEndPoints) {
      Nearby().sendBytesPayload(id, bytes);
    }
  }

  void _broadcastLocation() async {
    try {
      _myPos = await Geolocator.getCurrentPosition();
      final data = jsonEncode({
        'type': 'LOC',
        'sender': widget.userName,
        'role': widget.role,
        'lat': _myPos!.latitude,
        'lng': _myPos!.longitude
      });
      _broadcast(data);
    } catch (e) {
      debugPrint("Broadcast Error: $e");
    }
  }

  void _sendSOS() async {
    try {
      _myPos = await Geolocator.getCurrentPosition();
      final data = jsonEncode({
        'type': 'SOS',
        'sender': widget.userName,
        'role': widget.role,
        'lat': _myPos!.latitude,
        'lng': _myPos!.longitude
      });
      _broadcast(data);
      setState(() => liveFeedLogs.insert(0, "CRITICAL: SOS Transmitted!"));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("SOS SIGNAL BROADCASTED"), backgroundColor: Colors.red),
      );
    } catch (e) {
      debugPrint("SOS Error: $e");
    }
  }

  void _downloadRegion() async {
    if (_myPos == null) return;
    setState(() {
      isDownloadingMap = true;
      downloadProgress = 0.0;
    });

    try {
      List<int> zoomLevels = [13, 14, 15];
      int totalTiles = zoomLevels.length * 25; 
      int downloadedTiles = 0;

      for (int z in zoomLevels) {
        double latRad = _myPos!.latitude * math.pi / 180;
        int n = math.pow(2, z).toInt();
        int xtile = ((_myPos!.longitude + 180) / 360 * n).floor();
        int ytile = ((1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) / 2 * n).floor();

        for (int x = xtile - 2; x <= xtile + 2; x++) {
          for (int y = ytile - 2; y <= ytile + 2; y++) {
            String url = "https://a.basemaps.cartocdn.com/dark_all/$z/$x/$y.png";
            await precacheImage(NetworkImage(url, headers: {'User-Agent': userAgent}), context);
            downloadedTiles++;
            setState(() => downloadProgress = downloadedTiles / totalTiles);
          }
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Offline Region Cached!"), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cache Failed: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => isDownloadingMap = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        elevation: 10,
        title: Row(
          children: [
            const Icon(Icons.security, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("D.A.M.S. | ${widget.role.toUpperCase()}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const Text("MESH NETWORK ACTIVE", style: TextStyle(fontSize: 9, color: Colors.white70, letterSpacing: 2)),
              ],
            ),
          ],
        ),
      ),
      body: _buildCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF121212),
        selectedItemColor: const Color(0xFFE53935),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.radar), label: "COMMS"),
          BottomNavigationBarItem(icon: Icon(Icons.forum_outlined), label: "CHAT"),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: "MAP"),
        ],
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0: return _buildCommsView();
      case 1: return _buildChatView();
      case 2: return _buildMapView();
      default: return _buildCommsView();
    }
  }

  Widget _buildCommsView() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard("PEERS", "${peers.length}", Icons.people_outline)),
              const SizedBox(width: 15),
              Expanded(child: _buildStatCard("LOGS", "${liveFeedLogs.length}", Icons.history)),
            ],
          ),
          const SizedBox(height: 30),
          const Align(alignment: Alignment.centerLeft, child: Text("LIVE NETWORK FEED", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5))),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
              child: ListView.builder(
                itemCount: liveFeedLogs.length,
                itemBuilder: (ctx, i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text("> ${liveFeedLogs[i]}", style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontFamily: 'monospace')),
                ),
              ),
            ),
          ),
          if (widget.role == 'survivor') ...[
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935), 
                minimumSize: const Size(double.infinity, 70),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 10,
              ),
              onPressed: _sendSOS,
              child: const Text("BROADCAST SOS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, fontStyle: FontStyle.italic)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFE53935), size: 24),
          const SizedBox(height: 15),
          Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChatView() {
    final TextEditingController chatCtrl = TextEditingController();
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: chatMessages.length,
            itemBuilder: (ctx, i) {
              final m = chatMessages[i];
              bool isMe = m['isMe'] ?? false;
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(m['sender'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isMe ? const Color(0xFF8B0000) : const Color(0xFF1E1E1E), 
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(15),
                          topRight: const Radius.circular(15),
                          bottomLeft: isMe ? const Radius.circular(15) : Radius.zero,
                          bottomRight: isMe ? Radius.zero : const Radius.circular(15),
                        )
                      ),
                      child: Text(m['text'], style: const TextStyle(color: Colors.white, fontSize: 14)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(15),
          color: Colors.black,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: chatCtrl, 
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Broadcast to mesh...",
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  )
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                backgroundColor: const Color(0xFFE53935),
                child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: () {
                  if (chatCtrl.text.isNotEmpty) {
                    final data = jsonEncode({'type': 'CHAT', 'sender': widget.userName, 'text': chatCtrl.text});
                    _broadcast(data);
                    setState(() => chatMessages.add({'sender': 'Me', 'text': chatCtrl.text, 'isMe': true}));
                    chatCtrl.clear();
                  }
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapView() {
    int activeSosCount = peers.values.where((p) => p['type'] == 'SOS').length;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _myPos != null ? LatLng(_myPos!.latitude, _myPos!.longitude) : LatLng(0, 0), 
            initialZoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate: mapUrl,
              userAgentPackageName: userAgent,
            ),
            MarkerLayer(
              markers: [
                if (_myPos != null)
                  Marker(
                    point: LatLng(_myPos!.latitude, _myPos!.longitude),
                    width: 40, height: 40,
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.blue, width: 3)),
                      child: const Icon(Icons.person, color: Colors.blue, size: 20),
                    ),
                  ),
                ...peers.values.map((p) => Marker(
                  point: LatLng(p['lat'], p['lng']),
                  width: 50, height: 50,
                  child: Column(
                    children: [
                      Icon(
                        p['type'] == 'SOS' ? Icons.warning : Icons.location_on, 
                        color: p['role'] == 'rescue' ? Colors.blue : const Color(0xFFE53935), 
                        size: 35
                      ),
                      Text(p['name'], style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, backgroundColor: Colors.black54)),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ],
        ),
        
        // MAP CONTROLS
        Positioned(
          top: 20,
          right: 20,
          child: Column(
            children: [
              _mapActionButton(Icons.my_location, Colors.white, Colors.black, _getCurrentLocation),
              const SizedBox(height: 10),
              _mapActionButton(
                isDownloadingMap ? Icons.hourglass_empty : Icons.download_for_offline, 
                isDownloadingMap ? Colors.grey : const Color(0xFFE53935), 
                Colors.white, 
                isDownloadingMap ? null : _downloadRegion
              ),
            ],
          ),
        ),

        // BOTTOM OVERLAY
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Column(
            children: [
              if (isDownloadingMap)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(value: downloadProgress, backgroundColor: Colors.white24, color: const Color(0xFFE53935), minHeight: 6),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: activeSosCount > 0 ? Colors.red : Colors.green, shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        Text("$activeSosCount ACTIVE SOS SIGNALS", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => setState(() => peers.clear()),
                      child: const Text("CLEAR", style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mapActionButton(IconData icon, Color bg, Color iconColor, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)],
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
    );
  }
}