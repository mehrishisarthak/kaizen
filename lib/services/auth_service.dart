import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// A service class to handle all Firebase Authentication logic.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream to listen for authentication state changes.
  /// This will be used by the AuthWrapper to navigate users.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get the current user, if any.
  User? get currentUser => _auth.currentUser;

  /// Sign up a new user with email/password and send a verification email.
  Future<String> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty && username.isNotEmpty) {
        // Create the user in Firebase Auth
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );

        // Update the Auth user's profile display name
        await cred.user?.updateDisplayName(username.trim());

        // Send the verification email
        await cred.user?.sendEmailVerification();

        // Default profile image (from your example)
        String defaultImage =
            "https://firebasestorage.googleapis.com/v0/b/kartsy-3ff24.firebasestorage.app/o/assets%2Fdefault_profile.png?alt=media&token=2038c7c3-dd79-41f1-b5bd-30e39e76af5d";

        // Store additional user details in Firestore
        await _firestore.collection('users').doc(cred.user!.uid).set({
          'Name': username.trim(),
          'Email': email.trim(),
          'Id': cred.user!.uid, // Use Firebase UID
          'Image': defaultImage,
        });

        res =
            "Success: Account created! Please check your email to verify your account.";
      } else {
        res = "Error: Please fill in all the fields.";
      }
    } on FirebaseAuthException catch (err) {
      switch (err.code) {
        case 'weak-password':
          res = "Error: The password provided is too weak.";
          break;
        case 'email-already-in-use':
          res = "Error: An account with this email already exists.";
          break;
        case 'invalid-email':
          res = "Error: The email address is invalid.";
          break;
        default:
          res =
              err.message ?? "Error: An unexpected authentication error occurred.";
      }
    } catch (e) {
      res = "Error: Something went wrong. Please try again.";
    }
    return res;
  }

  /// Sign in an existing user with email/password and check for email verification.
  Future<String> signInWithEmail({
    required String email,
    required String password,
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        // Sign in the user
        UserCredential cred = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );

        // Check if the user's email is verified
        if (cred.user != null && cred.user!.emailVerified) {
          res = "Success: Logged in successfully.";
        } else {
          // If not verified, sign them out for security and inform them
          await _auth.signOut();
          res =
              "Error: Please verify your email before logging in. Check your inbox.";
        }
      } else {
        res = "Error: Please fill in all the fields.";
      }
    } on FirebaseAuthException catch (err) {
      switch (err.code) {
        case 'user-not-found':
        case 'invalid-credential': // More common error code now
          res = "Error: Incorrect email or password.";
          break;
        case 'wrong-password':
          res = "Error: Incorrect password.";
          break;
        case 'invalid-email':
          res = "Error: The email address is invalid.";
          break;
        case 'user-disabled':
          res = "Error: This user account has been disabled.";
          break;
        case 'too-many-requests':
          res = "Error: Too many failed attempts. Try again later.";
          break;
        default:
          res = err.message ?? "Error: An unexpected authentication error occurred.";
      }
    } catch (e) {
      res = "Error: Something went wrong. Please try again.";
    }
    return res;
  }

  /// Sign in or sign up a user with their Google account.
  Future<String> signInWithGoogle() async {
    String res = "Some error occurred";
    try {
      // Trigger the Google authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        return "Error: Google Sign-In cancelled.";
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new Firebase credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // Check if this is a new user by looking for their document in Firestore
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        // If the user is signing in for the first time, create their profile
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'Name': user.displayName ?? 'No Name Provided',
            'Email': user.email ?? 'No Email Provided',
            'Id': user.uid, // Use the Firebase UID as the primary ID
            'Image': user.photoURL ??
                "https://firebasestorage.googleapis.com/v0/b/kartsy-3ff24.firebasestorage.app/o/assets%2Fdefault_profile.png?alt=media&token=2038c7c3-dd79-41f1-b5bd-30e39e76af5d",
          });
        }
        res = "Success: Logged in successfully.";
      }
    } on FirebaseAuthException catch (e) {
      res = e.message ?? "Error: An unexpected authentication error occurred.";
    } catch (e) {
      res = "Error: Something went wrong. Please try again.";
    }
    return res;
  }

  /// Sign out the current user from Firebase and Google.
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}