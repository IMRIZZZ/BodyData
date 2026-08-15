import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/account.dart';
import '../models/profile.dart';
import '../models/weight_record.dart';
import '../services/storage_service.dart';

enum SignupRecoveryStage { none, verifyingEmail, setPassword }

class AppProvider extends ChangeNotifier {
  late StorageService _storage;

  bool _isLoading = true;
  String? _activeAccountId;
  String? _activeProfileId;
  List<Profile> _profiles = [];
  List<WeightRecord> _weightRecords = [];
  String? _errorMessage;
  bool _isMetric = true;
  bool _isDarkMode = false;
  bool _firebaseAvailable = false;

  // Set only when Google reports that the email already belongs to a
  // password account. The credential is held in memory for one linking
  // attempt and is never persisted.
  AuthCredential? _pendingGoogleCredential;
  String? _pendingGoogleEmail;

  SignupRecoveryStage _signupRecoveryStage = SignupRecoveryStage.none;
  String _signupEmail = '';
  String _signupTempPassword = '';
  DateTime? _signupStartedAt;

  static const _recoveringSignupKey = 'bd_recovering_signup';
  static const _signupEmailKey = 'bd_signup_email';
  static const _signupTempPasswordKey = 'bd_signup_temp_password';
  static const _signupTimestampKey = 'bd_signup_timestamp';
  static const _signupLifetime = Duration(minutes: 5);
  static const _darkModeKey = 'bd_dark_mode';

  bool get isLoading => _isLoading;
  String? get activeAccountId => _activeAccountId;
  String? get activeProfileId => _activeProfileId;
  List<Profile> get profiles => List.unmodifiable(_profiles);
  List<WeightRecord> get weightRecords => List.unmodifiable(_weightRecords);
  String? get errorMessage => _errorMessage;
  bool get isMetric => _isMetric;
  bool get isDarkMode => _isDarkMode;
  bool get firebaseAvailable => _firebaseAvailable;
  bool get hasPendingGoogleLink => _pendingGoogleCredential != null;
  String? get pendingGoogleEmail => _pendingGoogleEmail;
  SignupRecoveryStage get signupRecoveryStage => _signupRecoveryStage;
  bool get hasPendingSignup => _signupRecoveryStage != SignupRecoveryStage.none;
  String get signupEmail => _signupEmail;

  int get signupSecondsRemaining {
    final started = _signupStartedAt;
    if (started == null) return _signupLifetime.inSeconds;
    final remaining = _signupLifetime.inSeconds -
        DateTime.now().difference(started).inSeconds;
    return remaining.clamp(0, _signupLifetime.inSeconds);
  }

  Profile? get currentProfile {
    if (_activeProfileId == null) return null;
    for (final profile in _profiles) {
      if (profile.id == _activeProfileId) return profile;
    }
    return null;
  }

