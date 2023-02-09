import 'package:cache/cache.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:meta/meta.dart';
import 'models/user.dart' as user_model;

/// {@template authentication_repository}
/// The AuthenticationRepository is responsible for abstracting the underlying implementation of how a user is authenticated, as well as how a user is fetched.
/// {@endtemplate}
class SignUpWithEmailAndPasswordFailure implements Exception {
  const SignUpWithEmailAndPasswordFailure([
    this.message =
    'An unknown exception ocurred while signing up with email and password',
  ]);

  factory SignUpWithEmailAndPasswordFailure.fromCode(String code) {
    switch (code) {
      case 'invalid-email':
        return const SignUpWithEmailAndPasswordFailure(
          'The email address is badly formatted',
        );
      case 'user-disabled':
        return const SignUpWithEmailAndPasswordFailure(
          'The user has been disabled. Please contact support for help',
        );
      case 'email-already-in-use':
        return const SignUpWithEmailAndPasswordFailure(
          'The email address is already in use by another account',
        );
      case 'operation-not-allowed':
        return const SignUpWithEmailAndPasswordFailure(
          'Email and password accounts are not enabled. Please contact support for help',
        );
      case 'weak-password':
        return const SignUpWithEmailAndPasswordFailure(
          'The password is not strong enough',
        );
      default:
        return const SignUpWithEmailAndPasswordFailure();
    }
  }

  final String message;
}

class LoginInWithEmailAndPasswordFailure implements Exception {
  const LoginInWithEmailAndPasswordFailure([
    this.message = 'An unknown exception ocurred',
  ]);

  factory LoginInWithEmailAndPasswordFailure.fromCode(String code) {
    switch (code) {
      case 'invalid-email':
        return const LoginInWithEmailAndPasswordFailure(
          'Email is not valid or  badly formatted',
        );
      case 'user-disabled':
        return const LoginInWithEmailAndPasswordFailure(
          'This user has been disabled. Please contact support for help',
        );
      case 'user-not-found':
        return const LoginInWithEmailAndPasswordFailure(
          'No user found for this email',
        );
      case 'wrong-password':
        return const LoginInWithEmailAndPasswordFailure(
          'Wrong password provided for this user',
        );
      default:
        return const LoginInWithEmailAndPasswordFailure();
    }
  }

  final String message;
}


class LogInWithGoogleFailure implements Exception {
  const LogInWithGoogleFailure([
    this.message = 'An unknown exception ocurred',
  ]);

  factory LogInWithGoogleFailure.fromCode(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return const LogInWithGoogleFailure(
          'An account already exists with the same email address but different sign-in credentials. Sign in using a provider associated with this email address.',
        );
      case 'invalid-credential':
        return const LogInWithGoogleFailure(
          'Error occurred while accessing credentials. Try again.',
        );
      case 'operation-not-allowed':
        return const LogInWithGoogleFailure(
          'Error occurred because account linking is not enabled. Enable account linking and try again.',
        );
      case 'invalid-verification-code':
        return const LogInWithGoogleFailure(
          'The verification code is invalid.',
        );
      case 'invalid-verification-id':
        return const LogInWithGoogleFailure(
          'The verification ID is invalid.',
        );
      default:
        return const LogInWithGoogleFailure();
    }
  }


  final String message;
}

// Occurs when the logout process fails

class LogOutFailure implements Exception {}

class AuthenticationRepository {
  AuthenticationRepository({
    CacheClient? cache,
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })
      : _cache = cache ?? CacheClient(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.standard();

  final CacheClient _cache;
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  @visibleForTesting
  bool isWeb = kIsWeb;

  @visibleForTesting
  static const userCacheKey = '__user_cache_key__';

  // Stream of [User] which will emit the current user when
  Stream<user_model.User> get user {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) {
        return user_model.User.empty;
      }
      return user_model.User(
        id: firebaseUser.uid,
        email: firebaseUser.email,
        name: firebaseUser.displayName,
        photo: firebaseUser.photoURL,
      );
    });
  }


  // Returns the current user from cache
  user_model.User get currentUser {
    return _cache.read<user_model.User>(key: userCacheKey) ??
        user_model.User.empty;
  }

  // Registers a new user with email and password
  Future<void> signUp({required String email, required String password}) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw SignUpWithEmailAndPasswordFailure.fromCode(e.code);
    } catch (_) {
      throw const SignUpWithEmailAndPasswordFailure();
    }
  }


  // Starts google sign in
  Future<void> logInWithGoogle() async {
    try {
      late final AuthCredential credential;
      if (isWeb) {
        final googleProvider = GoogleAuthProvider();
        final userCredential = await _firebaseAuth.signInWithPopup(
          googleProvider,
        );
        credential = userCredential.credential!;
      } else {
        final googleUser = await _googleSignIn.signIn();
        final googleAuth = await googleUser!.authentication;
        credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
      }
      await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw LoginInWithEmailAndPasswordFailure.fromCode(e.code);
    } catch (_) {
      throw const LoginInWithEmailAndPasswordFailure();
    }
  }


  // Signs in with email and password
  Future<void> logInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password,);
    } on FirebaseAuthException catch (e) {
      throw LoginInWithEmailAndPasswordFailure.fromCode(e.code);
    } catch (_) {
      throw const LoginInWithEmailAndPasswordFailure();
    }
  }

  /// Signs out the current user which will emit
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