import 'firebase_presence_ds.dart';

abstract class IFirePresenceHandler extends FirebasePresenceDataSource{
  Stream<bool> get hasConnectionStream;
  void dispose();
  void connect({required String uid, Function(bool)? onSuccess,Function? onError});
  void forceDisconnect({required String uid,Function? onSuccess,Function? onError});
}
