# D.A.M.S. (Disaster Aid Management System) 2.0

A Flutter-based cross-platform emergency communication system that enables real-time mesh networking for disaster response without requiring internet or cellular connectivity.

## Overview

**D.A.M.S. 2.0** is designed for coordinating disaster response and aid distribution in areas where traditional communication infrastructure is unavailable. It creates a decentralized mesh network allowing rescue teams and survivors to communicate, share location data, and broadcast emergency signals.

### Key Features

- **🌐 Mesh Networking**: Creates a peer-to-peer mesh network using Bluetooth and nearby connections (no internet required)
- **📍 Real-Time GPS Tracking**: Broadcast and receive live location data from all connected nodes
- **🆘 Emergency SOS System**: Send and receive emergency distress signals with location information
- **💬 Mesh Chat**: Direct messaging between connected rescue teams and survivors
- **🗺️ Offline Maps**: Download map tiles for offline use in affected regions
- **📊 Network Dashboard**: Monitor active peers, connection status, and network activity in real-time
- **👥 Dual-Role System**: Support for both Rescue Teams (network coordinators) and Survivors (aid seekers)

## Architecture

### Platform Support

- **iOS** - Full support with Bluetooth connectivity
- **Android** - Full support with Bluetooth and NearbyConnections
- **macOS** - Compatible
- **Linux** - Compatible
- **Windows** - Compatible
- **Web** - Compatible

### Core Technologies

- **Framework**: [Flutter](https://flutter.dev/) 3.0+
- **Language**: Dart
- **Networking**: 
  - [nearby_connections](https://pub.dev/packages/nearby_connections) - P2P mesh clustering
  - [Geolocator](https://pub.dev/packages/geolocator) - GPS positioning and location services
- **Mapping**: [flutter_map](https://pub.dev/packages/flutter_map) with CartoDB dark tiles
- **State Management**: [Provider](https://pub.dev/packages/provider) 6.1.1+
- **Permissions**: [permission_handler](https://pub.dev/packages/permission_handler)
- **Icons**: [Lucide Icons](https://pub.dev/packages/lucide_icons)

## Getting Started

### Prerequisites

- Flutter SDK 3.0.0 or higher
- Dart SDK compatible with Flutter 3.0+
- Mobile device or emulator with Bluetooth support

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/aaron-bauer/DAMS-2.git
   cd DAMS-2
