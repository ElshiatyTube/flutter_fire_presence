import 'firebase_db_ds.dart';

abstract class IFirePresenceHandler extends FirebaseDatabaseDataSource{
  Stream<bool> get hasConnectionStream;
  void dispose();
  void connect({required String uid, Function(bool)? onSuccess,Function? onError});
  void forceDisconnect({required String uid,Function? onSuccess,Function? onError});
}
