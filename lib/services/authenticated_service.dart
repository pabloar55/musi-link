import 'package:firebase_auth/firebase_auth.dart';

mixin AuthenticatedService {
  FirebaseAuth get auth;

  String get currentUid {
    final uid = auth.currentUser?.uid;
    if (uid == null) throw StateError('$runtimeType: no authenticated user.');
    return uid;
  }
}
