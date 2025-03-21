import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'i_connectivity.dart';

class FirePresenceHandler extends IFirePresenceHandler {
  FirePresenceHandler._();

  static final FirePresenceHandler _singleton = FirePresenceHandler._();

  factory FirePresenceHandler() => _singleton;

  final StreamController<bool> _hasConnectionController =
  StreamController<bool>.broadcast();

  StreamSubscription<bool>? _hasConnectionStreamSubscription;
  bool _isInitialized = false;

  Future<void> _init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    _hasConnectionController.add(await _checkConnection());

    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> event) {
      bool isConnected =
      !event.any((element) => element == ConnectivityResult.none);
      _hasConnectionController.add(isConnected);
    });

    debugPrint('FirePresenceHandler: Initialized.');
  }
  @override
  Stream<bool> get hasConnectionStream => _hasConnectionController.stream;

  Future<bool> _checkConnection() async {
    List<ConnectivityResult> connectivityResult =
    await Connectivity().checkConnectivity();
    return !connectivityResult
        .any((element) => element == ConnectivityResult.none);
  }

  void _listenToConnectionChanges(
      {required String uid, Function? onDisconnect,Function? onError}) {
    _hasConnectionStreamSubscription?.cancel(); // Prevent multiple listeners
    try{
      _hasConnectionStreamSubscription = hasConnectionStream.listen((isConnected) {
        debugPrint('ConnectivityHandler: User is online: $isConnected');
        _updatePresence(
            uid: uid, isOnline: isConnected, onSuccess: onDisconnect);
      });
    }catch(e){
      onError?.call(e);
    }
  }

  void _updatePresence(
      {required String uid, required bool isOnline, Function? onSuccess,Function? onError}) {
    updatePresence(
        uid: uid,
        isOnline: isOnline,
        onSuccess: () {
          debugPrint('ConnectivityHandler: onDisconnect triggered');
          onSuccess?.call();
        },
        onError: (error) {
          debugPrint('ConnectivityHandler: onDisconnectError: $error');
          onError?.call(error);
        });
  }

  @override
  void dispose() {
    _hasConnectionController.close();
    _hasConnectionStreamSubscription?.cancel();
  }

  @override
  void connect({required String uid, Function? onDisconnect,Function? onError}) {
    _init().then((_) {
      _listenToConnectionChanges(uid: uid, onDisconnect: onDisconnect,onError: onError);
    });
  }

  @override
  void forceDisconnect({required String uid, Function? onForceDisconnect,Function? onError}) {
    _updatePresence(
        uid: uid,
        isOnline: false,
        onError: onError,
        onSuccess: () {
          debugPrint('ConnectivityHandler: User forcibly disconnected');
          onForceDisconnect?.call();
        });
  }
}
