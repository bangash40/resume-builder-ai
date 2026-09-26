import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

String authErrorMessage(Object error) {
  // Google sign-in reports failures from the native SDK as PlatformException.
  if (error is PlatformException) {
    switch (error.code) {
      case 'network_error':
        return 'No internet connection. Please try again.';
      case 'sign_in_canceled':
        return 'Google sign-in was cancelled.';
      default:
        return 'Google sign-in failed. Please try again, or use email and '
            'password.';
    }
  }
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Please choose a stronger password (at least 6 characters).';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return error.message ?? 'Something went wrong. Please try again.';
    }
  }
  return 'Something went wrong. Please try again.';
}
