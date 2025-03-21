import 'firebase_db_ds.dart';

abstract class IConnectivity extends FirebaseDatabaseDataSource{
  Stream<bool> get hasConnectionStream;
  void dispose();
  void connect({required String uid,Function? onDisconnect});
  void forceDisconnect({required String uid});
}
