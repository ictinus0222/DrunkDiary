import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/analytics/analytics_service.dart';

// Note: GoogleSignIn is now a singleton (v7.0.0+)
// Initialization happens in main.dart
final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

Future<void> signInWithGoogle() async {
  try {
    // 1. Trigger Google sign-in (Authenticate)
    final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();

    if (googleUser == null) {
      // User cancelled the sign-in
      print("Google Sign-In: User cancelled");
      return;
    }

    // 2. Get auth details (Identity/idToken)
    final googleAuth = await googleUser.authentication;
    final String? idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception("Missing Google ID Token");
    }

    // 3. Get authorization (accessToken)
    // In v7.0.0+, accessToken is retrieved via the authorizationClient
    final authorization = await googleUser.authorizationClient.authorizeScopes([
      'email',
      'openid',
    ]);
    final String? accessToken = authorization.accessToken;

    if (accessToken == null) {
      throw Exception("Missing Google Access Token");
    }

    // 4. Create Firebase credential
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: accessToken,
      idToken: idToken,
    );
    // 4. Sign in to Firebase
    final UserCredential userCredential =
    await FirebaseAuth.instance.signInWithCredential(credential);

    final user = userCredential.user;
    if (user == null) {
      throw Exception("Google sign-in failed: Firebase user is null");
    }

    // 🏆 Log analytics event
    await AnalyticsService().setUserId(user.uid);
    await AnalyticsService().logLogin('google');

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
        'authProvider': 'google',
      });
    }
  } catch (e) {
    print("Google Sign-In Error: $e");
    rethrow;
  }
}
Future<void> signOutGoogle() async {
  try {
    await FirebaseAuth.instance.signOut();
    await _googleSignIn.signOut();
    print("Google Sign-Out: Successful");
  } catch (e) {
    print("Google Sign-Out Error: $e");
    rethrow;
  }
}
