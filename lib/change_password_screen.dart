import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:presence_par_qr/main.dart';
import 'widgets.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, required this.lang});

  final AppLang lang;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _emailController = TextEditingController();
  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _emailController.dispose();
    _oldController.dispose();
    _newController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF18C5C5);
    const bg = Color(0xFF243449);
    final lang = widget.lang;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: bg,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        backgroundColor: bg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          tr(
            lang,
            fr: 'Changer le mot de passe',
            ar: '\u062a\u063a\u064a\u064a\u0631 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631',
            en: 'Change password',
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2636),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    LineInput(
                      hint: tr(
                        lang,
                        fr: 'Email',
                        ar: '\u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a',
                        en: 'Email',
                      ),
                      icon: Icons.mail_outline,
                      accent: accent,
                      controller: _emailController,
                    ),
                    const SizedBox(height: 14),
                    LineInput(
                      hint: tr(
                        lang,
                        fr: 'Mot de passe actuel',
                        ar: '\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631 \u0627\u0644\u062d\u0627\u0644\u064a\u0629',
                        en: 'Current password',
                      ),
                      icon: Icons.lock_outline,
                      accent: accent,
                      obscureText: true,
                      controller: _oldController,
                    ),
                    const SizedBox(height: 14),
                    LineInput(
                      hint: tr(
                        lang,
                        fr: 'Nouveau mot de passe',
                        ar: '\u0643\u0644\u0645\u0629 \u0645\u0631\u0648\u0631 \u062c\u062f\u064a\u062f\u0629',
                        en: 'New password',
                      ),
                      icon: Icons.lock_outline,
                      accent: accent,
                      obscureText: true,
                      controller: _newController,
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
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                          ),
                          elevation: 4,
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
                                  fr: 'Confirmer',
                                  ar: '\u062a\u0623\u0643\u064a\u062f',
                                  en: 'Confirm',
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(bool isAr) async {
    final email = _emailController.text.trim();
    final oldPass = _oldController.text;
    final newPass = _newController.text;
    if (email.isEmpty || oldPass.isEmpty || newPass.isEmpty) {
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
          ? await localApi.changePassword(
              email: email,
              oldPassword: oldPass,
              newPassword: newPass,
            )
          : jsonDecode(
                  (await http.post(
                    Uri.parse('$apiBase/auth/change-password'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'email': email,
                      'oldPassword': oldPass,
                      'newPassword': newPass,
                    }),
                  )).body,
                )
                as Map<String, dynamic>;
      if (data['ok'] != true) {
        final reason = data['reason']?.toString() ?? 'error';
        setState(() {
          _error = reason == 'invalid'
              ? (isAr ? 'كلمة المرور غير صحيحة' : 'Mot de passe incorrect')
              : (isAr ? 'المستخدم غير موجود' : 'Utilisateur introuvable');
        });
        return;
      }
      setState(() {
        _success = isAr ? 'تم التغيير بنجاح' : 'Changement réussi';
      });
    } catch (_) {
      setState(() {
        _error = isAr ? 'تعذر الاتصال بالخادم' : 'Impossible de se connecter';
      });
    } finally {
      setState(() => _loading = false);
    }
  }
}
