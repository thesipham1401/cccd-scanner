import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' show AuthClient;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/sheets/v4.dart' show SheetsApi;

/// Wraps google_sign_in 7.x: identity (authenticate) and authorization
/// (authorizeScopes) are separate steps in this version.
class AuthService {
  /// Web OAuth client ID. On Android, authorization for API scopes needs this
  /// (set after Google Cloud setup — see docs/superpowers/notes/google-setup.md).
  final String? serverClientId;

  AuthService({this.serverClientId});

  static const List<String> _scopes = <String>[SheetsApi.spreadsheetsScope];

  GoogleSignInAccount? _current;
  bool _initialized = false;

  GoogleSignInAccount? get currentUser => _current;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(serverClientId: serverClientId);
    _initialized = true;
  }

  /// Silent sign-in for an already-authenticated user; null if none.
  Future<GoogleSignInAccount?> signInSilently() async {
    await _ensureInit();
    _current = await GoogleSignIn.instance.attemptLightweightAuthentication();
    return _current;
  }

  /// Interactive sign-in. Returns null on platforms without interactive auth.
  Future<GoogleSignInAccount?> signIn() async {
    await _ensureInit();
    if (!GoogleSignIn.instance.supportsAuthenticate()) return null;
    _current = await GoogleSignIn.instance.authenticate(scopeHint: _scopes);
    return _current;
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    _current = null;
  }

  /// A googleapis-ready HTTP client authorized for the Sheets scope, or null
  /// if not signed in.
  Future<AuthClient?> authedClient() async {
    final account = _current;
    if (account == null) return null;
    final authz = await account.authorizationClient.authorizeScopes(_scopes);
    return authz.authClient(scopes: _scopes);
  }
}
