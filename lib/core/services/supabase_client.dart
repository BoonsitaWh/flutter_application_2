import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // Shortcut accessors
  static User? get currentUser => client.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;
}