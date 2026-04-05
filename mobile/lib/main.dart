import 'package:flutter/material.dart';

void main() {
  runApp(const SafeGuardApp());
}

class SafeGuardApp extends StatelessWidget {
  const SafeGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SafeGuard Mobile',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      ),
      home: const DashboardScreen(),
    );
  }
}

// ---------------- DASHBOARD ----------------
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String status = "SAFE";

  Color getStatusColor() {
    switch (status) {
      case "RISK":
        return Colors.red;
      case "WARNING":
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  void simulateScan() {
    setState(() {
      status = "WARNING";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SafeGuard Mobile')),
      floatingActionButton: FloatingActionButton(
        onPressed: simulateScan,
        child: const Icon(Icons.security),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.shield, size: 50, color: getStatusColor()),
                    const SizedBox(height: 10),
                    Text(
                      status,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: getStatusColor()),
                    ),
                    const Text("Your device is protected"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  buildMenu(context, "Apps", Icons.apps, const AppsScreen()),
                  buildMenu(context, "Permissions", Icons.lock, const PermissionsScreen()),
                  buildMenu(context, "Network", Icons.wifi, const NetworkScreen()),
                  buildMenu(context, "Alerts", Icons.warning, const AlertsScreen()),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildMenu(BuildContext context, String title, IconData icon, Widget screen) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 10),
            Text(title)
          ],
        ),
      ),
    );
  }
}

// ---------------- APPS SCREEN ----------------
class AppsScreen extends StatelessWidget {
  const AppsScreen({super.key});

  final List<Map<String, dynamic>> apps = const [
    {"name": "Facebook", "risk": "LOW"},
    {"name": "Unknown App", "risk": "HIGH"},
    {"name": "Bank App", "risk": "SAFE"},
  ];

  Color getColor(String risk) {
    switch (risk) {
      case "HIGH":
        return Colors.red;
      case "LOW":
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Apps Scan")),
      body: ListView.builder(
        itemCount: apps.length,
        itemBuilder: (context, index) {
          final app = apps[index];
          return ListTile(
            leading: const Icon(Icons.apps),
            title: Text(app['name']),
            trailing: Text(
              app['risk'],
              style: TextStyle(color: getColor(app['risk'])),
            ),
          );
        },
      ),
    );
  }
}

// ---------------- PERMISSIONS ----------------
class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Permissions")),
      body: ListView(
        children: [
          permissionTile("Camera", true),
          permissionTile("Microphone", false),
          permissionTile("Location", false),
        ],
      ),
    );
  }

  Widget permissionTile(String name, bool safe) {
    return ListTile(
      title: Text(name),
      trailing: Icon(
        safe ? Icons.check : Icons.warning,
        color: safe ? Colors.green : Colors.orange,
      ),
    );
  }
}

// ---------------- NETWORK ----------------
class NetworkScreen extends StatelessWidget {
  const NetworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Network")),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi, size: 50),
            SizedBox(height: 10),
            Text("Wi-Fi Secure"),
          ],
        ),
      ),
    );
  }
}

// ---------------- ALERTS ----------------
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Alerts")),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.warning, color: Colors.red),
            title: Text("Unknown app detected"),
            subtitle: Text("High risk"),
          ),
        ],
      ),
    );
  }
}
