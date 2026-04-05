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
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF8B0000),
          elevation: 0,
          centerTitle: true,
        ),
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
    // Splash screen delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _currentStep == 0) _nextStep();
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
            const Icon(Icons.sensors, size: 100, color: Color(0xFFE53935)),
            const SizedBox(height: 30),
            const Text("D.A.M.S", 
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 8)),
            const SizedBox(height: 10),
            const Text("DISASTER AID MANAGEMENT SYSTEM", 
              style: TextStyle(fontSize: 12, color: Colors.white54, letterSpacing: 2)),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Color(0xFFE53935), strokeWidth: 2),
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
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("IDENTIFICATION", 
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1)),
              const Text("Establish your network identity", 
                style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 50),
              const Text("CALLSIGN", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: "Enter your name/ID",
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  contentPadding: const EdgeInsets.all(20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.account_circle_outlined, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 40),
              const Text("OPERATIONAL ROLE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 15),
              _roleCard("Rescue Team", "rescue", Icons.shield_outlined, "Coordinate aid and locate survivors"),
              const SizedBox(height: 15),
              _roleCard("Survivor", "survivor", Icons.local_fire_department_outlined, "Broadcast location and request aid"),
              const SizedBox(height: 50),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B0000),
                  minimumSize: const Size(double.infinity, 65),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                onPressed: () {
                  if (nameCtrl.text.trim().isNotEmpty && _selectedRole != null) {
                    setState(() => _userName = nameCtrl.text.trim());
                    _nextStep();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter a name and select a role"))
                    );
                  }
                },
                child: const Text("INITIALIZE MESH →", 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSel ? const Color(0xFFE53935) : Colors.grey.shade800, width: 2),
          color: isSel ? const Color(0xFFE53935).withOpacity(0.1) : const Color(0xFF1E1E1E),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFFE53935) : Colors.grey.shade900,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
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
            const Icon(Icons.hub_outlined, size: 80, color: Color(0xFFE53935)),
            const SizedBox(height: 30),
            const Text("MESH PROTOCOL", 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 40),
            _guideItem(Icons.wifi_tethering, "Rescue Teams create a local mesh hotspot."),
            _guideItem(Icons.bluetooth_searching, "Survivors automatically discover and link."),
            _guideItem(Icons.map_outlined, "Real-time GPS data flows through the chain."),
            _guideItem(Icons.offline_bolt, "No internet or cellular data required."),
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

  Widget _guideItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE53935), size: 20),
          const SizedBox(width: 20),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14))),
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

  @override
  void initState() {
    super.initState();
    _initMesh();
    _getCurrentLocation();
    if (widget.role == 'survivor') {
      _locationTimer = Timer.periodic(const Duration(seconds: 15), (timer) => _broadcastLocation());
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
    Nearby().stopAllEndpoints();
    super.dispose();
  }

  void _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _myPos = position;
          _mapController.move(LatLng(position.latitude, position.longitude), 15);
        });
      }
    } catch (e) {
      _log("Location Error: $e");
    }
  }

  void _log(String msg) {
    final time = DateTime.now().toString().split(' ')[1].split('.')[0];
    if (mounted) {
      setState(() => liveFeedLogs.insert(0, "[$time] $msg"));
    }
  }

  void _initMesh() async {
    await [
      Permission.location, 
      Permission.bluetooth, 
      Permission.bluetoothScan, 
      Permission.bluetoothConnect, 
      Permission.bluetoothAdvertise, 
      Permission.nearbyWifiDevices
    ].request();

    if (widget.role == 'rescue') {
      _log("Starting Mesh Hotspot...");
      await Nearby().startAdvertising(widget.userName, strategy,
        onConnectionInitiated: (id, info) => Nearby().acceptConnection(id, onPayLoadRecieved: _onPayload),
        onConnectionResult: (id, status) { 
          if (status == Status.CONNECTED) {
            setState(() {
              isMeshActive = true;
              connectedEndPoints.add(id);
            });
            _log("New peer linked: $id");
          }
        },
        onDisconnected: (id) => setState(() {
          peers.remove(id);
          connectedEndPoints.remove(id);
          _log("Peer lost: $id");
        }),
      );
    } else {
      _log("Scanning for Mesh...");
      await Nearby().startDiscovery(widget.userName, strategy,
        onEndpointFound: (id, name, serviceId) {
          _log("Found node: $name");
          Nearby().requestConnection(
            widget.userName,
            id,
            onConnectionInitiated: (id, info) => Nearby().acceptConnection(id, onPayLoadRecieved: _onPayload),
            onConnectionResult: (id, status) {
              if (status == Status.CONNECTED) {
                setState(() {
                  isMeshActive = true;
                  connectedEndPoints.add(id);
                });
                _log("Linked to node: $name");
              }
            },
            onDisconnected: (id) => setState(() {
              peers.remove(id);
              connectedEndPoints.remove(id);
              _log("Lost link to node: $id");
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
      if (mounted) {
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
            if (data['type'] == 'SOS') {
              _log("!!! SOS RECEIVED FROM ${data['sender']} !!!");
            }
          } else if (data['type'] == 'CHAT') {
            chatMessages.add({'sender': data['sender'], 'text': data['text'], 'isMe': false});
          }
        });
      }
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
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Broadcast Error: $e");
    }
  }

  void _sendSOS() async {
    _myPos = await Geolocator.getCurrentPosition();
    final data = jsonEncode({
      'type': 'SOS',
      'sender': widget.userName,
      'role': widget.role,
      'lat': _myPos!.latitude,
      'lng': _myPos!.longitude
    });
    _broadcast(data);
    _log("EMERGENCY SOS BROADCASTED");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("SOS SIGNAL SENT TO ALL PEERS"), backgroundColor: Colors.red)
    );
  }

  void _downloadRegion() async {
    if (_myPos == null) return;
    setState(() {
      isDownloadingMap = true;
      downloadProgress = 0.0;
    });

    try {
      List<int> zoomLevels = [13, 14, 15, 16];
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
            await precacheImage(NetworkImage(url, headers: {'User-Agent': 'com.dams.app'}), context);
            downloadedTiles++;
            if (mounted) setState(() => downloadProgress = downloadedTiles / totalTiles);
          }
        }
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Offline Map Region Saved!"), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Download Failed: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => isDownloadingMap = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text("D.A.M.S. DASHBOARD", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: connectedEndPoints.isNotEmpty ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(connectedEndPoints.isNotEmpty ? "MESH ACTIVE" : "SCANNING...", 
                  style: const TextStyle(fontSize: 10, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.info_outline), onPressed: () {
            showAboutDialog(context: context, applicationName: "D.A.M.S.", applicationVersion: "1.0.0-Release");
          }),
        ],
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
              Expanded(child: _buildStatCard("CONNECTED", "${connectedEndPoints.length}", Icons.link)),
            ],
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("LIVE NETWORK FEED", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
              child: liveFeedLogs.isEmpty 
                ? const Center(child: Text("Waiting for network activity...", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: liveFeedLogs.length,
                    itemBuilder: (ctx, i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(liveFeedLogs[i], style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace')),
                    ),
                  ),
            ),
          ),
          if (widget.role == 'survivor') ...[
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935), 
                minimumSize: const Size(double.infinity, 65),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: _sendSOS,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Text("SEND EMERGENCY SOS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
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
          Icon(icon, color: const Color(0xFFE53935), size: 20),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildChatView() {
    final TextEditingController chatCtrl = TextEditingController();
    return Column(
      children: [
        Expanded(
          child: chatMessages.isEmpty 
            ? const Center(child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 50, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("No messages in mesh", style: TextStyle(color: Colors.grey)),
                ],
              ))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: chatMessages.length,
                itemBuilder: (ctx, i) {
                  final m = chatMessages[i];
                  bool isMe = m['isMe'] ?? false;
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text(
                            isMe ? "Me" : m['sender'],
                            style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFFE53935) : const Color(0xFF1E1E1E), 
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(15),
                              topRight: const Radius.circular(15),
                              bottomLeft: isMe ? const Radius.circular(15) : Radius.zero,
                              bottomRight: isMe ? Radius.zero : const Radius.circular(15),
                            ),
                          ),
                          child: Text(m['text'], style: const TextStyle(color: Colors.white, fontSize: 15)),
                        ),
                      ],
                    ),
                  );
                },
              ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF121212),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: chatCtrl,
                  decoration: InputDecoration(
                    hintText: "Type a mesh message...",
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                backgroundColor: const Color(0xFFE53935),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20), 
                  onPressed: () {
                    if (chatCtrl.text.trim().isNotEmpty) {
                      final data = jsonEncode({'type': 'CHAT', 'sender': widget.userName, 'text': chatCtrl.text.trim()});
                      _broadcast(data);
                      setState(() => chatMessages.add({'sender': 'Me', 'text': chatCtrl.text.trim(), 'isMe': true}));
                      chatCtrl.clear();
                    }
                  }
                ),
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
              urlTemplate: "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png",
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.dams.app',
            ),
            MarkerLayer(
              markers: [
                if (_myPos != null)
                  Marker(
                    point: LatLng(_myPos!.latitude, _myPos!.longitude),
                    width: 80, height: 80,
                    child: Column(
                      children: [
                        Icon(
                          widget.role == 'rescue' ? Icons.shield : Icons.local_fire_department, 
                          color: widget.role == 'rescue' ? Colors.blue : const Color(0xFFE53935), 
                          size: 30
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                          child: const Text("YOU", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ...peers.values.map((p) => Marker(
                  point: LatLng(p['lat'], p['lng']),
                  width: 80, height: 80,
                  child: Column(
                    children: [
                      Icon(
                        p['type'] == 'SOS' ? Icons.warning : (p['role'] == 'rescue' ? Icons.shield : Icons.local_fire_department), 
                        color: p['role'] == 'rescue' ? Colors.blue : const Color(0xFFE53935), 
                        size: 40
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                        child: Text(p['name'], style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ],
        ),
        Positioned(
          top: 20,
          right: 20,
          child: Column(
            children: [
              _mapActionButton(Icons.near_me, Colors.white, Colors.black, _getCurrentLocation),
              const SizedBox(height: 12),
              _mapActionButton(
                Icons.download_for_offline, 
                isDownloadingMap ? Colors.grey : const Color(0xFFE53935), 
                Colors.white, 
                isDownloadingMap ? null : _downloadRegion,
                isLoading: isDownloadingMap
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Column(
            children: [
              if (isDownloadingMap)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: downloadProgress, 
                      backgroundColor: Colors.white12, 
                      color: const Color(0xFFE53935),
                      minHeight: 6,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.9), 
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: activeSosCount > 0 ? Colors.red.withOpacity(0.5) : Colors.transparent),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: activeSosCount > 0 ? Colors.red : Colors.grey, size: 18),
                        const SizedBox(width: 10),
                        Text("$activeSosCount ACTIVE SOS SIGNALS", 
                          style: TextStyle(color: activeSosCount > 0 ? Colors.red : Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => setState(() => peers.clear()),
                      child: const Text("CLEAR MAP", 
                        style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold, fontSize: 13)),
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

  Widget _mapActionButton(IconData icon, Color bg, Color iconColor, VoidCallback? onTap, {bool isLoading = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg, 
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)],
        ),
        child: isLoading 
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Icon(icon, color: iconColor, size: 24),
      ),
    );
  }
}