  List<WeightRecord> get recentWeightRecords {
    final today = DateTime.now();
    final cutoff = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 6));
    return _weightRecords
        .where((record) =>
            !record.dateTime.isBefore(cutoff) &&
            record.dateTime.isBefore(cutoff.add(const Duration(days: 7))))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _storage = await StorageService.create();
      _isDarkMode = _storage.prefs.getBool(_darkModeKey) ?? false;
      _firebaseAvailable = Firebase.apps.isNotEmpty;

      final recovered = await _restorePendingSignup();
      if (recovered) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (_firebaseAvailable) {
        final user = FirebaseAuth.instance.currentUser;
        _activeAccountId = user?.uid;
        if (_activeAccountId != null) {
          await _storage.setActiveAccountId(_activeAccountId);
        } else {
          _activeAccountId = _storage.getActiveAccountId();
        }
      } else {
        _activeAccountId = _storage.getActiveAccountId();
      }

      _activeProfileId = _storage.getActiveProfileId();
      if (_activeAccountId != null) {
        _profiles = _storage.getProfilesForAccount(_activeAccountId!);
        if (_activeProfileId == null ||
            !_profiles.any((profile) => profile.id == _activeProfileId)) {
          _activeProfileId = _profiles.isEmpty ? null : _profiles.first.id;
          await _storage.setActiveProfileId(_activeProfileId);
        }
        if (_activeProfileId != null) {
          _weightRecords =
              _storage.getWeightRecordsForProfile(_activeProfileId!);
        }
      } else {
        _activeProfileId = null;
        _profiles = [];
        _weightRecords = [];
      }
    } catch (_) {
      _firebaseAvailable = false;
      _activeAccountId = null;
      _activeProfileId = null;
      _profiles = [];
      _weightRecords = [];
      _errorMessage = 'Could not restore the previous session.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> _restorePendingSignup() async {
    final prefs = await _storage.prefs;
    final recovering = prefs.getBool(_recoveringSignupKey) ?? false;
    if (!recovering) return false;

    final startedValue = prefs.getString(_signupTimestampKey);
    final started =
        startedValue == null ? null : DateTime.tryParse(startedValue);
    final email = prefs.getString(_signupEmailKey);
    final tempPassword = prefs.getString(_signupTempPasswordKey);

    if (started == null || email == null || tempPassword == null) {
      await _clearSignupRecovery();
      return false;
    }
    if (DateTime.now().difference(started) >= _signupLifetime) {
      await _deletePendingFirebaseUser(email);
      await _clearSignupRecovery();
      return false;
    }
    if (!_firebaseAvailable) {
      _errorMessage = 'Pending email verification requires Firebase.';
      await _clearSignupRecovery();
      return false;
    }

    _signupEmail = email;
    _signupTempPassword = tempPassword;
    _signupStartedAt = started;

    try {
      final current = FirebaseAuth.instance.currentUser;
      if (current == null || current.email != email) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: tempPassword,
        );
      }
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      final refreshed = FirebaseAuth.instance.currentUser;
      _signupRecoveryStage = refreshed?.emailVerified == true
          ? SignupRecoveryStage.setPassword
          : SignupRecoveryStage.verifyingEmail;
      return true;
    } catch (_) {
      await _deletePendingFirebaseUser(email);
      await _clearSignupRecovery();
      return false;
    }
  }

  Future<void> setDarkMode(bool enabled) async {
    _isDarkMode = enabled;
    await _storage.prefs.setBool(_darkModeKey, enabled);
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    final normalizedEmail = email.trim();
    if (!_validateCredentials(normalizedEmail, password)) return false;

    try {
      _errorMessage = null;
      if (_firebaseAvailable) {
        final credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
                email: normalizedEmail, password: password);
        final user = credential.user;
        if (user == null) throw StateError('No Firebase user returned.');
        await user.reload();
        final refreshed = FirebaseAuth.instance.currentUser;
        if (refreshed?.emailVerified != true) {
          _errorMessage =
              'Please verify your email before signing in. You can request a new verification link by signing up again.';
          await FirebaseAuth.instance.signOut();
          notifyListeners();
          return false;
        }
        await _activateAccount(user.uid, user.email ?? normalizedEmail);
      } else {
        final account = _storage.getAccountByEmail(normalizedEmail) ??
            Account(
              id: _uid(),
              email: normalizedEmail,
              passwordHash: password,
            );
        await _storage.upsertAccount(account);
        await _activateAccount(account.id, account.email);
      }
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = _firebaseMessage(error);
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Sign-in failed. Check your details and try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> startSignup(String email, [String? fallbackPassword]) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      _errorMessage = 'Enter a valid email address.';
      notifyListeners();
      return false;
    }
    final localPassword = fallbackPassword ?? _generateTemporaryPassword();

    try {
      _errorMessage = null;
      if (!_firebaseAvailable) {
        final existing = _storage.getAccountByEmail(normalizedEmail);
        if (existing != null) {
          _errorMessage = 'An account with this email already exists.';
          notifyListeners();
          return false;
        }
        final account = Account(
          id: _uid(),
          email: normalizedEmail,
          passwordHash: localPassword,
        );
        await _storage.upsertAccount(account);
        await _activateAccount(account.id, account.email);
        notifyListeners();
        return true;
      }

      final tempPassword = _generateTemporaryPassword();
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: tempPassword,
      );
      final user = credential.user;
      if (user == null) throw StateError('No Firebase user returned.');

      _signupEmail = normalizedEmail;
      _signupTempPassword = tempPassword;
      _signupStartedAt = DateTime.now();
      await _saveSignupRecovery();
      await user.sendEmailVerification();
      _signupRecoveryStage = SignupRecoveryStage.verifyingEmail;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (error) {
      await _deletePendingFirebaseUser(normalizedEmail);
      await _clearSignupRecovery();
      _errorMessage = _firebaseMessage(error);
      notifyListeners();
      return false;
    } catch (_) {
      await _deletePendingFirebaseUser(normalizedEmail);
      await _clearSignupRecovery();
      _errorMessage = 'Sign-up failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // Compatibility alias for older BodyData callers.
  Future<bool> register(String email, String password) =>
      startSignup(email, password);

  Future<void> checkSignupVerification() async {
    if (_signupRecoveryStage != SignupRecoveryStage.verifyingEmail ||
        !_firebaseAvailable) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await user.reload();
      final refreshed = FirebaseAuth.instance.currentUser;
      if (refreshed?.emailVerified == true) {
        _signupRecoveryStage = SignupRecoveryStage.setPassword;
        notifyListeners();
      }
    } catch (_) {
      // A temporary network error is retried by the verification screen.
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
    } catch (_) {
      _errorMessage = 'Could not resend the email. Please try again.';
      notifyListeners();
    }
  }

  Future<bool> completeSignupPassword(String newPassword) async {
    if (newPassword.length < 6) {
      _errorMessage = 'Password must contain at least 6 characters.';
      notifyListeners();
      return false;
    }
    if (_signupRecoveryStage != SignupRecoveryStage.setPassword) {
      _errorMessage = 'Verify your email before setting a password.';
      notifyListeners();
      return false;
    }

    try {
      _errorMessage = null;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('Session lost. Please sign up again.');
      await user.updatePassword(newPassword);
      await _activateAccount(user.uid, user.email ?? _signupEmail);
      await _clearSignupRecovery();
      _signupRecoveryStage = SignupRecoveryStage.none;
      _signupEmail = '';
      _signupTempPassword = '';
      _signupStartedAt = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = _firebaseMessage(error);
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Could not finish account setup. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> expirePendingSignup() async {
    try {
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (_) {
      // The user may already be deleted or require reauthentication.
    }
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    await _clearSignupRecovery();
    _signupRecoveryStage = SignupRecoveryStage.none;
    _signupEmail = '';
    _signupTempPassword = '';
    _signupStartedAt = null;
    _errorMessage = 'Sign-up session expired. Please start again.';
    notifyListeners();
  }

  Future<void> cancelPendingSignup() => expirePendingSignup();

  Future<bool> loginWithGoogle() async {
    AuthCredential? googleCredential;
    String? googleEmail;
    try {
      _errorMessage = null;
      if (!_firebaseAvailable) {
        _errorMessage =
            'Google Sign-In requires Firebase configuration and an Android OAuth client.';
        notifyListeners();
        return false;
      }

      final googleUser = await GoogleSignIn(scopes: const ['email']).signIn();
      if (googleUser == null) return false;
      googleEmail = googleUser.email.trim();
      final googleAuth = await googleUser.authentication;
      googleCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result =
          await FirebaseAuth.instance.signInWithCredential(googleCredential);
      final user = result.user;
      if (user == null) throw StateError('No Google user returned.');
      _pendingGoogleCredential = null;
      _pendingGoogleEmail = null;
      await _activateAccount(user.uid, user.email ?? 'Google user');
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'account-exists-with-different-credential' &&
          googleCredential != null) {
        _pendingGoogleCredential = googleCredential;
        _pendingGoogleEmail = googleEmail;
        _errorMessage =
            'This email already has an email/password account. Enter that account password below to link Google to the same account.';
      } else {
        _errorMessage = _firebaseMessage(error);
      }
      notifyListeners();
      return false;
    } on PlatformException catch (error) {
      final details = (error.message ?? '').toLowerCase();
      if (error.code == 'sign_in_failed' &&
          (details.contains('10') || details.contains('developer_error'))) {
        _errorMessage =
            'Google Sign-In rejected this Android certificate. Add the APK signing SHA-1 and SHA-256 to the Firebase Android app, then download a fresh google-services.json.';
      } else if (error.code == 'sign_in_canceled' ||
          error.code == 'sign_in_cancelled') {
        _errorMessage = 'Google Sign-In was cancelled.';
      } else {
        _errorMessage =
            'Google Sign-In failed (${error.code}). ${error.message ?? 'Check Firebase OAuth setup.'}';
      }
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage =
          'Google Sign-In could not be completed. Check Firebase OAuth setup.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> linkPendingGoogleAccount(String email, String password) async {
    final credential = _pendingGoogleCredential;
    final normalizedEmail = email.trim();
    if (credential == null) {
      _errorMessage = 'Start Google Sign-In again to link the accounts.';
      notifyListeners();
      return false;
    }
    if (!_validateCredentials(normalizedEmail, password)) return false;

    try {
      _errorMessage = null;
      final emailResult = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: normalizedEmail, password: password);
      final user = emailResult.user;
      if (user == null) throw StateError('No email account returned.');
      await user.linkWithCredential(credential);
      await user.reload();
      _pendingGoogleCredential = null;
      _pendingGoogleEmail = null;
      await _activateAccount(user.uid, user.email ?? normalizedEmail);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = _firebaseMessage(error);
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage =
          'Could not link Google to this account. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      _errorMessage = 'Enter a valid email address.';
      notifyListeners();
      return false;
    }

    try {
      _errorMessage = null;
      if (_firebaseAvailable) {
        await FirebaseAuth.instance
            .sendPasswordResetEmail(email: normalizedEmail);
      } else {
        final account = _storage.getAccountByEmail(normalizedEmail);
        if (account == null) {
          _errorMessage = 'No account was found for this email address.';
          notifyListeners();
          return false;
        }
      }
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = _firebaseMessage(error);
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Password reset could not be sent. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      if (_firebaseAvailable) {
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn().signOut();
      }
    } catch (_) {}
    await _storage.setActiveAccountId(null);
    await _storage.setActiveProfileId(null);
    _activeAccountId = null;
    _activeProfileId = null;
    _profiles = [];
    _weightRecords = [];
    _errorMessage = null;
    _pendingGoogleCredential = null;
    _pendingGoogleEmail = null;
    notifyListeners();
  }

  Future<void> createProfile({
    required String name,
    required int dobTimestamp,
    required String gender,
    required double heightCm,
    required double weightKg,
  }) async {
    if (_activeAccountId == null || heightCm <= 0 || weightKg <= 0) return;

    final profileId = _uid();
    final profile = Profile(
      id: profileId,
      accountId: _activeAccountId!,
      name: name.trim(),
      dobTimestamp: dobTimestamp,
      gender: gender,
      heightCm: heightCm,
      weightKg: weightKg,
    );
    await _storage.upsertProfile(profile);
    await _storage.addWeightRecord(WeightRecord(
      id: _uid(),
      profileId: profileId,
      weightKg: weightKg,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
    await _storage.setActiveProfileId(profileId);
    _activeProfileId = profileId;
    _profiles = _storage.getProfilesForAccount(_activeAccountId!);
    _weightRecords = _storage.getWeightRecordsForProfile(profileId);
    notifyListeners();
  }

  Future<void> switchProfile(String profileId) async {
    if (_activeAccountId == null ||
        !_profiles.any((profile) => profile.id == profileId)) return;
    await _storage.setActiveProfileId(profileId);
    _activeProfileId = profileId;
    _weightRecords = _storage.getWeightRecordsForProfile(profileId);
    notifyListeners();
  }

  Future<bool> updateCurrentProfile({
    required double heightCm,
    required double weightKg,
  }) async {
    final profile = currentProfile;
    if (profile == null || heightCm <= 0 || weightKg <= 0) return false;

    await _storage.upsertProfile(
        profile.copyWith(heightCm: heightCm, weightKg: weightKg));
    await _storage.addWeightRecord(WeightRecord(
      id: _uid(),
      profileId: profile.id,
      weightKg: weightKg,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
    _profiles = _storage.getProfilesForAccount(_activeAccountId!);
    _weightRecords = _storage.getWeightRecordsForProfile(profile.id);
    notifyListeners();
    return true;
  }

  void setMetric(bool value) {
    if (_isMetric == value) return;
    _isMetric = value;
    notifyListeners();
  }

  bool _validateCredentials(String email, String password) {
    if (email.isEmpty || !email.contains('@')) {
      _errorMessage = 'Enter a valid email address.';
      notifyListeners();
      return false;
    }
    if (password.length < 6) {
      _errorMessage = 'Password must contain at least 6 characters.';
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<void> _activateAccount(String accountId, String email) async {
    _activeAccountId = accountId;
    await _storage.setActiveAccountId(accountId);
    await _storage.upsertAccount(
      Account(id: accountId, email: email, passwordHash: ''),
    );
    _profiles = _storage.getProfilesForAccount(accountId);
    final storedProfileId = _storage.getActiveProfileId();
    if (storedProfileId != null &&
        _profiles.any((profile) => profile.id == storedProfileId)) {
      _activeProfileId = storedProfileId;
    } else {
      _activeProfileId = _profiles.isEmpty ? null : _profiles.first.id;
      await _storage.setActiveProfileId(_activeProfileId);
    }
    _weightRecords = _activeProfileId == null
        ? []
        : _storage.getWeightRecordsForProfile(_activeProfileId!);
  }

  Future<void> _saveSignupRecovery() async {
    final started = _signupStartedAt;
    if (started == null) return;
    final prefs = await _storage.prefs;
    await prefs.setBool(_recoveringSignupKey, true);
    await prefs.setString(_signupEmailKey, _signupEmail);
    await prefs.setString(_signupTempPasswordKey, _signupTempPassword);
    await prefs.setString(_signupTimestampKey, started.toIso8601String());
  }

  Future<void> _clearSignupRecovery() async {
    final prefs = await _storage.prefs;
    await prefs.remove(_recoveringSignupKey);
    await prefs.remove(_signupEmailKey);
    await prefs.remove(_signupTempPasswordKey);
    await prefs.remove(_signupTimestampKey);
  }

  Future<void> _deletePendingFirebaseUser(String email) async {
    if (!_firebaseAvailable) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email == email) await user.delete();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  String _generateTemporaryPassword() {
    final random = math.Random.secure();
    final suffix = List.generate(24, (_) => random.nextInt(36))
        .map((value) => value.toRadixString(36))
        .join();
    return 'BdTemp!$suffix';
  }

  String _firebaseMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Sign in with its current provider instead.';
      case 'account-exists-with-different-credential':
        return 'This email is already registered with another sign-in method.';
      case 'credential-already-in-use':
        return 'This Google account is already linked to another Firebase account.';
      case 'weak-password':
        return 'Choose a stronger password of at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase Console.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  String _uid() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return '${now}_${math.Random().nextInt(999999)}';
  }
}
