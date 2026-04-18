import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class AdminRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a bottle image to Firebase Storage and returns the download URL.
  Future<String> uploadBottleImage(File image, String fileName) async {
    final ref = _storage.ref().child('bottles').child(fileName);
    final uploadTask = await ref.putFile(image);
    return await uploadTask.ref.getDownloadURL();
  }
}
