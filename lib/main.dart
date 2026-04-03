import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';

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
  void _goToStep(int step) => setState(() => _currentStep = step);

  @override
  void initState() {
    super.initState();
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
            const Text("D.A.M.S", style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white)),
            const Text("Offline Emergency Coordination", style: TextStyle(fontSize: 16, color: Colors.white70)),
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
              const Text("Welcome to D.A.M.S", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const Text("Select your role to continue", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  hintText: "Enter your name",
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 30),
              _roleCard("Rescue Team", "rescue", Icons.shield_outlined),
              const SizedBox(height: 15),
              _roleCard("Survivor", "survivor", Icons.location_on_outlined),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B0000),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty && _selectedRole != null) {
                    _userName = nameCtrl.text;
                    _nextStep();
                  }
                },
                child: const Text("Start Network →", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard(String title, String role, IconData icon) {
    bool isSel = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSel ? const Color(0xFFE53935) : Colors.grey.shade800),
          color: isSel ? const Color(0xFFE53935).withOpacity(0.1) : const Color(0xFF1E1E1E),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSel ? const Color(0xFFE53935) : Colors.white),
            const SizedBox(width: 20),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("How It Works", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            const Text("1. Rescue Team creates hotspot\n2. Survivors connect via Bluetooth/WiFi\n3. Real-time GPS & Chat enabled", textAlign: TextAlign.center),
            const SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B0000), minimumSize: const Size(double.infinity, 56)),
              onPressed: _nextStep,
              child: const Text("Got It, Let's Start"),
            )
          ],
        ),
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
  Map<String, Map<String, dynamic>> peers = {}; // id -> {name, lat, lng, role, time}
  List<Map<String, dynamic>> chatMessages = [];
  List<String> liveFeedLogs = [];
  Set<String> connectedEndPoints = {};
  bool isMeshActive = false;
  Position? _myPos;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _initMesh();
    _getCurrentLocation();
    if (widget.role == 'survivor') {
      _locationTimer = Timer.periodic(const Duration(seconds: 15), (timer) => _broadcastLocation());
    }
  }

  void _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _myPos = position;
      _mapController.move(LatLng(position.latitude, position.longitude), 15);
    });
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
              liveFeedLogs.insert(0, "New connection: $id");
            });
          }
        },
        onDisconnected: (id) => setState(() {
          peers.remove(id);
          connectedEndPoints.remove(id);
          liveFeedLogs.insert(0, "Peer disconnected: $id");
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
                  liveFeedLogs.insert(0, "Connected to: $id");
                });
              }
            },
            onDisconnected: (id) => setState(() {
              peers.remove(id);
              connectedEndPoints.remove(id);
              liveFeedLogs.insert(0, "Disconnected from: $id");
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
            'role': data['role'], // Store the peer's role
            'time': DateTime.now()
          };
          liveFeedLogs.insert(0, "${data['type']} from ${data['sender']} (${data['role']})");
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
    _myPos = await Geolocator.getCurrentPosition();
    final data = jsonEncode({
      'type': 'LOC',
      'sender': widget.userName,
      'role': widget.role, // Broadcast own role
      'lat': _myPos!.latitude,
      'lng': _myPos!.longitude
    });
    _broadcast(data);
    setState(() {});
  }

  void _sendSOS() async {
    _myPos = await Geolocator.getCurrentPosition();
    final data = jsonEncode({
      'type': 'SOS',
      'sender': widget.userName,
      'role': widget.role, // Broadcast own role
      'lat': _myPos!.latitude,
      'lng': _myPos!.longitude
    });
    _broadcast(data);
    setState(() => liveFeedLogs.insert(0, "SOS Transmitted!"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        title: Row(
          children: [
            const Icon(Icons.shield, color: Colors.white),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("D.A.M.S.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("DISASTER AID MANAGEMENT", style: TextStyle(fontSize: 10, color: Colors.white70)),
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
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.sensors), label: "COMMS"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "CHAT"),
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard("ACTIVE PEERS", "${peers.length}", Icons.people_outline)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard("TOTAL LOGS", "${liveFeedLogs.length}", Icons.chat_outlined)),
            ],
          ),
          const SizedBox(height: 24),
          const Align(alignment: Alignment.centerLeft, child: Text("LIVE FEED", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey))),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
              child: ListView.builder(
                itemCount: liveFeedLogs.length,
                itemBuilder: (ctx, i) => Text(liveFeedLogs[i], style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            ),
          ),
          if (widget.role == 'survivor') ...[
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), minimumSize: const Size(double.infinity, 60)),
              onPressed: _sendSOS,
              child: const Text("SEND EMERGENCY SOS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ]),
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
            padding: const EdgeInsets.all(16),
            itemCount: chatMessages.length,
            itemBuilder: (ctx, i) {
              final m = chatMessages[i];
              return Align(
                alignment: m['isMe'] ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: m['isMe'] ? const Color(0xFFE53935) : const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
                  child: Text(m['text'], style: const TextStyle(color: Colors.white)),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: TextField(controller: chatCtrl, decoration: const InputDecoration(hintText: "Type a message..."))),
              IconButton(icon: const Icon(Icons.send, color: Color(0xFFE53935)), onPressed: () {
                if (chatCtrl.text.isNotEmpty) {
                  final data = jsonEncode({'type': 'CHAT', 'sender': widget.userName, 'text': chatCtrl.text});
                  _broadcast(data);
                  setState(() => chatMessages.add({'sender': 'Me', 'text': chatCtrl.text, 'isMe': true}));
                  chatCtrl.clear();
                }
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: LatLng(0, 0), initialZoom: 13),
          children: [
            TileLayer(
              urlTemplate: "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png",
              subdomains: const ['a', 'b', 'c', 'd'],
            ),
            MarkerLayer(
              markers: [
                // Your location marker
                if (_myPos != null)
                  Marker(
                    point: LatLng(_myPos!.latitude, _myPos!.longitude),
                    child: Icon(
                      Icons.my_location, 
                      color: widget.role == 'rescue' ? Colors.blue : const Color(0xFFE53935), 
                      size: 30
                    ),
                  ),
                // Peer markers
                ...peers.values.map((p) => Marker(
                  point: LatLng(p['lat'], p['lng']),
                  child: Icon(
                    Icons.location_on, 
                    // Blue for Rescue Team, Red for Survivors
                    color: p['role'] == 'rescue' ? Colors.blue : const Color(0xFFE53935), 
                    size: 40
                  ),
                )).toList(),
              ],
            ),
          ],
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: const Color(0xFFE53935),
            onPressed: _getCurrentLocation,
            child: const Icon(Icons.gps_fixed, color: Colors.white),
          ),
        ),
      ],
    );
  }
}