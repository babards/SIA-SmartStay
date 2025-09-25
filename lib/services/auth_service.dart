import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  UserModel? _currentUserModel;
  UserModel? get currentUserModel => _currentUserModel;

  // Register new user
  Future<UserCredential?> registerUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phoneNumber,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Create user profile in Firestore
        UserModel newUser = UserModel(
          id: result.user!.uid,
          name: name,
          email: email,
          role: role,
          phoneNumber: phoneNumber,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .set(newUser.toMap());

        _currentUserModel = newUser;
        notifyListeners();
      }

      return result;
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Sign in user
  Future<UserCredential?> signInUser({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await _loadUserData(result.user!.uid);
      }

      return result;
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  // Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUserModel =
            UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user data: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUserModel = null;
    notifyListeners();
  }
}
