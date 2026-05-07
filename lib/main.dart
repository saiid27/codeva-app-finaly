import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'forgot_password_screen.dart';
import 'signup_screen.dart';
import 'widgets.dart';
import 'local_api.dart';

const String apiBase = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://codeva-backend-a2ny.onrender.com',
);
const bool useLocal = bool.fromEnvironment('USE_LOCAL_DB', defaultValue: false);
final double attendanceSiteLatitude =
    double.tryParse(
      const String.fromEnvironment(
        'ATTENDANCE_SITE_LAT',
        defaultValue: '18.0735',
      ),
    ) ??
    18.0735;
final double attendanceSiteLongitude =
    double.tryParse(
      const String.fromEnvironment(
        'ATTENDANCE_SITE_LNG',
        defaultValue: '-15.9582',
      ),
    ) ??
    -15.9582;
final double attendanceAllowedRadiusMeters =
    double.tryParse(
      const String.fromEnvironment('ATTENDANCE_RADIUS_M', defaultValue: '150'),
    ) ??
    150;
final LocalApi localApi = LocalApi.instance;
String? currentUserEmail;
String? currentUserRole;
final List<_LocationEntry> _locationEntries = [];

enum AppLang { ar, fr, en }

const Color whiteBg = Colors.white;

String tr(
  AppLang lang, {
  required String fr,
  required String ar,
  required String en,
}) {
  switch (lang) {
    case AppLang.ar:
      return ar;
    case AppLang.en:
      return en;
    case AppLang.fr:
    default:
      return fr;
  }
}

class _LocationEntry {
  const _LocationEntry({
    required this.email,
    required this.url,
    required this.createdAt,
  });

  final String email;
  final String url;
  final DateTime createdAt;
}

void main() {
  runApp(const PresenceApp());
}

