import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'main.dart';
import 'widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.lang});

  final AppLang lang;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  Timer? _otpTimer;
  bool _loading = false;
  bool _otpLoading = false;
  String? _error;
  String? _success;
  String? _otpInfo;
  String? _lastOtpEmail;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus) {
        _maybeSendOtp();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _emailFocus.dispose();
    _otpTimer?.cancel();
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
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 720;
    final topPadding = isSmall ? 14.0 : 20.0;
    final titleSize = isSmall ? 22.0 : 24.0;
    final subtitleSize = isSmall ? 11.0 : 12.0;
    final headerGap = isSmall ? 8.0 : 10.0;
    final afterHeaderGap = isSmall ? 44.0 : 56.0;
    final bottomShapeHeight = isSmall ? 340.0 : 420.0;
    final bottomShapeOffset = isSmall ? -240.0 : -200.0;

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
            bottom: bottomShapeOffset,
            child: Container(
              height: bottomShapeHeight,
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
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: topPadding,
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
                SizedBox(height: headerGap),
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
                        fontSize: titleSize,
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
                        fontSize: subtitleSize,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: afterHeaderGap),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: accent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                tr(
                                  lang,
                                  fr: 'Mot de passe oublié',
                                  ar: '\u0646\u0633\u064a\u062a \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631',
                                  en: 'Forgot password',
                                ),
                                style: TextStyle(
                                  color: textLight,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
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
                            focusNode: _emailFocus,
                            onChanged: (_) => _scheduleOtp(),
                          ),
                          const SizedBox(height: 14),
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
                            fillColor: field,
                            obscureText: true,
                            controller: _newPasswordController,
                          ),
                          const SizedBox(height: 14),
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
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (_otpInfo != null) ...[
                            Text(
                              _otpInfo!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
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

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final code = _otpController.text.trim();
    final newPassword = _newPasswordController.text;
    if (email.isEmpty) {
      setState(
        () => _error = tr(
          widget.lang,
          fr: 'Entrez votre email',
          ar: '\u0623\u062f\u062e\u0644 \u0627\u0644\u0628\u0631\u064a\u062f',
          en: 'Enter your email',
        ),
      );
      return;
    }
    if (code.isEmpty) {
      setState(
        () => _error = tr(
          widget.lang,
          fr: 'Entrez le code',
          ar: '\u0623\u062f\u062e\u0644 \u0627\u0644\u0631\u0645\u0632',
          en: 'Enter the code',
        ),
      );
      return;
    }
    if (newPassword.isEmpty) {
      setState(
        () => _error = tr(
          widget.lang,
          fr: 'Entrez le nouveau mot de passe',
          ar: '\u0623\u062f\u062e\u0644 \u0643\u0644\u0645\u0629 \u0645\u0631\u0648\u0631 \u062c\u062f\u064a\u062f\u0629',
          en: 'Enter the new password',
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      final data = useLocal
          ? await localApi.verifyOtp(email, code)
          : jsonDecode(
                  (await http.post(
                    Uri.parse('$apiBase/auth/reset-password'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'email': email,
                      'code': code,
                      'newPassword': newPassword,
                    }),
                  )).body,
                )
                as Map<String, dynamic>;
      if (data['ok'] == true) {
        setState(() {
          _success = tr(
            widget.lang,
            fr: 'Mot de passe modifie avec succes',
            ar: '\u062a\u0645 \u0627\u0644\u062a\u062d\u0642\u0642 \u0645\u0646 \u0627\u0644\u0631\u0645\u0632',
            en: 'Password changed successfully',
          );
        });
      } else {
        setState(() {
          final reason = data['reason']?.toString() ?? 'invalid';
          _error = reason == 'expired'
              ? tr(
                  widget.lang,
                  fr: 'Code expiré',
                  ar: '\u0627\u0646\u062a\u0647\u062a \u0635\u0644\u0627\u062d\u064a\u0629 \u0627\u0644\u0631\u0645\u0632',
                  en: 'Code expired',
                )
              : tr(
                  widget.lang,
                  fr: 'Code invalide',
                  ar: '\u0631\u0645\u0632 \u063a\u064a\u0631 \u0635\u0627\u0644\u062d',
                  en: 'Invalid code',
                );
        });
      }
    } catch (_) {
      setState(() {
        _error = tr(
          widget.lang,
          fr: 'Impossible de se connecter',
          ar: '\u062a\u0639\u0630\u0631 \u0627\u0644\u0627\u062a\u0635\u0627\u0644',
          en: 'Connection failed',
        );
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  void _maybeSendOtp() {
    if (!_emailFocus.hasFocus) _scheduleOtp();
  }

  void _scheduleOtp() {
    final email = _emailController.text.trim();
    if (email.isEmpty || email == _lastOtpEmail) return;
    _otpTimer?.cancel();
    _otpTimer = Timer(const Duration(milliseconds: 800), () {
      _requestOtp();
    });
  }

  Future<void> _requestOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _otpInfo = tr(
          widget.lang,
          fr: 'Entrez votre email',
          ar: '\u0623\u062f\u062e\u0644 \u0627\u0644\u0628\u0631\u064a\u062f',
          en: 'Enter your email',
        );
      });
      return;
    }
    setState(() {
      _otpLoading = true;
      _otpInfo = null;
      _error = null;
    });
    try {
      final data = useLocal
          ? await localApi.requestOtp(email, purpose: 'reset')
          : jsonDecode(
                  (await http.post(
                    Uri.parse('$apiBase/auth/request-otp'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({'email': email, 'purpose': 'reset'}),
                  )).body,
                )
                as Map<String, dynamic>;
      if (data['ok'] == true) {
        _lastOtpEmail = email;
        setState(() {
          final codeText = data['code']?.toString();
          _otpInfo = tr(
            widget.lang,
            fr: codeText == null ? 'Code envoyé par email' : 'Code: $codeText',
            ar: codeText == null
                ? '\u062a\u0645 \u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u0631\u0645\u0632 \u0628\u0627\u0644\u0628\u0631\u064a\u062f'
                : '\u0627\u0644\u0631\u0645\u0632: $codeText',
            en: codeText == null ? 'Code sent by email' : 'Code: $codeText',
          );
        });
      } else {
        setState(() {
          _otpInfo = tr(
            widget.lang,
            fr: 'Email introuvable',
            ar: '\u0627\u0644\u0628\u0631\u064a\u062f \u063a\u064a\u0631 \u0645\u0648\u062c\u0648\u062f',
            en: 'Email not found',
          );
        });
      }
    } catch (_) {
      setState(() {
        _otpInfo = tr(
          widget.lang,
          fr: 'Impossible de se connecter',
          ar: '\u062a\u0639\u0630\u0631 \u0627\u0644\u0627\u062a\u0635\u0627\u0644',
          en: 'Connection failed',
        );
      });
    } finally {
      if (mounted) setState(() => _otpLoading = false);
    }
  }
}
