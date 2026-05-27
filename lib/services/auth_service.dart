import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
/// États possibles du processus d'authentification
enum AuthStatus {
  idle,           // Aucune opération en cours
  sendingCode,    // Envoi du SMS en cours
  codeSent,       // SMS envoyé, en attente du code OTP
  verifying,      // Vérification du code OTP en cours
  authenticated,  // Utilisateur connecté
  error,          // Erreur survenue
}

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;
  String? _verificationId;   // ID retourné par Firebase pour lier envoi et vérification
  int? _resendToken;         // Token pour renvoyer le SMS sans recaptcha

  // ─── Getters publics ────────────────────────────────────────────────────────

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _auth.currentUser != null;
  User? get currentUser => _auth.currentUser;

  // ─── ÉTAPE 1 : Envoyer le SMS ────────────────────────────────────────────────

  /// [phoneNumber] doit être au format E.164 : "+22200000000"
  Future<void> sendOTP(String phoneNumber) async {
    _setStatus(AuthStatus.sendingCode);

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,

      // ── Timeout avant que Firebase abandonne l'auto-récupération ──
      timeout: const Duration(seconds: 60),

      // ── Rappelé dès que le SMS est envoyé ────────────────────────
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        _setStatus(AuthStatus.codeSent);
        debugPrint('SMS envoyé. verificationId: $verificationId');
      },

      // ── Sur Android : récupération automatique du code SMS ────────
      // Appelé si Firebase détecte automatiquement le code (sans saisie)
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
        debugPrint('Auto-retrieval timeout. verificationId: $verificationId');
      },

      // ── Sur Android : code récupéré automatiquement ───────────────
      verificationCompleted: (PhoneAuthCredential credential) async {
        debugPrint('Vérification automatique déclenchée');
        await _signInWithCredential(credential);
      },

      // ── Erreur lors de l'envoi ────────────────────────────────────
      verificationFailed: (FirebaseAuthException e) {
        debugPrint('Erreur vérification: ${e.code} - ${e.message}');
        _setError(_mapFirebaseError(e.code));
      },

      // ── Token pour renvoyer le SMS (évite un nouveau reCAPTCHA) ───
      forceResendingToken: _resendToken,
    );
  }

  // ─── ÉTAPE 2 : Vérifier l'OTP saisi ─────────────────────────────────────────

  /// [otp] est le code à 6 chiffres reçu par SMS
  Future<void> verifyOTP(String otp) async {
    if (_verificationId == null) {
      _setError('Veuillez d\'abord demander un code SMS');
      return;
    }

    _setStatus(AuthStatus.verifying);

    // Création du credential avec l'ID de vérification + le code saisi
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otp,
    );

    await _signInWithCredential(credential);
  }

  // ─── Connexion avec le credential ────────────────────────────────────────────

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('Connecté : ${userCredential.user?.phoneNumber}');
      _setStatus(AuthStatus.authenticated);
    } on FirebaseAuthException catch (e) {
      debugPrint('Erreur connexion: ${e.code} - ${e.message}');
      _setError(_mapFirebaseError(e.code));
    }
  }

  // ─── Déconnexion ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _auth.signOut();
    _verificationId = null;
    _resendToken = null;
    _setStatus(AuthStatus.idle);
  }

  // ─── Helpers privés ──────────────────────────────────────────────────────────

  void _setStatus(AuthStatus status) {
    _status = status;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  /// Traduit les codes d'erreur Firebase en messages lisibles
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'Numéro de téléphone invalide';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard';
      case 'invalid-verification-code':
        return 'Code incorrect. Vérifiez le SMS';
      case 'session-expired':
        return 'Code expiré. Demandez un nouveau SMS';
      case 'quota-exceeded':
        return 'Quota SMS dépassé. Contactez le support';
      case 'network-request-failed':
        return 'Pas de connexion Internet';
      default:
        return 'Erreur: $code';
    }
  }


  // Ajouter cette méthode dans AuthService
Future<bool> isConnected() async {
  final result = await Connectivity().checkConnectivity();
  return result != ConnectivityResult.none;
}
}
