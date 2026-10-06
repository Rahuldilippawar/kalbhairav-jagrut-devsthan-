import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Uploads a devotee's profile photo to `users/{uid}/profile.jpg`
/// (owner-only per storage.rules) and returns its download URL.
abstract class PhotoUploader {
  bool get enabled;
  Future<String> uploadProfilePhoto(String uid, Uint8List jpeg);
}

class FirebasePhotoUploader implements PhotoUploader {
  @override
  bool get enabled => true;

  @override
  Future<String> uploadProfilePhoto(String uid, Uint8List jpeg) async {
    final ref = FirebaseStorage.instance.ref('users/$uid/profile.jpg');
    await ref.putData(jpeg, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }
}

class DisabledPhotoUploader implements PhotoUploader {
  @override
  bool get enabled => false;

  @override
  Future<String> uploadProfilePhoto(String uid, Uint8List jpeg) =>
      throw UnsupportedError('Photo upload needs Firebase Storage');
}
