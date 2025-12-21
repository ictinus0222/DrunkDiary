import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/google_auth_service.dart'; // adjust path

class LoginScreen extends StatefulWidget {  // StatefulWidget to manage _isLoading and _error state
  static const routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false; // diasbles button and shows loading indicator when true
  String? _error; //displays error text when not null

  Future<void> _handleGoogleSignIn() async { // google sign-in handler, async => (Network request and Firebase + Google popup)
    setState(() {
      _isLoading = true; // start loading and disable button
      _error = null;
    });

    try {
      await signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Something went wrong. Please try again.';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    if (!mounted || _error != null) return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to DrunkDiary 🍻',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Log drinks. Remember nights.',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 32),

            if (_error != null) ...[
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.g_mobiledata, size: 28),
                    SizedBox(width: 8),
                    Text('Continue with Google'),
                  ],
                ),
              ),

            ),
            const SizedBox(height: 16),
            const Text(
              'We don’t post anything without your permission.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),

          ],
        ),
      ),
    );
  }
}
