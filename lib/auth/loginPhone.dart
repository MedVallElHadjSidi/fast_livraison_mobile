import 'package:flutter/material.dart'; // widgets Flutter
import 'package:intl_phone_field/countries.dart'; // modèle Country
import 'package:intl_phone_field/intl_phone_field.dart'; // widget champ téléphone
import '../services/auth_service.dart'; //  ma logique Firebase
import 'package:provider/provider.dart'; // gestion d'état
import 'otp_screen.dart'; // écran suivant

class LoginPhone extends StatefulWidget {
  const LoginPhone({super.key});

  @override
  State<LoginPhone> createState() => _LoginPhoneState();
}

class _LoginPhoneState extends State<LoginPhone> {
  String _completePhoneNumber = ''; // Numéro complet avec indicatif (+222...)
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();


  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un numéro de téléphone')),
      );
    }

    if (_completePhoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Veuillez entrer un numéro de téléphone'),
        ),
      );
      return;
    }

    // ↑ context.read (pas watch) car on appelle juste une méthode
    final authService = context.read<AuthService>();
          // ✅ Vérification connexion Internet
  // final authService = context.read<AuthService>();
  // final connected = await authService.isConnected();

  // if (!connected) {
  //   // isLoading=false;
  //   print("pas de connexion Internet");
  //   if (mounted) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Row(
  //           children: [
  //             Icon(Icons.wifi_off, color: Colors.white),
  //             SizedBox(width: 10),
  //             Text('Pas de connexion Internet'),
  //           ],
  //         ),
  //         backgroundColor: Colors.red.shade600,
  //         duration: Duration(seconds: 3),
  //       ),
  //     );
  //   }
  //   return; // ← stop ici, n'envoie pas le SMS
  // }

    // Écoute une seule fois le changement de statut après l'envoi
    void listener() {
      if (authService.status == AuthStatus.codeSent && mounted) {
        // 3. SMS envoyé → navigation vers OtpScreen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(phoneNumber: _completePhoneNumber),
          ),
        );

        authService.removeListener(listener); // ← stop l'écoute
      } else if (authService.status == AuthStatus.error) {
        authService.removeListener(listener); // ← stop l'écoute
      }
    }

    // ← démarre l'écoute
    authService.addListener(listener);
    await authService.sendOTP(_completePhoneNumber); // ← appel Firebase
  }

  @override
  Widget build(BuildContext context) {
      //  écoute AuthService → rebuild automatique si status change
    final authService = context.watch<AuthService>();
    //  true quand Firebase envoie le SMS → désactive le bouton
    final isLoading = authService.status == AuthStatus.sendingCode;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                // ── Icône et titre ──────────────────────────────────────────
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.phone_android,
                      size: 40,
                      color: Colors.indigo.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Votre numéro\nde téléphone',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nous vous enverrons un code de vérification par SMS.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                ),
                const SizedBox(height: 40),
                // ── Champ numéro avec sélecteur de pays ───────────────────
                IntlPhoneField(
                  countries: [
                    Country(
                      name: "Mauritania",
                      flag: '🇲🇷',
                      code: "MR",
                      dialCode: "222",
                      nameTranslations: {
                        'en': 'Mauritania',
                        'fr': 'Mauritanie',
                        'ar': 'موريتانيا',
                      },
                      minLength: 8,
                      maxLength: 8,
                    ),
                  ],

                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),

                  initialCountryCode: 'MR', // Mauritanie par défaut
                  onChanged: (phone) {
                    // phone.completeNumber = "+222XXXXXXXX"
                    _completePhoneNumber = phone.completeNumber;
                  },
                  // Validation intégrée du format par pays
                  invalidNumberMessage: 'Numéro invalide pour ce pays',
                ),
                // const SizedBox(height: 16),
                const SizedBox(height: 24),

                // ── Bouton Envoyer ────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: isLoading ? null : _sendCode,
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
                            'Envoyer le code SMS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'En continuant, vous acceptez de recevoir\nun SMS de vérification.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
