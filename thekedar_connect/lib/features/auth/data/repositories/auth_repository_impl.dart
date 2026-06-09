import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/auth_repository.dart';

import 'package:google_sign_in/google_sign_in.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabase;

  AuthRepositoryImpl(this._supabase);

  @override
  Future<void> signInWithGoogle() async {
    const webClientId = '47406421196-o9skujh8uehjp6fvqiopqjc4k45ifebq.apps.googleusercontent.com';

    await GoogleSignIn.instance.initialize(serverClientId: webClientId);
    final googleUser = await GoogleSignIn.instance.authenticate();
    
    if (googleUser == null) {
      throw 'Google Sign In was canceled or failed.';
    }

    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw 'No ID Token found.';
    }

    // Optional access token if needed for Supabase (usually just idToken is enough)
    final authClient = googleUser.authorizationClient;
    final authScopes = await authClient.authorizationForScopes(['email', 'profile']);
    final accessToken = authScopes?.accessToken;

    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  @override
  Stream<User?> get authStateChanges =>
      _supabase.auth.onAuthStateChange.map((event) => event.session?.user);
}
