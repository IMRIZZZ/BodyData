// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../models/profile.dart';
import '../models/weight_record.dart';

/// Local persistence service using SharedPreferences.
///
/// FIREBASE MIGRATION NOTE:
/// When integrating Firebase, replace each method body with the corresponding
/// Firestore / Realtime Database call.  The interface (method signatures) can
/// stay the same, keeping screen / provider code unchanged.
class StorageService {
  static const _accountsKey = 'bd_accounts';
  static const _profilesKey = 'bd_profiles';
  static const _weightRecordsKey = 'bd_weight_records';
  static const _activeAccountKey = 'bd_active_account_id';
  static const _activeProfileKey = 'bd_active_profile_id';

  final SharedPreferences _prefs;
  StorageService._(this._prefs);

  /// Direct access used only for short-lived signup recovery metadata.
  SharedPreferences get prefs => _prefs;

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService._(prefs);
  }

  // ───────────────────────── Accounts ──────────────────────────

  List<Account> getAccounts() {
    try {
      final raw = _prefs.getString(_accountsKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Account.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('StorageService.getAccounts error: $e');
      return [];
    }
  }

  Future<void> _saveAccounts(List<Account> accounts) async {
    await _prefs.setString(
      _accountsKey,
      jsonEncode(accounts.map((a) => a.toJson()).toList()),
    );
  }

  Account? getAccountByEmail(String email) {
    final lower = email.toLowerCase();
    for (final a in getAccounts()) {
      if (a.email.toLowerCase() == lower) return a;
    }
    return null;
  }

  Future<void> upsertAccount(Account account) async {
    final accounts = getAccounts();
    final idx = accounts.indexWhere((a) => a.id == account.id);
    if (idx >= 0) {
      accounts[idx] = account;
    } else {
      accounts.add(account);
    }
    await _saveAccounts(accounts);
  }

  // ───────────────────────── Profiles ──────────────────────────

  List<Profile> getProfiles() {
    try {
      final raw = _prefs.getString(_profilesKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Profile.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('StorageService.getProfiles error: $e');
      return [];
    }
  }

  List<Profile> getProfilesForAccount(String accountId) =>
      getProfiles().where((p) => p.accountId == accountId).toList();

  Profile? getProfile(String profileId) {
    for (final p in getProfiles()) {
      if (p.id == profileId) return p;
    }
    return null;
  }

  Future<void> _saveProfiles(List<Profile> profiles) async {
    await _prefs.setString(
      _profilesKey,
      jsonEncode(profiles.map((p) => p.toJson()).toList()),
    );
  }

  Future<void> upsertProfile(Profile profile) async {
    final profiles = getProfiles();
    final idx = profiles.indexWhere((p) => p.id == profile.id);
    if (idx >= 0) {
      profiles[idx] = profile;
    } else {
      profiles.add(profile);
    }
    await _saveProfiles(profiles);
  }

  // ─────────────────────── Weight Records ───────────────────────

  List<WeightRecord> getWeightRecords() {
    try {
      final raw = _prefs.getString(_weightRecordsKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => WeightRecord.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('StorageService.getWeightRecords error: $e');
      return [];
    }
  }

  List<WeightRecord> getWeightRecordsForProfile(String profileId) {
    return getWeightRecords()
        .where((r) => r.profileId == profileId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> _saveWeightRecords(List<WeightRecord> records) async {
    await _prefs.setString(
      _weightRecordsKey,
      jsonEncode(records.map((r) => r.toJson()).toList()),
    );
  }

  Future<void> addWeightRecord(WeightRecord record) async {
    final records = getWeightRecords()..add(record);
    await _saveWeightRecords(records);
  }

  // ─────────────────── Active Account / Profile ──────────────────

  String? getActiveAccountId() => _prefs.getString(_activeAccountKey);
  String? getActiveProfileId() => _prefs.getString(_activeProfileKey);

  Future<void> setActiveAccountId(String? id) async {
    if (id == null) {
      await _prefs.remove(_activeAccountKey);
    } else {
      await _prefs.setString(_activeAccountKey, id);
    }
  }

  Future<void> setActiveProfileId(String? id) async {
    if (id == null) {
      await _prefs.remove(_activeProfileKey);
    } else {
      await _prefs.setString(_activeProfileKey, id);
    }
  }
}
