import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'i_connectivity.dart';

class ConnectivityHandler extends IConnectivity {
  ConnectivityHandler._() {
    _init();
  }

  static final ConnectivityHandler _singleton = ConnectivityHandler._();

  factory ConnectivityHandler() => _singleton;

  final StreamController<bool> _hasConnectionController =
  StreamController<bool>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<bool>? _connectionStreamSubscription;

  void _init() async {
    _hasConnectionController.add(await checkConnection());

    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> event) {
      bool isConnected =
      !event.any((element) => element == ConnectivityResult.none);
      _hasConnectionController.add(isConnected);
    });
  }

  @override
  Stream<bool> get hasConnectionStream => _hasConnectionController.stream;

  Future<bool> checkConnection() async {
    List<ConnectivityResult> connectivityResult =
    await Connectivity().checkConnectivity();
    return !connectivityResult
        .any((element) => element == ConnectivityResult.none);
  }

  void _listenToConnectionChanges(
      {required String uid, Function? onDisconnect}) {
    _connectionStreamSubscription?.cancel(); // Prevent multiple listeners

    _connectionStreamSubscription = hasConnectionStream.listen((isConnected) {
      _updatePresence(
          uid: uid, isOnline: isConnected, onDisconnect: onDisconnect);
      debugPrint('ConnectivityHandler: User is online: $isConnected');
    });
  }

  void _updatePresence(
      {required String uid, required bool isOnline, Function? onDisconnect}) {
    updatePresence(
        uid: uid,
        isOnline: isOnline,
        onDisconnectSuccess: () {
          debugPrint('ConnectivityHandler: onDisconnect triggered');
          onDisconnect?.call();
        },
        onDisconnectError: (error) {
          debugPrint('ConnectivityHandler: onDisconnectError: $error');
        });
  }

  @override
  void dispose() {
    _hasConnectionController.close();
    _connectivitySubscription?.cancel();
    _connectionStreamSubscription?.cancel();
  }

  @override
  void connect({required String uid, Function? onDisconnect}) {
    _listenToConnectionChanges(uid: uid, onDisconnect: onDisconnect);
  }

  @override
  void forceDisconnect({required String uid, Function? onForceDisconnect}) {
    _updatePresence(
        uid: uid,
        isOnline: false,
        onDisconnect: () {
          debugPrint('ConnectivityHandler: User forcibly disconnected');
          onForceDisconnect?.call();
        });
  }
}
