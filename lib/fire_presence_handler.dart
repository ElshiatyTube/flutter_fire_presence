import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'i_connectivity.dart';

class FirePresenceHandler extends IFirePresenceHandler {
  FirePresenceHandler._();

  static final FirePresenceHandler _singleton = FirePresenceHandler._();

  factory FirePresenceHandler() => _singleton;

  final _hasConnectionController = StreamController<bool>.broadcast();
  StreamSubscription<bool>? _hasConnectionStreamSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isInitialized = false;

  void _init() {
    if (_isInitialized) return;

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((event) {
      bool isConnected = !event.any((element) => element == ConnectivityResult.none);
      _hasConnectionController.add(isConnected);
    });

    _isInitialized = true;
    debugPrint('FirePresenceHandler: Initialized.');
  }

  @override
  Stream<bool> get hasConnectionStream => _hasConnectionController.stream;

  Future<bool> _checkConnection() async {
    List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.any((element) => element == ConnectivityResult.none);
  }

  void _listenToConnectionChanges({
    required String uid,
    Function(bool)? onSuccess,
    Function? onError,
  }) {
    _hasConnectionStreamSubscription?.cancel();
    try {
      _hasConnectionStreamSubscription = hasConnectionStream.listen((isConnected) {
        debugPrint('ConnectivityHandler: User is online: $isConnected');
        _updatePresence(uid: uid, isOnline: isConnected, onSuccess: onSuccess);
      });
    } catch (e) {
      onError?.call(e);
    }
  }

  void _updatePresence({
    required String uid,
    required bool isOnline,
    Function? onSuccess,
    Function? onError,
  }) {
    updatePresence(
      uid: uid,
      isOnline: isOnline,
      onSuccess: () {
        debugPrint('ConnectivityHandler: onSuccess triggered');
        onSuccess?.call();
      },
      onError: (error) {
        debugPrint('ConnectivityHandler: onError: $error');
        onError?.call(error);
      },
    );
  }

  @override
  void dispose() {
    _hasConnectionController.close();
    _hasConnectionStreamSubscription?.cancel();
    _connectivitySubscription?.cancel();
  }

  @override
  Future<void> connect({
    required String uid,
    Function(bool)? onSuccess,
    Function? onError,
  }) async {
    if (_isInitialized) {
      bool isConnected = await _checkConnection();
      _hasConnectionController.add(isConnected);
    } else {
      _init();
    }

    _listenToConnectionChanges(uid: uid, onSuccess: onSuccess, onError: onError);
  }

  @override
  void forceDisconnect({
    required String uid,
    Function? onSuccess,
    Function? onError,
  }) {
    _updatePresence(
      uid: uid,
      isOnline: false,
      onSuccess: () {
        debugPrint('ConnectivityHandler: User forcibly disconnected');
        _isInitialized = false;
        _connectivitySubscription?.cancel(); // Stop listening to connectivity changes
        onSuccess?.call();
      },
      onError: onError,
    );
  }
}
