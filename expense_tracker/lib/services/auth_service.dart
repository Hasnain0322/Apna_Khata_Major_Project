import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:expense_tracker/services/firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();

  Stream<User?> get user => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        await _firestoreService.createUserProfile(user);
      }
      return user;
    } catch (e) {
      print('Google Sign-In failed: $e');
      return null;
    }
  }

  Future<User?> registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password.trim());
      final user = result.user;
      if (user != null) {
        await _firestoreService.createUserProfile(user);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      print('Registration failed: ${e.message}');
      return null;
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password.trim());
      final user = result.user;
      if (user != null) {
        await _firestoreService.createUserProfile(user);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      print('Sign in failed: ${e.message}');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<bool> sendPasswordResetEmail() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return false;
    try {
      await _auth.sendPasswordResetEmail(email: user.email!);
      return true;
    } catch (e) {
      print('Error sending password reset email: $e');
      return false;
    }
  }

  Future<bool> deleteUserAccount() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await user.delete();
      return true;
    } on FirebaseAuthException catch (e) {
      print('Error deleting user account: ${e.code} - ${e.message}');
      return false;
    }
  }
}