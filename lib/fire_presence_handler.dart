import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'i_fire_presence_handler.dart';

/// A handler for managing the presence of a user based on connectivity status.
class FirePresenceHandler extends IFirePresenceHandler {
  FirePresenceHandler._();

  /// Singleton instance of [FirePresenceHandler].
  static final FirePresenceHandler _singleton = FirePresenceHandler._();

  /// Factory constructor to return the singleton instance.
  factory FirePresenceHandler() => _singleton;

  /// Stream controller to broadcast connectivity status changes.
  final _hasConnectionController = StreamController<bool>.broadcast();
  StreamSubscription<bool>? _hasConnectionStreamSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isInitialized = false;

  /// Initializes the connectivity listener.
  void _init() {
    if (_isInitialized) return;

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((event) {
      bool isConnected = !event.any((element) => element == ConnectivityResult.none);
      _hasConnectionController.add(isConnected);
    });

    _isInitialized = true;
    print('FirePresenceHandler: Initialized.');
  }

  /// Stream of connectivity status changes.
  @override
  Stream<bool> get hasConnectionStream => _hasConnectionController.stream;

  /// Checks the current connectivity status.
  Future<bool> _checkConnection() async {
    List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.any((element) => element == ConnectivityResult.none);
  }

  /// Listens to connectivity changes and updates user presence.
  ///
  /// \param uid The user ID.
  /// \param onSuccess Callback function to be called on success.
  /// \param onError Callback function to be called on error.
  void _listenToConnectionChanges({
    required String uid,
    Function(bool)? onSuccess,
    Function? onError,
  }) {
    _hasConnectionStreamSubscription?.cancel();
    try {
      _hasConnectionStreamSubscription = hasConnectionStream.listen((isConnected) {
        print('ConnectivityHandler: User is online: $isConnected');
        _updatePresence(uid: uid, isOnline: isConnected, onSuccess: onSuccess);
      });
    } catch (e) {
      onError?.call(e);
    }
  }

  /// Updates the presence status of the user.
  ///
  /// \param uid The user ID.
  /// \param isOnline The online status of the user.
  /// \param onSuccess Callback function to be called on success.
  /// \param onError Callback function to be called on error.
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
        print('ConnectivityHandler: onSuccess triggered');
        onSuccess?.call();
      },
      onError: (error) {
        print('ConnectivityHandler: onError: $error');
        onError?.call(error);
      },
    );
  }

  /// Disposes the resources used by the handler.
  @override
  void dispose() {
    _hasConnectionController.close();
    _hasConnectionStreamSubscription?.cancel();
    _connectivitySubscription?.cancel();
  }

  /// Connects the user and starts listening to connectivity changes.
  ///
  /// \param uid The user ID.
  /// \param onSuccess Callback function to be called on success.
  /// \param onError Callback function to be called on error.
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

  /// Forces the user to disconnect and stops listening to connectivity changes.
  ///
  /// \param uid The user ID.
  /// \param onSuccess Callback function to be called on success.
  /// \param onError Callback function to be called on error.
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
        print('ConnectivityHandler: User forcibly disconnected');
        _isInitialized = false;
        _connectivitySubscription?.cancel(); // Stop listening to connectivity changes
        onSuccess?.call();
      },
      onError: onError,
    );
  }
}