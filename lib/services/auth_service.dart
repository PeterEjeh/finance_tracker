import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream that emits current user status
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is currently signed in
  bool get isUserSignedIn => _auth.currentUser != null;

  // Sign in with email and password
  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found with this email address.');
        case 'wrong-password':
          throw Exception('Invalid password. Please check and try again.');
        case 'invalid-email':
          throw Exception('Invalid email format.');
        case 'user-disabled':
          throw Exception('This account has been disabled.');
        case 'too-many-requests':
          throw Exception('Too many failed attempts. Please try again later.');
        default:
          throw Exception('Sign in failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Sign in failed');
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUp(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          throw Exception('Password is too weak.');
        case 'email-already-in-use':
          throw Exception('An account already exists with this email.');
        case 'invalid-email':
          throw Exception('Invalid email format.');
        case 'operation-not-allowed':
          throw Exception('Email/password accounts are not enabled.');
        default:
          throw Exception('Sign up failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Sign up failed');
    }
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw Exception(
            'Account already exists with a different sign-in method.',
          );
        case 'invalid-credential':
          throw Exception('Invalid Google credentials.');
        case 'operation-not-allowed':
          throw Exception('Google sign-in is not enabled.');
        case 'user-disabled':
          throw Exception('This account has been disabled.');
        case 'user-not-found':
          throw Exception('User not found.');
        case 'wrong-password':
          throw Exception('Invalid credentials.');
        default:
          throw Exception('Google sign-in failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Google sign-in failed');
    }
  }

  // Send email verification for current user
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw Exception('Failed to send email verification');
    }
  }

  // Send email verification for signup (without account creation)
  Future<void> sendEmailVerificationForSignup(String email) async {
    try {
      // Create a temporary account, send verification, then delete it
      // This is not ideal but Firebase doesn't support sending verification emails without an account
      final tempPassword =
          'temp_signup_' + DateTime.now().millisecondsSinceEpoch.toString();

      // Try to create the account
      try {
        await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: tempPassword,
        );

        // Send verification email
        await sendEmailVerification();
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          // Account already exists, this means they've signed up before
          // Sign in temporarily and resend verification
          try {
            await _auth.signInWithEmailAndPassword(
              email: email.trim(),
              password: tempPassword, // Won't work if real password exists
            );
            // If we get here, they used a temp password - sending verification
            await sendEmailVerification();
          } catch (signinError) {
            // Password doesn't match temp - this is a real existing account
            throw Exception(
              'An account with this email already exists. Please sign in instead.',
            );
          }
        } else {
          throw e;
        }
      }
    } catch (e) {
      if (e.toString().contains('An account with this email already exists')) {
        throw e; // Re-throw our custom error
      }
      throw Exception('Failed to send verification email');
    }
  }

  // Check if email is already registered
  Future<bool> checkEmailExists(String email) async {
    try {
      // Try to create a user with a temporary password to check if email exists
      // If it succeeds, the user doesn't exist, so we delete the user immediately
      // If it fails with email-already-in-use, the email exists
      final tempPassword =
          'temp_check_' + DateTime.now().millisecondsSinceEpoch.toString();

      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: tempPassword,
      );

      // If we get here, the user was created, so email didn't exist
      // We need to delete this temporary user
      await _auth.currentUser?.delete();
      return false;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // Email already exists
        return true;
      }
      // For other errors (network, invalid email, etc.), assume email doesn't exist
      return false;
    } catch (e) {
      return false;
    }
  }

  // Resend email verification
  Future<void> resendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw Exception('Failed to resend verification email');
    }
  }

  // Set password for current user (after email verification in signup flow)
  Future<void> setPasswordForCurrentUser(String password) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(password);
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      throw Exception('Failed to set password');
    }
  }

  // Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          throw Exception('Invalid email format.');
        case 'user-not-found':
          throw Exception('No account found with this email address.');
        default:
          throw Exception('Password reset failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Password reset failed');
    }
  }

  // Verify password reset code (for mobile apps)
  Future<void> verifyPasswordResetCode(String code) async {
    try {
      await _auth.verifyPasswordResetCode(code);
    } catch (e) {
      throw Exception('Invalid password reset code');
    }
  }

  // Confirm password reset
  Future<void> confirmPasswordReset(String code, String newPassword) async {
    try {
      await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
    } catch (e) {
      throw Exception('Failed to reset password');
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          throw Exception('New password is too weak.');
        case 'requires-recent-login':
          throw Exception('Please re-authenticate to update your password.');
        default:
          throw Exception('Password update failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Password update failed');
    }
  }

  // Update email
  Future<void> updateEmail(String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await user.verifyBeforeUpdateEmail(newEmail.trim());
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          throw Exception('Invalid email format.');
        case 'email-already-in-use':
          throw Exception('Email is already in use.');
        case 'requires-recent-login':
          throw Exception('Please re-authenticate to update your email.');
        default:
          throw Exception('Email update failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Email update failed');
    }
  }

  // Re-authenticate user
  Future<void> reauthenticate(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No user or email available');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          throw Exception('Invalid password.');
        case 'user-not-found':
          throw Exception('User not found.');
        case 'invalid-credential':
          throw Exception('Invalid credentials.');
        default:
          throw Exception('Re-authentication failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Re-authentication failed');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await user.delete();
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'requires-recent-login':
          throw Exception('Please re-authenticate to delete your account.');
        default:
          throw Exception('Account deletion failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Account deletion failed');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed');
    }
  }

  // Get user ID token (useful for backend authentication)
  Future<String?> getIdToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      return await user.getIdToken();
    } catch (e) {
      return null;
    }
  }

  // Check if email is verified
  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Reload user data
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      throw Exception('Failed to reload user data');
    }
  }

  // Get user display name
  String? getUserDisplayName() {
    return _auth.currentUser?.displayName;
  }

  // Get user email
  String? getUserEmail() {
    return _auth.currentUser?.email;
  }

  // Get user photo URL
  String? getUserPhotoUrl() {
    return _auth.currentUser?.photoURL;
  }

  // Update user profile
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoUrl);
    } catch (e) {
      throw Exception('Profile update failed');
    }
  }

  // Legacy methods for backward compatibility (these would need dynamic links or alternative implementation)
  // These are deprecated and kept for transition purposes

  @Deprecated(
    'Dynamic links are no longer supported. Use sendEmailVerification instead.',
  )
  Future<void> sendSignInLinkToEmail({
    required String email,
    required ActionCodeSettings actionCodeSettings,
  }) async {
    // This would throw an error as dynamic links are deprecated
    throw UnsupportedError(
      'Dynamic links are no longer supported. Email link sign-in has been replaced with email verification flow.',
    );
  }

  @Deprecated('Dynamic links are no longer supported.')
  Future<void> completeEmailLinkSignIn({
    required String email,
    required String emailLink,
  }) async {
    throw UnsupportedError(
      'Dynamic links are no longer supported. Use email verification flow with sendEmailVerification and reloadUser.',
    );
  }
}
