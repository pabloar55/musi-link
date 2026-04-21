import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:musi_link/utils/error_reporter.dart';

class StorageService {
  StorageService({required FirebaseStorage storage}) : _storage = storage;

  final FirebaseStorage _storage;

  Future<String?> uploadProfilePhoto(String uid, XFile imageFile) async {
    try {
      final ref = _storage.ref('profile_photos/$uid');
      await ref.putFile(
        File(imageFile.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await ref.getDownloadURL();
    } catch (e, st) {
      await reportError(e, st);
      rethrow;
    }
  }
}
