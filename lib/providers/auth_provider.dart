import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthUser? _user;
  ForumUser? _forumUser;
  bool _isLoading = false;

  AuthUser? get user => _user;
  ForumUser? get forumUser => _forumUser;
  bool get isLoggedIn => _user != null;
  bool get isModerator => _forumUser?.isModerator ?? false;
  bool get isLoading => _isLoading;

  final ApiService _apiService = ApiService();

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      _isLoading = true;
      notifyListeners();

      final session = await Amplify.Auth.fetchAuthSession();
      if (session.isSignedIn) {
        _user = await Amplify.Auth.getCurrentUser();
        await _loadForumUser();
      }
    } catch (e) {
      print('Error checking auth status: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadForumUser() async {
    if (_user == null) return;

    try {
      _forumUser = await _apiService.getUser(_user!.userId);
      await _updateOnlineStatus(true);
    } catch (e) {
      print('Error loading forum user: $e');
    }
  }

  Future<bool> signUp(String username, String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.email: email,
            AuthUserAttributeKey.preferredUsername: username,
          },
        ),
      );

      if (result.isSignUpComplete) {
        return await signIn(email, password);
      } else {
        // Handle email verification if needed
        return false;
      }
    } catch (e) {
      print('Sign up error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );

      if (result.isSignedIn) {
        _user = await Amplify.Auth.getCurrentUser();
        await _loadForumUser();
        return true;
      }
      return false;
    } catch (e) {
      print('Sign in error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _updateOnlineStatus(false);
      await Amplify.Auth.signOut();
      _user = null;
      _forumUser = null;
      notifyListeners();
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  Future<void> _updateOnlineStatus(bool isOnline) async {
    if (_forumUser == null) return;

    try {
      await _apiService.updateUserOnlineStatus(_forumUser!.id, isOnline);
    } catch (e) {
      print('Error updating online status: $e');
    }
  }

  String get currentUserId => _user?.userId ?? '';
  String get currentUsername => _forumUser?.username ?? 'Anonymous';
}