class PresenceApp extends StatelessWidget {
  const PresenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Presence QR',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00B7FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  AppLang _lang = AppLang.fr;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;
  late final AnimationController _marqueeCtrl;
  late final AnimationController _blinkCtrl;
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _marqueeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _marqueeCtrl.dispose();
    _blinkCtrl.dispose();
    _shimmerCtrl.dispose();
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
            bottom: -200,
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
                        onPressed: () {},
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Spacer(),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),
                SizedBox(height: headerGap),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 3000),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, child) {
                    return Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, (1 - t) * 12),
                        child: child,
                      ),
                    );
                  },
                  child: AnimatedBuilder(
                    animation: _shimmerCtrl,
                    builder: (context, child) {
                      final t = _shimmerCtrl.value * 2 - 1; // -1 to 1
                      return Stack(
                        children: [
                          child!,
                          ShaderMask(
                            shaderCallback: (rect) {
                              return LinearGradient(
                                begin: Alignment(t - 0.6, 0),
                                end: Alignment(t + 0.6, 0),
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withOpacity(0.85),
                                  Colors.transparent,
                                ],
                                stops: const [0.2, 0.5, 0.8],
                              ).createShader(rect);
                            },
                            blendMode: BlendMode.srcATop,
                            child: child,
                          ),
                        ],
                      );
                    },
                    child: Text(
                      tr(
                        _lang,
                        fr: 'Presence QR System',
                        ar: '\u0646\u0638\u0627\u0645 \u0627\u0644\u062d\u0636\u0648\u0631 \u0628\u0627\u0644\u0631\u0645\u0632',
                        en: 'Presence QR System',
                      ),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: headerGap),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 3000),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, child) {
                    return Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, (1 - t) * 10),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    tr(
                      _lang,
                      fr: 'Attendance via QR code',
                      ar: '\u0627\u0644\u062d\u0636\u0648\u0631 \u0639\u0628\u0631 \u0631\u0645\u0632 QR',
                      en: 'Attendance via QR code',
                    ),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: Text(
                    tr(
                      _lang,
                      fr: 'Mode local',
                      ar: '\u0648\u0636\u0639 \u0645\u062d\u0644\u064a',
                      en: 'Local mode',
                    ),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: afterHeaderGap),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      0,
                      24,
                      MediaQuery.of(context).viewInsets.bottom + 16,
                    ),
                    child: Column(
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 3000),
                          curve: Curves.easeOutCubic,
                          builder: (context, t, child) {
                            return Opacity(
                              opacity: t,
                              child: Transform.translate(
                                offset: Offset(0, (1 - t) * 16),
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                            decoration: BoxDecoration(
                              color: card.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.22),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.28),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: accent,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      width: 140,
                                      height: 26,
                                      child: ClipRect(
                                        child: AnimatedBuilder(
                                          animation: _marqueeCtrl,
                                          builder: (context, child) {
                                            final t = _marqueeCtrl.value;
                                            final dx = 140 - (t * 200);
                                            return Transform.translate(
                                              offset: Offset(dx, 0),
                                              child: child,
                                            );
                                          },
                                          child: Text(
                                            tr(
                                              _lang,
                                              fr: 'Connexion',
                                              ar: '\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062f\u062e\u0648\u0644',
                                              en: 'Login',
                                            ),
                                            style: TextStyle(
                                              color: textLight,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    AnimatedBuilder(
                                      animation: _blinkCtrl,
                                      builder: (context, child) {
                                        return Opacity(
                                          opacity:
                                              0.3 + (_blinkCtrl.value * 0.7),
                                          child: child,
                                        );
                                      },
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF3B30),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFFFF3B30,
                                              ).withOpacity(0.6),
                                              blurRadius: 10,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 36),
                                LineInput(
                                  hint: tr(
                                    _lang,
                                    fr: 'Email',
                                    ar: '\u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a',
                                    en: 'Email',
                                  ),
                                  icon: Icons.mail_outline,
                                  accent: textLight,
                                  fillColor: field,
                                  controller: _emailController,
                                ),
                                const SizedBox(height: 16),
                                LineInput(
                                  hint: tr(
                                    _lang,
                                    fr: 'Mot de passe',
                                    ar: '\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631',
                                    en: 'Password',
                                  ),
                                  icon: Icons.lock_outline,
                                  accent: textLight,
                                  fillColor: field,
                                  obscureText: _obscurePassword,
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: textLight.withOpacity(0.9),
                                    ),
                                  ),
                                  controller: _passwordController,
                                ),
                                const SizedBox(height: 14),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ForgotPasswordScreen(lang: _lang),
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: textLight,
                                    ),
                                    child: Text(
                                      tr(
                                        _lang,
                                        fr: 'Mot de passe oublié ? ',
                                        ar: '\u0646\u0633\u064a\u062a \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631\u061f',
                                        en: 'Forgot password?',
                                      ),
                                    ),
                                  ),
                                ),
                                if (_error != null) ...[
                                  Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                AnimatedContainer(
                                  width: double.infinity,
                                  height: 46,
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOut,
                                  child: ElevatedButton(
                                    onPressed: _loading
                                        ? null
                                        : () => _doLogin(),
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: const Color(0xFF255B48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      elevation: 6,
                                      shadowColor: Colors.black.withOpacity(
                                        0.3,
                                      ),
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
                                              _lang,
                                              fr: 'Connexion',
                                              ar: '\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062f\u062e\u0648\u0644',
                                              en: 'Login',
                                            ),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      tr(
                                        _lang,
                                        fr: 'Pas de compte ? ',
                                        ar: '\u0644\u0627 \u062a\u0645\u0644\u0643 \u062d\u0633\u0627\u0628\u0627\u064b\u061f',
                                        en: 'No account?',
                                      ),
                                      style: TextStyle(
                                        color: textLight.withOpacity(0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                SignupScreen(lang: _lang),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text(
                                        tr(
                                          _lang,
                                          fr: 'Créer un compte',
                                          ar: '\u0625\u0646\u0634\u0627\u0621 \u062d\u0633\u0627\u0628',
                                          en: 'Create account',
                                        ),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  tr(
                                    _lang,
                                    fr: 'Compte en attente de validation',
                                    ar: '\u0627\u0644\u062d\u0633\u0627\u0628 \u0642\u064a\u062f \u0627\u0644\u062a\u062d\u0642\u0642',
                                    en: 'Account pending approval',
                                  ),
                                  style: TextStyle(
                                    color: textLight.withOpacity(0.65),
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _LangChip(
                                label: 'AR',
                                selected: _lang == AppLang.ar,
                                onTap: () => setState(() => _lang = AppLang.ar),
                              ),
                              const SizedBox(width: 10),
                              _LangChip(
                                label: 'FR',
                                selected: _lang == AppLang.fr,
                                onTap: () => setState(() => _lang = AppLang.fr),
                              ),
                              const SizedBox(width: 10),
                              _LangChip(
                                label: 'EN',
                                selected: _lang == AppLang.en,
                                onTap: () => setState(() => _lang = AppLang.en),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
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

  Future<void> _doLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Entrez email et mot de passe';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = useLocal
          ? await localApi.login(email: email, password: password, otp: '')
          : jsonDecode(
                  (await http.post(
                    Uri.parse('$apiBase/auth/login'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({'email': email, 'password': password}),
                  )).body,
                )
                as Map<String, dynamic>;

      if (data['ok'] != true) {
        final reason = data['reason']?.toString() ?? 'invalid';
        final message = _mapReason(reason);
        setState(() => _error = message);
        return;
      }

      final user = data['user'] as Map<String, dynamic>;
      final role = user['role']?.toString() ?? 'worker';
      currentUserEmail = user['email']?.toString();
      currentUserRole = role;
      if (!mounted) return;
      if (role == 'admin') {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => AdminDashboard(lang: _lang)));
      } else {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => UserHome(lang: _lang)));
      }
    } catch (_) {
      setState(() {
        _error = 'Impossible de se connecter au serveur';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _mapReason(String reason) {
    switch (reason) {
      case 'pending':
        return 'Compte en attente';
      case 'rejected':
        return 'Compte refusé';
      case 'invalid':
        return 'Identifiants invalides';
      case 'not_found':
      default:
        return 'Utilisateur introuvable';
    }
  }
}

class UserHome extends StatefulWidget {
  const UserHome({super.key, required this.lang});

  final AppLang lang;

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  final List<_AttendanceItem> _records = [];
  bool _attendanceLoading = false;

  @override
  Widget build(BuildContext context) {
    const bg = Colors.white;
    final lang = widget.lang;
    const card = Color(0xFF1B2636);
    final isAr = lang == AppLang.ar;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: bg,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        backgroundColor: bg,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(
          tr(
            lang,
            fr: 'Accueil',
            ar: '\u0627\u0644\u0631\u0626\u064a\u0633\u064a\u0629',
            en: 'Home',
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _attendanceLoading
                    ? null
                    : () => _registerAttendanceByLocation(isAr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF18C5C5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                ),
                icon: _attendanceLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  tr(
                    lang,
                    fr: 'Enregistrer la presence',
                    ar: '\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062d\u0636\u0648\u0631',
                    en: 'Register attendance',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _attendanceLoading
                    ? null
                    : () async {
                        final token = await Navigator.of(context).push<String>(
                          MaterialPageRoute(
                            builder: (_) => ScanScreen(lang: lang),
                          ),
                        );
                        if (token == null || token.isEmpty) return;
                        await _verifyAttendance(token, isAr);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF255B48),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                ),
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(
                  tr(
                    lang,
                    fr: 'Scanner QR code',
                    ar: '\u0645\u0633\u062d QR code',
                    en: 'Scan QR code',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                tr(
                  lang,
                  fr: 'Historique',
                  ar: '\u0627\u0644\u0633\u062c\u0644',
                  en: 'History',
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _records.isEmpty
                  ? Center(
                      child: Text(
                        tr(
                          lang,
                          fr: tr(
                            lang,
                            fr: 'Aucun enregistrement',
                            ar: '\u0644\u0627 \u0633\u062c\u0644\u0627\u062a',
                            en: 'No records',
                          ),
                          ar: '\u0644\u0627 \u0633\u062c\u0644\u0627\u062a',
                          en: 'No records',
                        ),
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _records.length,
                      itemBuilder: (context, index) {
                        final item = _records[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          color: card,
                          child: Row(
                            children: [
                              Icon(
                                item.verified
                                    ? Icons.verified
                                    : Icons.error_outline,
                                color: item.verified
                                    ? Colors.greenAccent
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.message ?? 'Présence vérifiée',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              Text(
                                item.time,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _registerAttendanceByLocation(bool isAr) async {
    if (currentUserEmail == null) {
      _addAttendanceRecord(
        verified: false,
        message: 'Utilisateur inconnu',
        time: '--:--',
      );
      return;
    }

    setState(() => _attendanceLoading = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!kIsWeb) {
          await Geolocator.openLocationSettings();
        }
        _addAttendanceRecord(
          verified: false,
          message: isAr
              ? '\u0641\u0639\u0644 GPS \u062b\u0645 \u0623\u0639\u062f \u0627\u0644\u0645\u062d\u0627\u0648\u0644\u0629'
              : 'Activez le GPS puis reessayez',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (permission == LocationPermission.deniedForever && !kIsWeb) {
          await Geolocator.openAppSettings();
        }
        _addAttendanceRecord(
          verified: false,
          message: isAr
              ? '\u0644\u0645 \u064a\u062a\u0645 \u0645\u0646\u062d \u0625\u0630\u0646 \u0627\u0644\u0645\u0648\u0642\u0639'
              : 'Permission de localisation refusee',
        );
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 25),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }
      if (position == null) {
        _addAttendanceRecord(
          verified: false,
          message: isAr
              ? '\u062a\u0639\u0630\u0631 GPS: \u0627\u062e\u0631\u062c \u0644\u0645\u0643\u0627\u0646 \u0645\u0641\u062a\u0648\u062d'
              : 'GPS indisponible: essayez en zone ouverte',
        );
        return;
      }
      final data = useLocal
          ? await _recordLocalLocationAttendance(position)
          : jsonDecode(
                  (await http.post(
                    Uri.parse('$apiBase/attendance/location'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'email': currentUserEmail,
                      'latitude': position.latitude,
                      'longitude': position.longitude,
                    }),
                  )).body,
                )
                as Map<String, dynamic>;

      final verified = data['verified'] == true;
      final already = data['already'] == true;
      final distanceMeters = double.tryParse(
        (data['distanceMeters'] ?? '').toString(),
      );
      final allowedRadius = double.tryParse(
        (data['allowedRadiusMeters'] ?? attendanceAllowedRadiusMeters)
            .toString(),
      );
      _addAttendanceRecord(
        verified: verified,
        message: already
            ? (isAr
                  ? '\u0645\u0633\u062c\u0644 \u0645\u0633\u0628\u0642\u0627'
                  : 'Deja enregistre')
            : verified
            ? (isAr
                  ? '\u062a\u0645 \u0627\u0644\u062a\u062d\u0642\u0642 \u0645\u0646 \u0627\u0644\u062d\u0636\u0648\u0631'
                  : 'Presence verifiee')
            : (isAr
                      ? '\u0641\u0634\u0644 \u0627\u0644\u062a\u062d\u0642\u0642: \u062e\u0627\u0631\u062c \u0627\u0644\u0646\u0637\u0627\u0642'
                      : 'Verification refusee: hors zone') +
                  (distanceMeters == null || allowedRadius == null
                      ? ''
                      : ' (${distanceMeters.toStringAsFixed(0)}m / ${allowedRadius.toStringAsFixed(0)}m)'),
      );
    } catch (error) {
      _addAttendanceRecord(
        verified: false,
        message: isAr
            ? '\u062a\u0639\u0630\u0631 \u062a\u062d\u062f\u064a\u062f \u0627\u0644\u0645\u0648\u0642\u0639'
            : 'Erreur localisation ou connexion',
      );
    } finally {
      if (mounted) setState(() => _attendanceLoading = false);
    }
  }

  Future<Map<String, dynamic>> _recordLocalLocationAttendance(
    Position position,
  ) async {
    final distance = Geolocator.distanceBetween(
      attendanceSiteLatitude,
      attendanceSiteLongitude,
      position.latitude,
      position.longitude,
    );
    final verified = distance <= attendanceAllowedRadiusMeters;
    final reason = verified ? 'verified' : 'outside_area';
    final data = await localApi.recordLocationAttendance(
      email: currentUserEmail!,
      verified: verified,
      latitude: position.latitude,
      longitude: position.longitude,
      distanceMeters: distance,
      reason: reason,
    );
    data['verified'] = verified;
    data['distanceMeters'] = distance;
    data['allowedRadiusMeters'] = attendanceAllowedRadiusMeters;
    return data;
  }

  void _addAttendanceRecord({
    required bool verified,
    required String message,
    String? time,
  }) {
    final now = DateTime.now();
    if (!mounted) return;
    setState(() {
      _records.insert(
        0,
        _AttendanceItem(
          name: 'Location',
          status: verified ? 'present' : 'rejected',
          time:
              time ??
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
          verified: verified,
          message: message,
        ),
      );
    });
  }

  Future<void> _verifyAttendance(String token, bool isAr) async {
    if (currentUserEmail == null) {
      setState(() {
        _records.insert(
          0,
          _AttendanceItem(
            name: 'Scan',
            status: 'rejected',
            time: '--:--',
            verified: false,
            message: 'Utilisateur inconnu',
          ),
        );
      });
      return;
    }
    try {
      final data = useLocal
          ? await localApi.scanAttendance(
              email: currentUserEmail!,
              token: token,
            )
          : jsonDecode(
                  (await http.post(
                    Uri.parse('$apiBase/attendance/scan'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'email': currentUserEmail,
                      'token': token,
                    }),
                  )).body,
                )
                as Map<String, dynamic>;
      final now = DateTime.now();
      if (data['ok'] == true) {
        final already = data['already'] == true;
        setState(() {
          _records.insert(
            0,
            _AttendanceItem(
              name: 'Scan',
              status: 'present',
              time:
                  '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
              verified: true,
              message: already ? ('Déjà enregistré') : ('Présence vérifiée'),
            ),
          );
        });
      } else {
        final reason = data['reason']?.toString() ?? 'invalid';
        final msg = _mapScanReason(reason, isAr);
        setState(() {
          _records.insert(
            0,
            _AttendanceItem(
              name: 'Scan',
              status: 'rejected',
              time:
                  '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
              verified: false,
              message: msg,
            ),
          );
        });
      }
    } catch (_) {
      setState(() {
        _records.insert(
          0,
          _AttendanceItem(
            name: 'Scan',
            status: 'rejected',
            time: '--:--',
            verified: false,
            message: 'Connexion impossible',
          ),
        );
      });
    }
  }

  Future<void> _showLocationDialog() async {
    final lang = widget.lang;
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            tr(
              lang,
              fr: 'Lien Google Maps',
              ar: '\u0631\u0627\u0628\u0637 Google Maps',
              en: 'Google Maps link',
            ),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: tr(
                lang,
                fr: 'https://maps.google.com/...',
                ar: 'https://maps.google.com/...',
                en: 'https://maps.google.com/...',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                tr(
                  lang,
                  fr: 'Annuler',
                  ar: '\u0625\u0644\u063a\u0627\u0621',
                  en: 'Cancel',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: Text(
                tr(
                  lang,
                  fr: 'Envoyer',
                  ar: '\u0625\u0631\u0633\u0627\u0644',
                  en: 'Send',
                ),
              ),
            ),
          ],
        );
      },
    );
    if (url == null || url.isEmpty) return;
    final parsed = Uri.tryParse(url);
    if (parsed == null ||
        !(parsed.isScheme('http') || parsed.isScheme('https'))) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              lang,
              fr: 'Lien invalide',
              ar: '\u0631\u0627\u0628\u0637 \u063a\u064a\u0631 \u0635\u0627\u0644\u062d',
              en: 'Invalid link',
            ),
          ),
        ),
      );
      return;
    }
    _locationEntries.insert(
      0,
      _LocationEntry(
        email: currentUserEmail ?? 'Inconnu',
        url: url,
        createdAt: DateTime.now(),
      ),
    );
    if (useLocal) {
      await localApi.addLocation(currentUserEmail ?? 'Inconnu', url);
    } else {
      await http.post(
        Uri.parse('$apiBase/locations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': currentUserEmail ?? 'Inconnu', 'url': url}),
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            lang,
            fr: 'Localisation envoyée',
            ar: '\u062a\u0645 \u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u0645\u0648\u0642\u0639',
            en: 'Location sent',
          ),
        ),
      ),
    );
  }

  String _mapScanReason(String reason, bool isAr) {
    switch (reason) {
      case 'pending':
        return 'Compte en attente';
      case 'rejected':
        return 'Compte refusé';
      case 'invalid_qr':
        return 'QR invalide';
      case 'not_found':
      default:
        return 'Utilisateur introuvable';
    }
  }
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key, required this.lang});

  final AppLang lang;

  @override
  Widget build(BuildContext context) {
    const bgTop = Color(0xFF4C7B61);
    const bgBottom = Color(0xFF3E6F56);
    const bgLight = Color(0xFFF4F5F3);
    final lang = this.lang;
    final size = MediaQuery.of(context).size;
    final sectionWidth = size.width * 0.9;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: bgLight,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        backgroundColor: bgTop,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text(
            tr(
              lang,
              fr: 'Dashboard Admin',
              ar: '\u0644\u0648\u062d\u0629 \u0627\u0644\u062a\u062d\u0643\u0645',
              en: 'Admin Dashboard',
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 28, 0, 24),
        child: Center(
          child: SizedBox(
            width: sectionWidth,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE1E5E0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AdminCard(
                    title: tr(
                      lang,
                      fr: 'Demandes',
                      ar: 'الطلبات',
                      en: 'Requests',
                    ),
                    subtitle: tr(
                      lang,
                      fr: 'Valider',
                      ar: 'اعتماد',
                      en: 'Review',
                    ),
                    icon: Icons.person_add_alt_1,
                    color: const Color(0xFF3B82F6),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminRequestsScreen(lang: lang),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _AdminCard(
                    title: tr(
                      lang,
                      fr: 'Présences',
                      ar: 'الحضور',
                      en: 'Attendance',
                    ),
                    subtitle: tr(lang, fr: 'Voir', ar: 'عرض', en: 'View'),
                    icon: Icons.list_alt,
                    color: const Color(0xFF22C55E),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminAttendanceScreen(lang: lang),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _AdminCard(
                    title: tr(
                      lang,
                      fr: 'QR du jour',
                      ar: 'رمز اليوم',
                      en: 'Today QR',
                    ),
                    subtitle: tr(
                      lang,
                      fr: 'Partager',
                      ar: 'مشاركة',
                      en: 'Share',
                    ),
                    icon: Icons.qr_code_2,
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminQrScreen(lang: lang),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _AdminCard(
                    title: tr(
                      lang,
                      fr: 'Utilisateurs',
                      ar: 'المستخدمون',
                      en: 'Users',
                    ),
                    subtitle: tr(lang, fr: 'Liste', ar: 'قائمة', en: 'List'),
                    icon: Icons.people_alt,
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminRequestsScreen(lang: lang),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _AdminCard(
                    title: tr(
                      lang,
                      fr: 'Localisations',
                      ar: 'المواقع',
                      en: 'Locations',
                    ),
                    subtitle: tr(lang, fr: 'Voir', ar: 'عرض', en: 'View'),
                    icon: Icons.location_on,
                    color: const Color(0xFF06B6D4),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminLocationsScreen(lang: lang),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _AdminCard(
                    title: tr(
                      lang,
                      fr: 'Site entreprise',
                      ar: '\u0645\u0648\u0642\u0639 \u0627\u0644\u0634\u0631\u0643\u0629',
                      en: 'Company site',
                    ),
                    subtitle: tr(
                      lang,
                      fr: 'Configurer',
                      ar: '\u0625\u0639\u062f\u0627\u062f',
                      en: 'Configure',
                    ),
                    icon: Icons.apartment,
                    color: const Color(0xFF0F766E),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              AdminCompanyLocationScreen(lang: lang),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _AdminCard(
                    title: tr(
                      lang,
                      fr: 'Rapports',
                      ar: 'التقارير',
                      en: 'Reports',
                    ),
                    subtitle: tr(
                      lang,
                      fr: 'Mensuel',
                      ar: 'شهري',
                      en: 'Monthly',
                    ),
                    icon: Icons.table_chart,
                    color: const Color(0xFF14B8A6),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminReportsScreen(lang: lang),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  _AdminCard(
                    title: tr(
                      lang,
                      fr: 'Statistiques',
                      ar: 'إحصائيات',
                      en: 'Statistics',
                    ),
                    subtitle: tr(lang, fr: 'Vue', ar: 'عرض', en: 'View'),
                    icon: Icons.bar_chart,
                    color: const Color(0xFF22C55E),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminStatsScreen(lang: lang),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.color = const Color(0xFF1D3B66),
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key, required this.lang});

  final AppLang lang;

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
  String _search = '';
  bool _loadingUsers = false;
  final List<_AccountItem> _pending = [];
  final List<_AccountItem> _rejected = [];
  final List<_AccountItem> _approved = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Colors.white;
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
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(
          tr(
            lang,
            fr: 'Demandes',
            ar: '\u0627\u0644\u0637\u0644\u0628\u0627\u062a',
            en: 'Requests',
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _SearchBar(
              hint: tr(
                lang,
                fr: 'Rechercher nom ou email',
                ar: '\u0627\u0628\u062d\u062b \u0628\u0627\u0644\u0627\u0633\u0645 \u0623\u0648 \u0627\u0644\u0628\u0631\u064a\u062f',
                en: 'Search name or email',
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _PendingList(
                lang: widget.lang,
                pending: _pending,
                rejected: _rejected,
                approved: _approved,
                query: _search,
                onApprove: (item) => _approveUser(item.id),
                onReject: (item) => _rejectUser(item.id),
                onAdd: () async {
                  final result = await showDialog<_AccountItem>(
                    context: context,
                    builder: (_) => _AddAccountDialog(lang: widget.lang),
                  );
                  if (result == null) return;
                  await _createUser(result);
                },
              ),
            ),
            if (_loadingUsers)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Mise à jour...',
                  style: TextStyle(
                    color: const Color(0xFF11402E).withOpacity(0.6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final pending = await _fetchByStatus('pending');
      final approved = await _fetchByStatus('approved');
      final rejected = await _fetchByStatus('rejected');
      if (!mounted) return;
      setState(() {
        _pending
          ..clear()
          ..addAll(pending);
        _approved
          ..clear()
          ..addAll(approved);
        _rejected
          ..clear()
          ..addAll(rejected);
      });
    } finally {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  Future<List<_AccountItem>> _fetchByStatus(String status) async {
    final list = useLocal
        ? await localApi.listUsers(status)
        : (jsonDecode(
                    (await http.get(
                      Uri.parse('$apiBase/admin/users?status=$status'),
                    )).body,
                  )['users']
                  as List<dynamic>)
              .cast<Map<String, dynamic>>();
    return list
        .map(
          (u) => _AccountItem(
            id: u['id'] as int,
            name: (u['fullName'] ?? '').toString(),
            email: (u['email'] ?? '').toString(),
            phone: (u['phone'] ?? '').toString(),
            job: (u['jobTitle'] ?? '').toString(),
            role: (u['role'] ?? 'worker').toString(),
          ),
        )
        .toList();
  }

  Future<void> _approveUser(int id) async {
    if (useLocal) {
      await localApi.approveUser(id);
    } else {
      await http.post(Uri.parse('$apiBase/admin/users/$id/approve'));
    }
    await _fetchUsers();
  }

  Future<void> _rejectUser(int id) async {
    if (useLocal) {
      await localApi.rejectUser(id);
    } else {
      await http.post(Uri.parse('$apiBase/admin/users/$id/reject'));
    }
    await _fetchUsers();
  }

  Future<void> _createUser(_AccountItem item) async {
    if (useLocal) {
      await localApi.createUser(
        fullName: item.name,
        email: item.email,
        phone: item.phone,
        jobTitle: item.job,
        role: item.role,
      );
    } else {
      await http.post(
        Uri.parse('$apiBase/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': item.name,
          'email': item.email,
          'password': 'Temp1234',
          'phone': item.phone,
          'jobTitle': item.job,
          'role': item.role,
        }),
      );
    }
    await _fetchUsers();
  }
}

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key, required this.lang});

  final AppLang lang;

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  String _selectedMonth = _monthToken(DateTime.now());
  String _selectedGroup = 'Tous';
  bool _loading = false;
  List<_AttendanceRecord> _items = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Colors.white;
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
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(
          tr(
            lang,
            fr: 'Liste des présences',
            ar: '\u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u062d\u0636\u0648\u0631',
            en: 'Attendance list',
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _FilterChipBox(
                    label: tr(
                      lang,
                      fr: 'Mois',
                      ar: '\u0627\u0644\u0634\u0647\u0631',
                      en: 'Month',
                    ),
                    child: DropdownButton<String>(
                      value: _selectedMonth,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      items: _monthOptions()
                          .map(
                            (month) => DropdownMenuItem(
                              value: month,
                              child: Text(month),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedMonth = value);
                        _fetch();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FilterChipBox(
                    label: tr(
                      lang,
                      fr: 'Groupe',
                      ar: '\u0627\u0644\u0645\u062c\u0645\u0648\u0639\u0629',
                      en: 'Group',
                    ),
                    child: DropdownButton<String>(
                      value: _selectedGroup,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      items: [
                        DropdownMenuItem(
                          value: 'Tous',
                          child: Text(
                            tr(
                              lang,
                              fr: 'Tous',
                              ar: '\u0627\u0644\u0643\u0644',
                              en: 'All',
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Groupe A',
                          child: Text(
                            tr(
                              lang,
                              fr: 'Groupe A',
                              ar: '\u0645\u062c\u0645\u0648\u0639\u0629 A',
                              en: 'Group A',
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Groupe B',
                          child: Text(
                            tr(
                              lang,
                              fr: 'Groupe B',
                              ar: '\u0645\u062c\u0645\u0648\u0639\u0629 B',
                              en: 'Group B',
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedGroup = value);
                        _fetch();
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                  ? Center(
                      child: Text(
                        tr(
                          lang,
                          fr: 'Aucun enregistrement',
                          ar: '\u0644\u0627 \u0633\u062c\u0644\u0627\u062a',
                          en: 'No records',
                        ),
                        style: const TextStyle(color: Colors.black54),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final statusText = item.status == 'present'
                            ? tr(
                                lang,
                                fr: 'Présent',
                                ar: '\u062d\u0627\u0636\u0631',
                                en: 'Verified',
                              )
                            : tr(
                                lang,
                                fr: 'Absent',
                                ar: '\u063a\u0627\u0626\u0628',
                                en: 'Not verified',
                              );
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE3E6EA)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.status == 'present'
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: item.status == 'present'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${tr(lang, fr: 'Groupe', ar: '\u0627\u0644\u0645\u062c\u0645\u0648\u0639\u0629', en: 'Group')} ${item.group} • ${item.date}',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: item.status == 'present'
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final list = useLocal
          ? await localApi.listAttendance(
              month: _selectedMonth,
              group: _selectedGroup,
            )
          : (jsonDecode(
                          (await http.get(
                            Uri.parse(
                              '$apiBase/attendance/list?month=$_selectedMonth&group=${_selectedGroup == 'Tous' ? '' : _selectedGroup}',
                            ),
                          )).body,
                        )['items']
                        as List<dynamic>? ??
                    [])
                .cast<Map<String, dynamic>>();
      final items = list.map((e) {
        return _AttendanceRecord(
          name: (e['name'] ?? e['full_name'] ?? '').toString(),
          group: (e['group'] ?? e['job_title'] ?? '').toString(),
          date: (e['date'] ?? e['attend_date'] ?? '').toString(),
          status: (e['status'] ?? '').toString(),
          distanceMeters: double.tryParse((e['distance_m'] ?? '').toString()),
          verificationReason: (e['verification_reason'] ?? '').toString(),
        );
      }).toList();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (_) {
      if (!mounted) return;
      setState(() => _items = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static String _monthToken(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';
  }

  List<String> _monthOptions() {
    final now = DateTime.now();
    final previous = DateTime(now.year, now.month - 1);
    return {
      _selectedMonth,
      _monthToken(now),
      _monthToken(previous),
      '2026-04',
      '2026-03',
    }.toList();
  }
}

class AdminLocationsScreen extends StatefulWidget {
  const AdminLocationsScreen({super.key, required this.lang});

  final AppLang lang;

  @override
  State<AdminLocationsScreen> createState() => _AdminLocationsScreenState();
}

class _AdminLocationsScreenState extends State<AdminLocationsScreen> {
  bool _loading = true;
  List<_LocationEntry> _items = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      if (useLocal) {
        final rows = await localApi.listLocations();
        _items = rows
            .map(
              (row) => _LocationEntry(
                email: (row['email'] ?? '').toString(),
                url: (row['url'] ?? '').toString(),
                createdAt:
                    DateTime.tryParse((row['created_at'] ?? '').toString()) ??
                    DateTime.now(),
              ),
            )
            .toList();
      } else {
        final data =
            jsonDecode((await http.get(Uri.parse('$apiBase/locations'))).body)
                as Map<String, dynamic>;
        final rows = (data['items'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        _items = rows
            .map(
              (row) => _LocationEntry(
                email: (row['email'] ?? '').toString(),
                url: (row['url'] ?? '').toString(),
                createdAt:
                    DateTime.tryParse((row['created_at'] ?? '').toString()) ??
                    DateTime.now(),
              ),
            )
            .toList();
      }
    } catch (_) {
      _items = List<_LocationEntry>.from(_locationEntries);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Localisations'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(onPressed: _fetch, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(
              child: Text(
                'Aucune localisation',
                style: TextStyle(color: Colors.black54),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _items[index];
                final time =
                    '${item.createdAt.day.toString().padLeft(2, '0')}/'
                    '${item.createdAt.month.toString().padLeft(2, '0')} '
                    '${item.createdAt.hour.toString().padLeft(2, '0')}:'
                    '${item.createdAt.minute.toString().padLeft(2, '0')}';
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F6F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE1E7E5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.email,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.url,
                        style: const TextStyle(color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        time,
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class AdminStatsScreen extends StatelessWidget {
  const AdminStatsScreen({super.key, required this.lang});

  final AppLang lang;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Statistiques'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    title: 'Présents',
                    value: '22',
                    color: const Color(0xFF22C55E),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    title: 'Absents',
                    value: '4',
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    title: 'Taux de présence',
                    value: '84%',
                    color: const Color(0xFF0EA5E9),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    title: 'En retard',
                    value: '3',
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AdminCompanyLocationScreen extends StatefulWidget {
  const AdminCompanyLocationScreen({super.key, required this.lang});

  final AppLang lang;

  @override
  State<AdminCompanyLocationScreen> createState() =>
      _AdminCompanyLocationScreenState();
}

class _AdminCompanyLocationScreenState
    extends State<AdminCompanyLocationScreen> {
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _radiusController = TextEditingController(text: '150');
  bool _loading = true;
  bool _saving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data =
          jsonDecode(
                (await http.get(Uri.parse('$apiBase/company-location'))).body,
              )
              as Map<String, dynamic>;
      final location = (data['location'] as Map<String, dynamic>? ?? {});
      _latController.text = (location['latitude'] ?? '').toString();
      _lngController.text = (location['longitude'] ?? '').toString();
      _radiusController.text = (location['radiusMeters'] ?? '150').toString();
    } catch (_) {
      _message = 'Impossible de charger';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _useCurrentPosition() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _message = 'Permission de localisation refusee');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _latController.text = position.latitude.toStringAsFixed(7);
      _lngController.text = position.longitude.toStringAsFixed(7);
      setState(() => _message = 'Position actuelle chargee');
    } catch (_) {
      setState(() => _message = 'Impossible de determiner la position');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    final latitude = double.tryParse(_latController.text.trim());
    final longitude = double.tryParse(_lngController.text.trim());
    final radius = double.tryParse(_radiusController.text.trim());
    if (latitude == null ||
        longitude == null ||
        radius == null ||
        radius <= 0) {
      setState(() => _message = 'Valeurs invalides');
      return;
    }
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final response = await http.put(
        Uri.parse('$apiBase/company-location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'radiusMeters': radius,
        }),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 400 || data['ok'] != true) {
        setState(() => _message = 'Enregistrement refuse');
        return;
      }
      setState(() => _message = 'Site entreprise enregistre');
    } catch (_) {
      setState(() => _message = 'Connexion impossible');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(
          tr(
            lang,
            fr: 'Site entreprise',
            ar: '\u0645\u0648\u0642\u0639 \u0627\u0644\u0634\u0631\u0643\u0629',
            en: 'Company site',
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _latController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _lngController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _radiusController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Rayon autorise en metres',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _useCurrentPosition,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Utiliser ma position actuelle'),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Enregistrer'),
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _message!,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ],
            ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key, required this.lang});

  final AppLang lang;

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  bool _loading = true;
  List<_MonthlyReportRow> _items = [];
  String _selectedMonth = '2026-04';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final list = useLocal
          ? await localApi.monthlyReport(month: _selectedMonth)
          : (jsonDecode(
                          (await http.get(
                            Uri.parse(
                              '$apiBase/attendance/report?month=$_selectedMonth',
                            ),
                          )).body,
                        )['items']
                        as List<dynamic>? ??
                    [])
                .cast<Map<String, dynamic>>();
      final rows = list
          .map(
            (e) => _MonthlyReportRow(
              name: (e['name'] ?? e['full_name'] ?? '').toString(),
              present: int.tryParse(e['present']?.toString() ?? '0') ?? 0,
              absent: int.tryParse(e['absent']?.toString() ?? '0') ?? 0,
            ),
          )
          .toList();
      if (!mounted) return;
      setState(() => _items = rows);
    } catch (_) {
      if (!mounted) return;
      setState(() => _items = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final header = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE1E4E8)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              tr(lang, fr: 'Nom', ar: 'الاسم', en: 'Name'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              tr(lang, fr: 'Présent', ar: 'حاضر', en: 'Present'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              tr(lang, fr: 'Absent', ar: 'غائب', en: 'Absent'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          tr(
            lang,
            fr: 'Rapport mensuel',
            ar: 'التقرير الشهري',
            en: 'Monthly report',
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE6EBEF)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedMonth,
                      decoration: InputDecoration(
                        labelText: tr(
                          lang,
                          fr: 'Mois',
                          ar: 'الشهر',
                          en: 'Month',
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: '2026-04',
                          child: Text(
                            tr(
                              lang,
                              fr: 'Avril 2026',
                              ar: '\u0623\u0628\u0631\u064a\u0644 2026',
                              en: 'April 2026',
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: '2026-03',
                          child: Text(
                            tr(
                              lang,
                              fr: 'Mars 2026',
                              ar: '\u0645\u0627\u0631\u0633 2026',
                              en: 'March 2026',
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _selectedMonth = v);
                        _fetch();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _fetch,
                    icon: const Icon(Icons.refresh),
                    tooltip: tr(
                      lang,
                      fr: 'Actualiser',
                      ar: 'تحديث',
                      en: 'Refresh',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            header,
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Column(
                      children: _items.isEmpty
                          ? [
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  tr(
                                    lang,
                                    fr: 'Aucun enregistrement',
                                    ar: 'لا سجلات',
                                    en: 'No records',
                                  ),
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ),
                            ]
                          : _items
                                .map((e) => _ReportRowTile(item: e, lang: lang))
                                .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyReportRow {
  const _MonthlyReportRow({
    required this.name,
    required this.present,
    required this.absent,
  });

  final String name;
  final int present;
  final int absent;
}

class _ReportRowTile extends StatelessWidget {
  const _ReportRowTile({required this.item, required this.lang});

  final _MonthlyReportRow item;
  final AppLang lang;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final text = tr(
          lang,
          fr: '${item.name} • ${item.present} présent • ${item.absent} absent',
          ar: '${item.name} • ${item.present} حاضر • ${item.absent} غائب',
          en: '${item.name} • ${item.present} present • ${item.absent} absent',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(text),
            duration: const Duration(milliseconds: 900),
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                item.present.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.green),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                item.absent.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminQrScreen extends StatefulWidget {
  const AdminQrScreen({super.key, required this.lang});

  final AppLang lang;

  @override
  State<AdminQrScreen> createState() => _AdminQrScreenState();
}

class _AdminQrScreenState extends State<AdminQrScreen> {
  String? _token;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFEAF4FF);
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
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text('QR du jour'),
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator(color: Color(0xFF18C5C5))
            : _token == null
            ? Text(
                'Impossible de charger le QR',
                style: const TextStyle(color: Colors.black54),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(12),
                    child: QrImageView(data: _token!, size: 220),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _token!,
                    style: TextStyle(color: Colors.white.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _token!));
                        },
                        child: Text('Copier'),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: _shareWhatsapp,
                        child: Text('WhatsApp'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = useLocal
          ? await localApi.qrToday()
          : jsonDecode((await http.get(Uri.parse('$apiBase/qr/today'))).body)
                as Map<String, dynamic>;
      setState(() => _token = data['token']?.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _shareWhatsapp() async {
    if (_token == null) return;
    final text = Uri.encodeComponent('QR: $_token');
    final url = Uri.parse('https://wa.me/?text=$text');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, required this.lang});

  final AppLang lang;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    const bg = Colors.white;
    final lang = widget.lang;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: bg,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(
          tr(
            lang,
            fr: 'Scanner',
            ar: '\u0627\u0644\u0645\u0627\u0633\u062d',
            en: 'Scanner',
          ),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_scanned) return;
              final code = capture.barcodes.first.rawValue;
              if (code == null) return;
              _scanned = true;
              Navigator.of(context).pop(code);
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.black.withOpacity(0.5),
              child: Text(
                tr(
                  lang,
                  fr: 'Placez le code dans le cadre',
                  ar: '\u0636\u0639 \u0627\u0644\u0631\u0645\u0632 \u062f\u0627\u062e\u0644 \u0627\u0644\u0625\u0637\u0627\u0631',
                  en: 'Place the code inside the frame',
                ),
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.hint, required this.onChanged});

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F7FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCFEAF4)),
      ),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.black45),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF3CC7E6)),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _PendingList extends StatelessWidget {
  const _PendingList({
    required this.lang,
    required this.pending,
    required this.rejected,
    required this.approved,
    required this.query,
    required this.onApprove,
    required this.onReject,
    required this.onAdd,
  });

  final AppLang lang;
  final List<_AccountItem> pending;
  final List<_AccountItem> rejected;
  final List<_AccountItem> approved;
  final String query;
  final ValueChanged<_AccountItem> onApprove;
  final ValueChanged<_AccountItem> onReject;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final isAr = lang == AppLang.ar;
    final q = query.trim().toLowerCase();
    List<_AccountItem> filter(List<_AccountItem> items) {
      if (q.isEmpty) return items;
      return items
          .where(
            (item) =>
                item.name.toLowerCase().contains(q) ||
                item.email.toLowerCase().contains(q),
          )
          .toList();
    }

    final pendingFiltered = filter(pending);
    final approvedFiltered = filter(approved);
    final rejectedFiltered = filter(rejected);

    return ListView(
      children: [
        Row(
          children: [
            Text(
              tr(
                lang,
                fr: 'En attente',
                ar: '\u0642\u064a\u062f \u0627\u0644\u0627\u0646\u062a\u0638\u0627\u0631',
                en: 'Pending',
              ),
              style: const TextStyle(
                color: Color(0xFF2A6F86),
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onAdd,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2FAAD2),
              ),
              child: Text(
                tr(
                  lang,
                  fr: 'Ajouter un compte',
                  ar: '\u0625\u0636\u0627\u0641\u0629 \u062d\u0633\u0627\u0628',
                  en: 'Add account',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...pendingFiltered.map(
          (item) => _AccountTile(
            item: item,
            lang: lang,
            onApprove: () => onApprove(item),
            onReject: () => onReject(item),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          tr(
            lang,
            fr: 'Validés',
            ar: '\u0645\u0642\u0628\u0648\u0644',
            en: 'Approved',
          ),
          style: const TextStyle(
            color: Color(0xFF2A6F86),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...approvedFiltered.map(
          (item) => _AccountTile(item: item, lang: lang, isApproved: true),
        ),
        const SizedBox(height: 16),
        Text(
          tr(
            lang,
            fr: 'Refusés',
            ar: '\u0645\u0631\u0641\u0648\u0636',
            en: 'Rejected',
          ),
          style: const TextStyle(
            color: Color(0xFF2A6F86),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...rejectedFiltered.map(
          (item) => _AccountTile(item: item, lang: lang, isRejected: true),
        ),
      ],
    );
  }
}

class _AccountTile extends StatefulWidget {
  const _AccountTile({
    required this.item,
    required this.lang,
    this.onApprove,
    this.onReject,
    this.isRejected = false,
    this.isApproved = false,
  });

  final _AccountItem item;
  final AppLang lang;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool isRejected;
  final bool isApproved;

  @override
  State<_AccountTile> createState() => _AccountTileState();
}

class _AccountTileState extends State<_AccountTile> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: _pressed ? 0.985 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _pressed ? const Color(0xFFE6F6FB) : const Color(0xFFF3FBFE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD7EEF7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_pressed ? 0.03 : 0.06),
              blurRadius: _pressed ? 6 : 10,
              offset: Offset(0, _pressed ? 2 : 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            splashColor: const Color(0xFF18C5C5).withOpacity(0.15),
            highlightColor: Colors.transparent,
            onTap: () {},
            child: Row(
              children: [
                const Icon(Icons.person_outline, color: Colors.black54),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.name,
                        style: const TextStyle(color: Colors.black87),
                      ),
                      Text(
                        widget.item.email,
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 12,
                        ),
                      ),
                      if (widget.item.phone.isNotEmpty ||
                          widget.item.job.isNotEmpty)
                        Text(
                          '${widget.item.phone}${widget.item.phone.isNotEmpty && widget.item.job.isNotEmpty ? ' • ' : ''}${widget.item.job}',
                          style: const TextStyle(
                            color: Colors.black45,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!widget.isRejected && !widget.isApproved) ...[
                  TextButton(
                    onPressed: widget.onApprove,
                    child: Text(
                      tr(
                        lang,
                        fr: 'Valider',
                        ar: '\u0627\u0639\u062a\u0645\u0627\u062f',
                        en: 'Approve',
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onReject,
                    child: Text(
                      tr(
                        lang,
                        fr: 'Refuser',
                        ar: '\u0631\u0641\u0636',
                        en: 'Reject',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceList extends StatelessWidget {
  const _AttendanceList({required this.lang, required this.items});

  final AppLang lang;
  final List<_AttendanceItem> items;

  @override
  Widget build(BuildContext context) {
    final isAr = lang == AppLang.ar;
    return ListView(
      children: items.map((item) {
        final statusText = isAr
            ? (item.status == 'present' ? 'حاضر' : 'غائب')
            : (item.status == 'present' ? 'متأخر' : 'En retard');
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF1B2636),
          child: Row(
            children: [
              Icon(
                item.status == 'present' ? Icons.check_circle : Icons.timer,
                color: item.status == 'present'
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              Text(
                '${item.time} ï¿½ $statusText',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _AccountItem {
  _AccountItem({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.job,
    required this.role,
  });
  final int id;
  final String name;
  final String email;
  final String phone;
  final String job;
  final String role;
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF18C5C5) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF18C5C5) : Colors.black12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _AttendanceRecord {
  _AttendanceRecord({
    required this.name,
    required this.group,
    required this.date,
    required this.status,
    this.distanceMeters,
    this.verificationReason,
  });

  final String name;
  final String group;
  final String date;
  final String status;
  final double? distanceMeters;
  final String? verificationReason;
}

class _FilterChipBox extends StatelessWidget {
  const _FilterChipBox({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE1E4E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _AttendanceItem {
  _AttendanceItem({
    required this.name,
    required this.status,
    required this.time,
    this.verified = false,
    this.message,
  });
  final String name;
  final String status;
  final String time;
  final bool verified;
  final String? message;
}

class _AddAccountDialog extends StatefulWidget {
  const _AddAccountDialog({required this.lang});

  final AppLang lang;

  @override
  State<_AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<_AddAccountDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _jobController = TextEditingController();
  String _role = 'worker';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _jobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return AlertDialog(
      backgroundColor: const Color(0xFF1B2636),
      title: Text(
        tr(
          lang,
          fr: 'Ajouter un compte',
          ar: '\u0625\u0636\u0627\u0641\u0629 \u062d\u0633\u0627\u0628',
          en: 'Add account',
        ),
        style: const TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LineInput(
              hint: 'Nom complet',
              icon: Icons.person_outline,
              accent: const Color(0xFF18C5C5),
              controller: _nameController,
            ),
            const SizedBox(height: 12),
            LineInput(
              hint: tr(
                lang,
                fr: 'Email',
                ar: '\u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a',
                en: 'Email',
              ),
              icon: Icons.mail_outline,
              accent: const Color(0xFF18C5C5),
              controller: _emailController,
            ),
            const SizedBox(height: 12),
            LineInput(
              hint: 'Téléphone',
              icon: Icons.phone_outlined,
              accent: const Color(0xFF18C5C5),
              controller: _phoneController,
            ),
            const SizedBox(height: 12),
            LineInput(
              hint: 'Fonction',
              icon: Icons.work_outline,
              accent: const Color(0xFF18C5C5),
              controller: _jobController,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                border: Border.all(
                  color: const Color(0xFF18C5C5).withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.badge_outlined,
                    color: Color(0xFF18C5C5),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Type:',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _role,
                    dropdownColor: const Color(0xFF1B2636),
                    iconEnabledColor: const Color(0xFF18C5C5),
                    underline: const SizedBox.shrink(),
                    style: const TextStyle(
                      color: Color(0xFF18C5C5),
                      fontSize: 13,
                    ),
                    items: [
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'worker', child: Text('Worker')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _role = value);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Annuler'),
        ),
        TextButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final email = _emailController.text.trim();
            final phone = _phoneController.text.trim();
            final job = _jobController.text.trim();
            if (name.isEmpty || email.isEmpty) return;
            Navigator.of(context).pop(
              _AccountItem(
                id: 0,
                name: name,
                email: email,
                phone: phone,
                job: job,
                role: _role,
              ),
            );
          },
          child: Text('Ajouter'),
        ),
      ],
    );
  }
}
