import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/config/theme.dart';
import 'features/auth/views/login_screen.dart';
import 'features/auth/views/reset_password_screen.dart';
import 'features/product/views/product_list_screen.dart';
import 'features/chat/views/admin_chat_inbox_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://nfghwukwbkjjngxsbaqq.supabase.co',
    publishableKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5mZ2h3dWt3Ymtqam5neHNiYXFxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA3MTk3MTYsImV4cCI6MjEwNjI5NTcxNn0.T2MigFrUN-CESiR2MK0zYmDUw-a5pd25E2FyYLm5Rsw',
    authOptions: const FlutterAuthClientOptions(
      persistSession: true,
      autoRefreshToken: true,
    ),
  );

  bool initialPasswordRecovery = false;

  // ตรวจสอบลิงก์ที่ Supabase ส่งกลับมาจากอีเมล
  final uri = Uri.base;
  final code = uri.queryParameters['code'];

  if (code != null && code.isNotEmpty) {
    try {
      await Supabase.instance.client.auth.exchangeCodeForSession(code);
      initialPasswordRecovery = true;
      debugPrint('แลกเปลี่ยนรหัสรีเซ็ตรหัสผ่านสำเร็จ');
    } catch (e) {
      debugPrint('PASSWORD RECOVERY ERROR: $e');
    }
  }

  runApp(BakeryApp(initialPasswordRecovery: initialPasswordRecovery));
}

final supabase = Supabase.instance.client;

class BakeryApp extends StatelessWidget {
  final bool initialPasswordRecovery;

  const BakeryApp({super.key, this.initialPasswordRecovery = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wongherm Bakery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: AuthGate(initialPasswordRecovery: initialPasswordRecovery),
    );
  }
}

// =========================================
// AuthGate: ตรวจสอบ Login และ Password Recovery
// =========================================
class AuthGate extends StatefulWidget {
  final bool initialPasswordRecovery;

  const AuthGate({super.key, this.initialPasswordRecovery = false});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Session? _session;
  bool _isLoading = true;
  late bool _isPasswordRecovery;

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();

    _isPasswordRecovery = widget.initialPasswordRecovery;
    _session = supabase.auth.currentSession;
    _isLoading = false;

    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;

      final nextSession = data.event == AuthChangeEvent.signedOut
          ? null
          : data.session ?? supabase.auth.currentSession;

      setState(() {
        _session = nextSession;

        if (data.event == AuthChangeEvent.passwordRecovery) {
          _isPasswordRecovery = true;
        } else if (data.event == AuthChangeEvent.signedOut) {
          _isPasswordRecovery = false;
        }

        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ให้หน้าตั้งรหัสผ่านใหม่มาก่อนการตรวจสอบ Role
    if (_isPasswordRecovery) {
      return const ResetPasswordScreen();
    }

    if (_session == null) {
      return const LoginScreen();
    }

    return RoleGate(
      key: ValueKey(_session!.user.id),
      userId: _session!.user.id,
    );
  }
}

// =========================================
// RoleGate: ตรวจสอบ Role จาก Supabase
// =========================================
class RoleGate extends StatefulWidget {
  final String userId;

  const RoleGate({super.key, required this.userId});

  @override
  State<RoleGate> createState() => _RoleGateState();
}

class _RoleGateState extends State<RoleGate> {
  String? _role;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    try {
      final result = await supabase
          .from('user_roles')
          .select('role')
          .eq('user_id', widget.userId)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _role = result?['role']?.toString().toLowerCase();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                const Text('ตรวจสอบสิทธิ์ผู้ใช้ไม่สำเร็จ'),
                const SizedBox(height: 8),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadRole,
                  child: const Text('ลองอีกครั้ง'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_role == 'owner') {
      return const OwnerDashboardScreen();
    }

    if (_role == 'customer') {
      return const ProductListScreen();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('ไม่พบสิทธิ์ผู้ใช้')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48),
              const SizedBox(height: 12),
              const Text(
                'บัญชีนี้ยังไม่มี Role ที่ถูกต้อง',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text('Role ปัจจุบัน: ${_role ?? "ไม่มีข้อมูล"}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await supabase.auth.signOut();
                },
                child: const Text('ออกจากระบบ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================
// หน้าเจ้าของร้าน
// =========================================
class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final email = supabase.auth.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏪 จัดการร้าน Wongherm Bakery'),
        actions: [
          IconButton(
            tooltip: 'ออกจากระบบ',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storefront, size: 90, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'ยินดีต้อนรับ เจ้าของร้าน',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(email),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('ข้อความจากลูกค้า'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminChatInboxScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.inventory_2),
                  label: const Text('จัดการสินค้า'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProductListScreen(isOwner: true),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
