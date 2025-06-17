import 'dart:async';

import 'package:flutter/services.dart';
import 'package:ready_or_not/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

/// {@template log_in_with_google_failure}
/// Thrown during the sign in with google process if a failure occurs.
/// https://pub.dev/documentation/firebase_auth/latest/firebase_auth/FirebaseAuth/signInWithCredential.html
/// {@endtemplate}
class LogInWithGoogleFailure implements Exception {
  /// {@macro log_in_with_google_failure}
  const LogInWithGoogleFailure([
    this.message = 'An unknown exception occurred.',
  ]);

  /// Create an authentication message
  /// from a firebase authentication exception code.
  factory LogInWithGoogleFailure.fromCode(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return const LogInWithGoogleFailure(
          'Account exists with different credentials.',
        );
      case 'invalid-credential':
        return const LogInWithGoogleFailure(
          'The credential received is malformed or has expired.',
        );
      case 'operation-not-allowed':
        return const LogInWithGoogleFailure(
          'Operation is not allowed.  Please contact support.',
        );
      case 'user-disabled':
        return const LogInWithGoogleFailure(
          'This user has been disabled. Please contact support for help.',
        );
      case 'user-not-found':
        return const LogInWithGoogleFailure(
          'Email is not found, please create an account.',
        );
      case 'wrong-password':
        return const LogInWithGoogleFailure(
          'Incorrect password, please try again.',
        );
      case 'invalid-verification-code':
        return const LogInWithGoogleFailure(
          'The credential verification code received is invalid.',
        );
      case 'invalid-verification-id':
        return const LogInWithGoogleFailure(
          'The credential verification ID received is invalid.',
        );
      default:
        return const LogInWithGoogleFailure();
    }
  }

  /// The associated error message.
  final String message;
}

/// {@template log_in_with_apple_failure}
/// Thrown during the sign in with apple process if a failure occurs.
/// {@endtemplate}
class LogInWithAppleFailure implements Exception {
  /// {@macro log_in_with_google_failure}
  const LogInWithAppleFailure([
    this.message = 'An unknown exception occurred.',
  ]);

  /// Create an authentication message
  /// from a firebase authentication exception code.
  factory LogInWithAppleFailure.fromCode(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return const LogInWithAppleFailure(
          'Account exists with different credentials.',
        );
      case 'invalid-credential':
        return const LogInWithAppleFailure(
          'The credential received is malformed or has expired.',
        );
      case 'operation-not-allowed':
        return const LogInWithAppleFailure(
          'Operation is not allowed.  Please contact support.',
        );
      case 'user-disabled':
        return const LogInWithAppleFailure(
          'This user has been disabled. Please contact support for help.',
        );
      case 'user-not-found':
        return const LogInWithAppleFailure(
          'Email is not found, please create an account.',
        );
      case 'wrong-password':
        return const LogInWithAppleFailure(
          'Incorrect password, please try again.',
        );
      case 'invalid-verification-code':
        return const LogInWithAppleFailure(
          'The credential verification code received is invalid.',
        );
      case 'invalid-verification-id':
        return const LogInWithAppleFailure(
          'The credential verification ID received is invalid.',
        );
      default:
        return const LogInWithAppleFailure();
    }
  }

  /// The associated error message.
  final String message;
}

/// {@template continue_as_guest_failure}
/// Thrown during the continue as guest process if a failure occurs.
/// {@endtemplate}
class ContinueAsGuestFailure implements Exception {
  /// {@macro continue_as_guest_failure}
  const ContinueAsGuestFailure([
    this.message = 'An unknown exception occurred.',
  ]);

  /// Create an authentication message
  /// from a firebase authentication exception code.
  factory ContinueAsGuestFailure.fromCode(String code) {
    switch (code) {
      case 'operation-not-allowed':
        return const ContinueAsGuestFailure(
          'Operation is not allowed.  Please contact support.',
        );
      default:
        return const ContinueAsGuestFailure();
    }
  }

  /// The associated error message.
  final String message;
}

/// Thrown during the logout process if a failure occurs.
class LogOutFailure implements Exception {}

/// {@template authentication_repository}
/// Repository which manages user authentication.
/// {@endtemplate}
class AuthenticationRepository {
  /// {@macro authentication_repository}
  AuthenticationRepository._privateConstructor({
    firebase_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.standard();

  static final AuthenticationRepository instance = AuthenticationRepository._privateConstructor();

  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  /// Stream of [User] which will emit the current user when
  /// the authentication state changes.
  ///
  /// Emits [User.empty] if the user is not authenticated.
  Stream<User> get user {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      final user = firebaseUser == null ? User.empty : firebaseUser.toUser;
      return user;
    });
  }

  /// Returns the current cached user.
  /// Defaults to [User.empty] if there is no cached user.
  User get currentUser {
    final user = _firebaseAuth.currentUser;
    return user == null ? User.empty : user.toUser;
  }

  /// Starts the Sign In with Google Flow.
  ///
  /// Throws a [LogInWithGoogleFailure] if an exception occurs.
  Future<void> logInWithGoogle() async {
    try {
      late final firebase_auth.AuthCredential credential;
      
      final googleUser = await _googleSignIn.signIn();
      final googleAuth = await googleUser!.authentication;
      credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _firebaseAuth.signInWithCredential(credential);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw LogInWithGoogleFailure.fromCode(e.code);
    } on PlatformException catch (e) {
      throw const LogInWithGoogleFailure();
    } catch (e) {
      // User cancelled the sign in, do nothing.
    }
  }

  /// Starts the Sign In with Apple Flow.
  ///
  /// Throws a [LogInWithAppleFailure] if an exception occurs.
  Future<void> logInWithApple() async {
    try {
      final appleProvider = firebase_auth.AppleAuthProvider();
      await _firebaseAuth.signInWithProvider(appleProvider);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw LogInWithAppleFailure.fromCode(e.code);
    } catch (_) {
      throw const LogInWithAppleFailure();
    }
  }

  /// Starts the Continue as Guest Flow.
  ///
  /// Throws a [ContinueAsGuestFailure] if an exception occurs.
  Future<void> logInAsGuest() async {
    try {
      await _firebaseAuth.signInAnonymously();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ContinueAsGuestFailure.fromCode(e.code);
    } catch (_) {
      throw const ContinueAsGuestFailure();
    }
  }

  /// Signs out the current user which will emit
  /// [User.empty] from the [user] Stream.
  ///
  /// Throws a [LogOutFailure] if an exception occurs.
  Future<void> logOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (_) {
      throw LogOutFailure();
    }
  }
}

extension on firebase_auth.User {
  /// Maps a [firebase_auth.User] into a [User].
  User get toUser {
    late final UserType userType;
    if (providerData.isNotEmpty) {
      final provider = providerData.first.providerId;
      if (provider == 'google.com') {
        userType = UserType.google;
      } else if (provider == 'apple.com') {
        userType = UserType.apple;
      } else {
        userType = UserType.guest;
      }
    } else {
      userType = UserType.guest;
    }

    return User(id: uid, type: userType, email: email, name: displayName, photo: photoURL);
  }
}