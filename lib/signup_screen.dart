import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:presence_par_qr/main.dart';
import 'widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.lang});

  final AppLang lang;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _jobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _jobController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgTop = Color(0xFF2F6E5A);
    const bgBottom = Color(0xFF4F9F84);
    const card = Color(0xFF2E6A55);
    const field = Color(0xFF4C9075);
    const accent = Color(0xFF7DE3C2);
    const textLight = Color(0xFFF5FFFB);
    final lang = widget.lang;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [bgTop, bgBottom],
                ),
              ),
            ),
          ),
          Positioned(
            left: -60,
            right: -60,
            bottom: -200,
            child: Container(
              height: 420,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.elliptical(620, 320),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Spacer(),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      tr(
                        lang,
                        fr: 'Presence QR System',
                        ar: '\u0646\u0638\u0627\u0645 \u0627\u0644\u062d\u0636\u0648\u0631 \u0628\u0627\u0644\u0631\u0645\u0632',
                        en: 'Presence QR System',
                      ),
                      style: TextStyle(
                        color: textLight,
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr(
                        lang,
                        fr: 'Attendance via QR code',
                        ar: '\u0627\u0644\u062d\u0636\u0648\u0631 \u0639\u0628\u0631 \u0631\u0645\u0632 QR',
                        en: 'Attendance via QR code',
                      ),
                      style: TextStyle(
                        color: textLight.withOpacity(0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 44),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      MediaQuery.of(context).viewInsets.bottom + 16,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                      decoration: BoxDecoration(
                        color: card.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          LineInput(
                            hint: tr(
                              lang,
                              fr: 'Nom complet',
                              ar: '\u0627\u0644\u0627\u0633\u0645 \u0627\u0644\u0643\u0627\u0645\u0644',
                              en: 'Full name',
                            ),
                            icon: Icons.person_outline,
                            accent: accent,
                            fillColor: field,
                            controller: _nameController,
                          ),
                          const SizedBox(height: 14),
                          LineInput(
                            hint: tr(
                              lang,
                              fr: 'Email',
                              ar: '\u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a',
                              en: 'Email',
                            ),
                            icon: Icons.mail_outline,
                            accent: accent,
                            fillColor: field,
                            controller: _emailController,
                          ),
                          const SizedBox(height: 14),
                          LineInput(
                            hint: tr(
                              lang,
                              fr: 'Téléphone',
                              ar: '\u0627\u0644\u0647\u0627\u062a\u0641',
                              en: 'Phone',
                            ),
                            icon: Icons.phone_outlined,
                            accent: accent,
                            fillColor: field,
                            controller: _phoneController,
                          ),
                          const SizedBox(height: 14),
                          LineInput(
                            hint: tr(
                              lang,
                              fr: 'Fonction',
                              ar: '\u0627\u0644\u0648\u0638\u064a\u0641\u0629',
                              en: 'Role',
                            ),
                            icon: Icons.work_outline,
                            accent: accent,
                            fillColor: field,
                            controller: _jobController,
                          ),
                          const SizedBox(height: 14),
                          LineInput(
                            hint: tr(
                              lang,
                              fr: 'Mot de passe',
                              ar: '\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631',
                              en: 'Password',
                            ),
                            icon: Icons.lock_outline,
                            accent: accent,
                            fillColor: field,
                            obscureText: true,
                            controller: _passwordController,
                          ),
                          const SizedBox(height: 16),
                          LineInput(
                            hint: tr(
                              lang,
                              fr: 'Code de vérification',
                              ar: '\u0631\u0645\u0632 \u0627\u0644\u062a\u062d\u0642\u0642',
                              en: 'Verification code',
                            ),
                            icon: Icons.verified_outlined,
                            accent: accent,
                            fillColor: field,
                            controller: _otpController,
                          ),
                          const SizedBox(height: 16),
                          if (_error != null) ...[
                            Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (_success != null) ...[
                            Text(
                              _success!,
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                          ],
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              onPressed: _loading
                                  ? null
                                  : () => _submit(lang == AppLang.ar),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: const Color(0xFF255B48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 6,
                                shadowColor: Colors.black.withOpacity(0.3),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      tr(
                                        lang,
                                        fr: 'Envoyer',
                                        ar: '\u0625\u0631\u0633\u0627\u0644',
                                        en: 'Send',
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: textLight,
                            ),
                            child: Text(
                              tr(
                                lang,
                                fr: 'Retour',
                                ar: '\u0631\u062c\u0648\u0639',
                                en: 'Back',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(bool isAr) async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final job = _jobController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        _error = isAr ? 'حقول مطلوبة' : 'Champs requis';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      final data = useLocal
          ? await localApi.register(
              fullName: name,
              email: email,
              password: password,
              otp: _otpController.text.trim(),
              phone: phone,
              jobTitle: job,
            )
          : jsonDecode(
                  (await http.post(
                    Uri.parse('$apiBase/auth/register'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'fullName': name,
                      'email': email,
                      'password': password,
                      'phone': phone,
                      'jobTitle': job,
                    }),
                  )).body,
                )
                as Map<String, dynamic>;
      if (data['ok'] != true) {
        final reason = data['reason']?.toString() ?? 'error';
        setState(() {
          _error = reason == 'email_exists'
              ? (isAr ? 'البريد مستعمل' : 'Email déjà utilisé')
              : (isAr ? 'خطأ' : 'Erreur');
        });
        return;
      }
      setState(() {
        _success = isAr
            ? 'تم إرسال الطلب، في انتظار التفعيل'
            : 'Demande envoyée, en attente de validation';
      });
    } catch (_) {
      setState(() {
        _error = isAr ? 'تعذر الاتصال' : 'Impossible de se connecter';
      });
    } finally {
      setState(() => _loading = false);
    }
  }
}
