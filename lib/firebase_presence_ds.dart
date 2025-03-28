import 'package:firebase_database/firebase_database.dart';

abstract class FirebasePresenceDataSource {
  final DatabaseReference _presenceRef =
      FirebaseDatabase.instance.ref().child('presence');

  final Map<String, dynamic> _onlineStatus = {
    'online': true,
    'lastOnline': ServerValue.timestamp,
  };

  final Map<String, dynamic> _offlineStatus = {
    'online': false,
    'lastOnline': ServerValue.timestamp,
  };

  /// Updates the user's presence status and sets an `onDisconnect` behavior.
  Future<void> updatePresence(
      {required String uid,
      required bool isOnline,
      Function? onSuccess,
      Function? onError}) async {
    final userRef = _presenceRef.child(uid);
    try {
      if (isOnline) {
        // Ensure previous `onDisconnect` is canceled in case of reconnection
        await userRef.onDisconnect().cancel();
        // Set new `onDisconnect` behavior
        await userRef.onDisconnect().update(_offlineStatus);
      }
      onSuccess?.call();

      // Update the presence status in real-time
      await userRef.update(isOnline ? _onlineStatus : _offlineStatus);
    } catch (e) {
      onError?.call(e);
    }
  }

  /// Listens for changes in presence for a specific user (If needed)
  Stream<DatabaseEvent> presenceStream(String uid) {
    return _presenceRef.child(uid).onValue;
  }
}
