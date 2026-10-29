import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // =========================
  // REGISTER
  // =========================
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  // =========================
  // LOGIN
  // =========================
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // =========================
  // CURRENT USER
  // =========================
  User? get currentUser => _supabase.auth.currentUser;

  // =========================
  // UPDATE PROFILE
  // =========================
  Future<User?> updateProfile({
    required String fullName,
    required String phone,
    required String address,
  }) async {
    final response = await _supabase.auth.updateUser(
      UserAttributes(
        data: {'full_name': fullName, 'phone': phone, 'address': address},
      ),
    );

    return response.user;
  }

  // =========================
  // GET PROFILE DATA
  // =========================
  Map<String, dynamic> getProfileData() {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return {};
    }

    return {
      'id': user.id,
      'email': user.email ?? '',
      'full_name': user.userMetadata?['full_name'] ?? '',
      'phone': user.userMetadata?['phone'] ?? '',
      'address': user.userMetadata?['address'] ?? '',
    };
  }

  // =========================
  // DELETE ACCOUNT
  // =========================
  Future<void> deleteAccount() async {
    // ตรวจสอบ session ปัจจุบัน
    final session = _supabase.auth.currentSession;

    if (session == null) {
      throw Exception('ไม่พบเซสชันผู้ใช้งาน');
    }

    final response = await _supabase.functions.invoke(
      'delete-account',
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );

    if (response.status != 200) {
      throw Exception(response.data?['error'] ?? 'ไม่สามารถลบบัญชีได้');
    }

    await _supabase.auth.signOut();
  }
}
