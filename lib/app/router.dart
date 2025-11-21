import 'package:flutter/material.dart';
import 'package:test_flutter/features/artikel/pages/artikel_detail_page.dart';
import 'package:test_flutter/features/artikel/pages/artikel_page.dart';
import 'package:test_flutter/features/auth/pages/forgot_password.dart';
import 'package:test_flutter/features/auth/pages/login_page.dart';
import 'package:test_flutter/features/auth/pages/otp.dart';
import 'package:test_flutter/features/auth/pages/reset_password.dart';
import 'package:test_flutter/features/auth/pages/signup_page.dart';
import 'package:test_flutter/features/auth/pages/splash_screen.dart';
import 'package:test_flutter/features/auth/pages/welcome_page.dart';
import 'package:test_flutter/features/compass/pages/compass_page.dart';
import 'package:test_flutter/features/haji/pages/haji_page.dart';
import 'package:test_flutter/features/home/pages/home_page.dart';
import 'package:test_flutter/features/komunitas/pages/komunitas_page.dart';
import 'package:test_flutter/features/monitoring/pages/monitoring_page.dart';
import 'package:test_flutter/features/profile/pages/profile_page.dart';
import 'package:test_flutter/features/profile/pages/edit_profile_page.dart';
import 'package:test_flutter/features/profile/pages/change_password_page.dart';
import 'package:test_flutter/features/profile/pages/manage_family_page.dart';
import 'package:test_flutter/features/puasa/pages/puasa_page.dart';
import 'package:test_flutter/features/quran/pages/quran_page.dart';
import 'package:test_flutter/features/quran/pages/surah_detail_page.dart';
import 'package:test_flutter/features/sedekah/pages/sedekah_page.dart';
import 'package:test_flutter/features/sholat/pages/sholat_page.dart';
import 'package:test_flutter/features/subscription/models/pesanan.dart';
import 'package:test_flutter/features/subscription/pages/detail_pesanan_page.dart';
import 'package:test_flutter/features/syahadat/pages/syahadat_page.dart';
import 'package:test_flutter/features/tahajud/pages/tahajud_page.dart';
import 'package:test_flutter/features/subscription/pages/paket_page.dart';
import 'package:test_flutter/features/subscription/pages/riwayat_page.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String otp = '/otp';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
  static const String qiblaCompass = '/qibla-compass';
  static const String quran = '/quran';
  static const String surahDetail = '/surah-detail';
  static const String sholat = '/sholat';
  static const String puasa = '/puasa';
  static const String zakat = '/zakat';
  static const String ngajiOnline = '/ngaji-online';
  static const String monitoring = '/monitoring';
  static const String tahajud = '/tahajud';
  static const String articleDetail = '/article-detail';
  static const String alarmSettings = '/alarm-settings';

  /// Profile and related pages
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String changePassword = '/change-password';
  static const String manageFamily = '/manage-family';
  static const String plan = '/plan';
  static const String transactionHistory = '/transaction-history';
  static const String pesananDetail = '/pesanan-detail';
  ///

  static const String article = '/article';
  static const String syahadat = '/syahadat';
  static const String komunitas = '/komunitas';
  static const String haji = '/haji';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomePage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupPage());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());
      case otp:
        final otpArgs = settings.arguments as Map<String, dynamic>?;
        final typeString = otpArgs?['type'] as String? ?? 'registration';

        OTPType otpType;
        switch (typeString.toLowerCase()) {
          case 'registration':
            otpType = OTPType.registration;
            break;
          case 'login':
            otpType = OTPType.login;
            break;
          case 'forgotpassword':
          default:
            otpType = OTPType.forgotPassword;
        }

        return MaterialPageRoute(
          builder: (_) => OTPPage(
            email: otpArgs?['email'] ?? '',
            type: otpType,
            name: otpArgs?['name'],
            password: otpArgs?['password'],
            confirmationPassword: otpArgs?['confirmationPassword'],
          ),
        );
      case resetPassword:
        final args = settings.arguments as Map<String, String>?;
        return MaterialPageRoute(
          builder: (_) => ResetPasswordPage(
            otp: args?['otp'] ?? '',
            email: args?['email'] ?? '',
          ),
        );
      case home:
        return MaterialPageRoute(builder: (_) => HomePage());
      case qiblaCompass:
        return MaterialPageRoute(builder: (_) => const CompassPage());
      case quran:
        return MaterialPageRoute(builder: (_) => const QuranPage());
      case surahDetail:
        return MaterialPageRoute(
          builder: (_) => SurahDetailPage(
            surah: settings.arguments as dynamic,
            allSurahs: [],
          ),
        );
      case sholat:
        return MaterialPageRoute(builder: (_) => const SholatPage());
      case puasa:
        return MaterialPageRoute(builder: (_) => const PuasaPage());
      case zakat:
        return MaterialPageRoute(builder: (_) => const SedekahPage());
      case monitoring:
        return MaterialPageRoute(builder: (_) => const MonitoringPage());
      case tahajud:
        return MaterialPageRoute(builder: (_) => const TahajudPage());
      case article:
        return MaterialPageRoute(builder: (_) => const ArtikelPage());
      case articleDetail:
        return MaterialPageRoute(
          builder: (_) =>
              ArtikelDetailPage(artikelId: settings.arguments as dynamic),
        );
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfilePage());
      case changePassword:
        return MaterialPageRoute(builder: (_) => const ChangePasswordPage());
      case manageFamily:
        return MaterialPageRoute(builder: (_) => const ManageFamilyPage());
      case syahadat:
        return MaterialPageRoute(builder: (_) => const SyahadatPage());
      case komunitas:
        return MaterialPageRoute(builder: (_) => const KomunitasPage());
      case haji:
        return MaterialPageRoute(builder: (_) => const HajiPage());
      case plan:
        return MaterialPageRoute(builder: (_) => const PaketPage());
      case transactionHistory:
        return MaterialPageRoute(builder: (_) => const RiwayatPage());
      case pesananDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => DetailPesananPage(
            pesanan: args['pesanan'] as Pesanan,
            snapToken: args['snapToken'] as String?,
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
