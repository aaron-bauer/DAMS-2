import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; // Corrected import path
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:typed_data';

void main() => runApp(DamsApp());

class DamsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'D.A.M.S.',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1A2B47),
        scaffoldBackgroundColor: Colors.white,
      ),
      // App now starts directly at the Home screen
      home: const DamsHome(),
    );
  }
}

class DamsHome extends StatefulWidget {
  const DamsHome({super.key});

  @override
  _DamsHomeState createState() => _DamsHomeState();
}

class _DamsHomeState extends State<DamsHome> {
  final Strategy strategy = Strategy.P2P_CLUSTER;
  final String userName = "User_${DateTime.now().millisecondsSinceEpoch}";
  Map<String, String> connectedPeers = {};
  List<Marker> sosMarkers = [];
  bool isMeshActive = false;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _startMesh();
  }

  void _startMesh() async {
    // Request all necessary permissions for Mesh Networking
    await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.nearbyWifiDevices
    ].request();

    try {
      // Start Advertising (Beacon)
      await Nearby().startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: (id, info) => Nearby().acceptConnection(id, onPayLoadRecieved: _onPayload),
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) setState(() => connectedPeers[id] = "Peer");
        },
        onDisconnected: (id) => setState(() => connectedPeers.remove(id)),
      );

      // Start Discovery (Scanner)
      await Nearby().startDiscovery(
        userName,
        strategy,
        onEndpointFound: (id, name, serviceId) {
          Nearby().requestConnection(
            userName,
            id,
            onConnectionInitiated: (id, info) {
              Nearby().acceptConnection(id, onPayLoadRecieved: _onPayload);
            },
            onConnectionResult: (id, status) {
              if (status == Status.CONNECTED) setState(() => connectedPeers[id] = "Peer");
            },
            onDisconnected: (id) => setState(() => connectedPeers.remove(id)),
          );
        },
        onEndpointLost: (id) {},
      );
      setState(() => isMeshActive = true);
    } catch (e) {
      debugPrint("Mesh Error: $e");
    }
  }

  void _onPayload(String id, Payload payload) {
    if (payload.type == PayloadType.BYTES) {
      var data = jsonDecode(String.fromCharCodes(payload.bytes!));
      setState(() {
        if (data['type'] == 'SOS') {
          sosMarkers.add(
            Marker(
              point: LatLng(data['lat'], data['lng']),
              child: const Icon(Icons.warning, color: Colors.red, size: 40),
            ),
          );
        }
      });
    }
  }

  void _sendSOS() async {
    Position pos = await Geolocator.getCurrentPosition();
    var data = {
      "type": "SOS",
      "sender": userName,
      "lat": pos.latitude,
      "lng": pos.longitude,
      "timestamp": DateTime.now().toIso8601String()
    };
    Uint8List bytes = Uint8List.fromList(jsonEncode(data).codeUnits);
    for (String id in connectedPeers.keys) {
      Nearby().sendBytesPayload(id, bytes);
    }
    // Also show it on our own map
    _onPayload("local", Payload(id: 1, type: PayloadType.BYTES, bytes: bytes));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2B47),
        title: const Text("D.A.M.S. Mesh Network"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Center(
              child: Text(
                "${connectedPeers.length} Peers",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(0, 0),
              initialZoom: 2,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(markers: sosMarkers),
            ],
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 65),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 8,
              ),
              onPressed: _sendSOS,
              child: const Text(
                "SEND EMERGENCY SOS",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          if (!isMeshActive)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}