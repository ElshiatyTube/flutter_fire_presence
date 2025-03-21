import 'package:flutter/material.dart';
import 'package:flutter_fire_presence/fire_presence_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final String _testUserId = 'testuser1'; //Simulated user id
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Handles app lifecycle changes if needed(Foreground, Background, Terminated)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isLoggedIn) {
      switch (state) {
        case AppLifecycleState.resumed:
          debugPrint('App in foreground, reconnecting...');
          FirePresenceHandler().connect(uid: _testUserId);
          break;
        case AppLifecycleState.paused:
          debugPrint('App in background, setting offline presence...');
          FirePresenceHandler().forceDisconnect(uid: _testUserId);
          break;
        case AppLifecycleState.detached:
          debugPrint('App terminated, setting offline presence...');
          FirePresenceHandler().forceDisconnect(uid: _testUserId);
          break;
        case AppLifecycleState.inactive:
          break;
        case AppLifecycleState.hidden:
          break;
      }
    }
  }

  /// Simulates user login
  void loginConnect() {
    FirePresenceHandler().connect(
      uid: _testUserId,
      onSuccess: (isConnected) {
       //Do something
      },
      onError: (e) => debugPrint('Error: $e'),
    );
    setState(() {
      _isLoggedIn = true;
    });
  }

  /// Simulates user logout
  void logout() {
    FirePresenceHandler().forceDisconnect(
      uid: _testUserId,
      onSuccess: (isConnected) {
        //Do something
      },
      onError: (e) => debugPrint('Error: $e'),
    );
    setState(() {
      _isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('FirePresenceHandler Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_isLoggedIn ? 'User is Online' : 'User is Offline'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoggedIn ? null : loginConnect,
                child: const Text('Login & Connect'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isLoggedIn ? logout : null,
                child: const Text('Logout & Disconnect'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
