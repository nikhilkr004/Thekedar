import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/auth_repository.dart';

import 'package:google_sign_in/google_sign_in.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabase;

  AuthRepositoryImpl(this._supabase);

  @override
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      // On Web, use Supabase's native OAuth flow to sign in with Google.
      // This avoids google_sign_in package limitations and initialization crashes on Web.
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        // The default redirect URI will be the current origin (e.g. http://127.0.0.1:8081/#/auth)
      );
      return;
    }

    // Mobile/native platforms use GoogleSignIn to get the ID token and send it to Supabase.
    const webClientId = '47406421196-o9skujh8uehjp6fvqiopqjc4k45ifebq.apps.googleusercontent.com';

    await GoogleSignIn.instance.initialize(serverClientId: webClientId);
    final googleUser = await GoogleSignIn.instance.authenticate();
    
    if (googleUser == null) {
      throw 'Google Sign In was canceled or failed.';
    }

    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw 'No Token ID Found! First SignUp ';
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
