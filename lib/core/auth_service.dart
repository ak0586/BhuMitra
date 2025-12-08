import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance, GoogleSignIn(scopes: ['email']));
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthService(this._auth, this._googleSignIn);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Handle the specific PigeonUserDetails error
      if (e.toString().contains('PigeonUserDetails')) {
        if (_auth.currentUser != null) {
          return _auth.currentUser;
        }
      }
      rethrow;
    }
  }

  // Register with email and password
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      if (credential.user != null) {
        print('Creating Firestore document for user: ${credential.user!.uid}');
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(credential.user!.uid)
              .set({
                'email': email,
                'name': 'Farmer', // Default name
                'phone': '',
                'location': '',
                'createdAt': FieldValue.serverTimestamp(),
              });
          print('Firestore document created successfully');
        } catch (firestoreError) {
          print('FIRESTORE ERROR: $firestoreError');
          print('Error type: ${firestoreError.runtimeType}');
          // Don't throw - allow registration to complete
        }
      }

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Handle the specific PigeonUserDetails error
      if (e.toString().contains('PigeonUserDetails')) {
        if (_auth.currentUser != null) {
          // Try to create document even if error occurs
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(_auth.currentUser!.uid)
                .set({
                  'email': email,
                  'name': 'Farmer',
                  'phone': '',
                  'location': '',
                  'createdAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
          } catch (_) {}

          return _auth.currentUser;
        }
      }
      rethrow;
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-In aborted');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Create or update user document in Firestore
      if (userCredential.user != null) {
        print(
          'Updating Firestore for Google user: ${userCredential.user!.uid}',
        );
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
                'email': userCredential.user!.email,
                'name': userCredential.user!.displayName ?? 'Farmer',
                'lastLogin': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
          print('Google user Firestore update successful');
        } catch (firestoreError) {
          print('FIRESTORE ERROR (Google): $firestoreError');
          print('Error type: ${firestoreError.runtimeType}');
          // Don't throw - allow sign-in to complete
        }
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Handle the specific PigeonUserDetails error
      if (e.toString().contains('PigeonUserDetails')) {
        if (_auth.currentUser != null) {
          // Try to update document even if error occurs
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(_auth.currentUser!.uid)
                .set({
                  'email': _auth.currentUser!.email,
                  'name': _auth.currentUser!.displayName ?? 'Farmer',
                  'lastLogin': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
          } catch (_) {}

          return _auth.currentUser;
        }
      }
      if (e.toString().contains('Google Sign-In aborted')) {
        rethrow;
      }
      throw Exception('Google Sign-In failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  String _handleAuthException(FirebaseAuthException e) {
    final msg = e.message?.toLowerCase() ?? "";

    // Treat config error as user-not-found
    final isConfigNotFound =
        msg.contains("configuration") ||
        msg.contains("config") ||
        msg.contains("configuration_not_found");

    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';

      case 'wrong-password':
        return 'Wrong password provided.';

      case 'email-already-in-use':
        return 'The account already exists for this email.';

      case 'weak-password':
        return 'The password provided is too weak.';

      case 'invalid-email':
        return 'The email address is not valid.';

      case 'invalid-credential':
        return 'No user found for that email.';

      case 'internal-error':
      case 'configuration-not-found':
        if (isConfigNotFound) {
          return 'Configuration Error';
        }
        return 'An internal error occurred. Please try again.';

      default:
        return 'An error occurred: ${e.message}';
    }
  }
}
