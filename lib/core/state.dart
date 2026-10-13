import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  String lang = 'en';
  Profile? profile;
  Json? supplierData;
  bool loading = true;
  String? selectedRole; // 'customer' | 'supplier' | 'admin'
  String? roleErrorMessage;
  StreamSubscription? _sub;

  bool get signedIn => Api.client.auth.currentSession != null;

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    lang = p.getString('lang') ?? 'en';
    selectedRole = p.getString('last_role');
    _sub = Api.client.auth.onAuthStateChange.listen((_) => refresh());
    await refresh();
  }

  Future<void> refresh() async {
    try {
      if (signedIn) {
        profile = await Api.fetchProfile();
        if (profile?.role == 'supplier') {
          try {
            supplierData = await Api.mySupplier();
          } catch (_) {
            supplierData = null;
          }
        } else {
          supplierData = null;
        }

        // Check if user is blocked
        if (profile != null && profile!.isBlocked) {
          roleErrorMessage = 'acc_blocked';
          await Api.signOut();
          profile = null;
          supplierData = null;
        }
      } else {
        profile = null;
        supplierData = null;
      }
    } catch (_) {
      profile = null;
      supplierData = null;
    }
    loading = false;
    notifyListeners();
  }

  Future<void> setSelectedRole(String? r) async {
    selectedRole = r;
    roleErrorMessage = null;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    if (r != null) {
      await p.setString('last_role', r);
    } else {
      await p.remove('last_role');
    }
  }

  Future<void> clearRole() async {
    selectedRole = null;
    roleErrorMessage = null;
    final p = await SharedPreferences.getInstance();
    await p.remove('last_role');
    notifyListeners();
  }

  Future<void> signOutAndChangeRole() async {
    loading = true;
    notifyListeners();
    try {
      await Api.signOut();
    } catch (_) {}
    profile = null;
    supplierData = null;
    selectedRole = null;
    roleErrorMessage = null;
    final p = await SharedPreferences.getInstance();
    await p.remove('last_role');
    loading = false;
    notifyListeners();
  }

  void setRoleError(String errorKey) {
    roleErrorMessage = errorKey;
    notifyListeners();
  }

  void clearRoleError() {
    roleErrorMessage = null;
    notifyListeners();
  }

  Future<void> setLang(String l) async {
    lang = l;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString('lang', l);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
