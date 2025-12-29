import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: [
    'email',
  ],
);

Future<void> signInWithGoogle() async {
  //  Trigger Google sign-in
  final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

  if (googleUser == null) {
    // User cancelled the sign-in
    return;
  }

  //  Get auth details
  final GoogleSignInAuthentication googleAuth =
  await googleUser.authentication;

  // Create Firebase credential
  final String? idToken = googleAuth.idToken;

  if (idToken == null) {
    throw Exception("Missing Google ID Token");
  }
  //  Create Firebase credential (NO accessToken)
  final OAuthCredential credential =
  GoogleAuthProvider.credential(
    idToken: idToken,
  );
  // 4. Sign in to Firebase
  final UserCredential userCredential =
  await FirebaseAuth.instance.signInWithCredential(credential);

  final user = userCredential.user;
  if (user == null) {
    throw Exception("Google sign-in failed");
  }

  // 5. Check Firestore user document
  final userDoc =
  FirebaseFirestore.instance.collection('users').doc(user.uid);

  final docSnapshot = await userDoc.get();

  // 6. Create user document (first login only)
  if (!docSnapshot.exists) {
    await userDoc.set({
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'onboardingCompleted': false,
      'dateOfBirth': null,
      'authProvider': 'google',
    });
  }
}
