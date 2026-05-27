import 'dart:async';
import 'package:fast_livraison_mobile/geolocations/Mygeo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // 6 controllers, un par chiffre
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  // Compte à rebours pour le renvoi du SMS
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // Focus automatique sur le premier champ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        timer.cancel();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  // Récupère le code complet à partir des 6 champs
  String get _otpCode => _controllers.map((c) => c.text).join();

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final isLoading = authService.status == AuthStatus.verifying;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ── Icône ───────────────────────────────────────────────────
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.sms, size: 40, color: Colors.green.shade600),
                ),
              ),
              const SizedBox(height: 28),

              Text(
                'Code de vérification',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  children: [
                    const TextSpan(text: 'Code envoyé au '),
                    TextSpan(
                      text: widget.phoneNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // ── Saisie des 6 chiffres OTP ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) => _buildOtpBox(index)),
              ),
              const SizedBox(height: 16),

              // ── Erreur ─────────────────────────────────────────────────
              if (authService.status == AuthStatus.error)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade600, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          authService.errorMessage ?? '',
                          style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // ── Bouton Vérifier ────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: isLoading ? null : _verifyCode,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Vérifier le code',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Renvoyer le SMS ────────────────────────────────────────
              Center(
                child: _countdown > 0
                    ? Text(
                        'Renvoyer le code dans ${_countdown}s',
                        style: TextStyle(color: Colors.grey.shade500),
                      )
                    : TextButton(
                        onPressed: _resendCode,
                        child: const Text('Renvoyer le code SMS'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit une case de saisie OTP individuelle
  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '', // Cache le compteur de caractères
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: EdgeInsets.zero,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            // Passe au champ suivant automatiquement
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            // Retourne au champ précédent si on efface
            _focusNodes[index - 1].requestFocus();
          }
          // Auto-vérification quand les 6 chiffres sont saisis
          if (_otpCode.length == 6) {
            _verifyCode();
          }
        },
      ),
    );
  }

  Future<void> _verifyCode() async {
    final code = _otpCode;
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrez les 6 chiffres du code')),
      );
      return;
    }
    await context.read<AuthService>().verifyOTP(code);
    // La navigation est gérée automatiquement par le Consumer dans main.dart

     // ✅ Vérifier après vérification si connecté → naviguer
  if (mounted && context.read<AuthService>().isLoggedIn) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MyGeo()),
      (route) => false, // ← supprime tout le stack (LoginPhone + OtpScreen)
    );
  }
  }

  Future<void> _resendCode() async {
    // Réinitialise les champs
    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
    _startCountdown();
    await context.read<AuthService>().sendOTP(widget.phoneNumber);
  }
}
