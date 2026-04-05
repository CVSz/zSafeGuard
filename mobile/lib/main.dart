import 'package:flutter/material.dart';

const String baseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:8000',
);

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Home());
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SafeGuard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Scan Ready'),
            SizedBox(height: 12),
            Text('API: $baseUrl'),
          ],
        ),
      ),
    );
  }
}
