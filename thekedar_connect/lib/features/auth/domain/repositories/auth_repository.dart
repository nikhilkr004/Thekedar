import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Stream<User?> get authStateChanges;
}
