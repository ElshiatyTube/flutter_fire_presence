import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'i_connectivity.dart';

class FirePresenceHandler extends IFirePresenceHandler {
  FirePresenceHandler._() {
    _init();
  }

  static final FirePresenceHandler _singleton = FirePresenceHandler._();

  factory FirePresenceHandler() => _singleton;

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
      {required String uid, Function? onDisconnect,Function? onError}) {
    _connectionStreamSubscription?.cancel(); // Prevent multiple listeners
    try{
      _connectionStreamSubscription = hasConnectionStream.listen((isConnected) {
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
    _connectivitySubscription?.cancel();
    _connectionStreamSubscription?.cancel();
  }

  @override
  void connect({required String uid, Function? onDisconnect,Function? onError}) {
    _listenToConnectionChanges(uid: uid, onDisconnect: onDisconnect,onError: onError);
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
