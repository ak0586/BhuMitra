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
    print('=== Login attempt for: ${email.trim()} ===');
    
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Login successful!');
      return credential.user;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: code=${e.code}, message=${e.message}');
      
      // Handle specific error codes that Firebase might return
      if (e.code == 'user-not-found') {
        print('Firebase says: user-not-found');
        throw Exception('USER_NOT_FOUND');
      }
      
      if (e.code == 'wrong-password') {
        print('Firebase says: wrong-password');
        throw Exception('WRONG_PASSWORD');
      }
      
      // For invalid-credential (most common in newer Firebase versions)
      // Since fetchSignInMethodsForEmail is unreliable, we'll use Firestore as primary check
      if (e.code == 'invalid-credential' || e.code == 'INVALID_LOGIN_CREDENTIALS') {
        print('Checking if user exists in Firestore...');
        
        try {
          // Check Firestore to see if user exists
          final querySnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email.trim())
              .limit(1)
              .get();
          
          final userExistsInFirestore = querySnapshot.docs.isNotEmpty;
          print('Firestore check: userExists=$userExistsInFirestore');
          
          if (userExistsInFirestore) {
            // User exists in Firestore, so password must be wrong
            print('User found in Firestore - WRONG_PASSWORD');
            throw Exception('WRONG_PASSWORD');
          } else {
            // User doesn't exist in Firestore
            print('User not found in Firestore - USER_NOT_FOUND');
            throw Exception('USER_NOT_FOUND');
          }
          
        } catch (e) {
          // If it's already our custom exception, rethrow it
          if (e is Exception && 
              (e.toString().contains('USER_NOT_FOUND') || 
               e.toString().contains('WRONG_PASSWORD'))) {
            print('Rethrowing custom exception: $e');
            rethrow;
          }
          
          // If Firestore check failed due to permissions or other error
          if (e.toString().contains('permission-denied')) {
            print('Firestore permission denied - assuming WRONG_PASSWORD for security');
            // For security, if we can't check Firestore, assume wrong password
            // rather than revealing whether email exists
            throw Exception('WRONG_PASSWORD');
          }
          
          // Other errors
          print('Firestore check failed with error: $e');
          throw Exception('Unable to verify credentials. Please try again.');
        }
      }
      
      // For any other Firebase error
      print('Other Firebase error, using handler');
      throw Exception(_handleAuthException(e));
      
    } catch (e) {
      print('Generic catch block: ${e.runtimeType} - $e');
      
      // Handle the specific PigeonUserDetails error
      if (e.toString().contains('PigeonUserDetails')) {
        if (_auth.currentUser != null) {
          print('PigeonUserDetails error but user is logged in');
          return _auth.currentUser;
        }
      }
      
      // Rethrow everything else (including our USER_NOT_FOUND and WRONG_PASSWORD)
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
      throw Exception(_handleAuthException(e));
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
      throw Exception(_handleAuthException(e));
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

  // Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      rethrow;
    }
  }

  // Delete Account
  Future<void> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Re-authenticate before deletion (Critical security step)
      // For Email/Password provider
      if (user.providerData.any((p) => p.providerId == 'password')) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }
      // For Google Provider, we rely on 'recent login'.
      // If 'requires-recent-login' error occurs, UI will ask user to re-login.

      // 1. Delete Firestore Data
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();
      } catch (e) {
        print('Error deleting user data: $e');
        // Continue to delete auth account even if firestore fails
      }

      // 2. Delete Auth Account
      await user.delete();
      await _googleSignIn.signOut();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'Security requires recent login. Please Sign Out and Log In again to delete your account.',
        );
      }
      throw Exception(_handleAuthException(e));
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Clear Firestore cache to free up memory
      await FirebaseFirestore.instance.clearPersistence();
    } catch (e) {
      // Ignore errors if cache clearing fails
      print('Cache clearing failed: $e');
    }
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
        // This is now handled specifically in signInWithEmail with Firestore check
        // But keeping as fallback for other methods that might encounter it
        return 'Invalid credentials. Please try again.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';

      case 'network-request-failed':
        return 'Network error. Please check your connection.';

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