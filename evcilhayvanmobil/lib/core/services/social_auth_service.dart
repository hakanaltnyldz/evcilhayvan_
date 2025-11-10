import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum SocialProvider { google, facebook }

class SocialAuthResult {
  final SocialProvider provider;
  final String token;
  final String? email;
  final String? displayName;
  final String? avatarUrl;

  const SocialAuthResult({
    required this.provider,
    required this.token,
    this.email,
    this.displayName,
    this.avatarUrl,
  });
}

class SocialAuthException implements Exception {
  final String message;
  SocialAuthException(this.message);

  @override
  String toString() => message;
}

class SocialAuthService {
  SocialAuthService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? _createGoogleSignIn();

  final GoogleSignIn _googleSignIn;

  static GoogleSignIn _createGoogleSignIn() {
    const serverClientId = String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
      defaultValue: '',
    );

    if (serverClientId.isNotEmpty && !kIsWeb) {
      return GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: serverClientId,
      );
    }

    return GoogleSignIn(
      scopes: const ['email', 'profile'],
    );
  }

  Future<SocialAuthResult> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw SocialAuthException('Google girişi iptal edildi.');
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw SocialAuthException(
          'Google kimlik doğrulama bilgisi alınamadı. Lütfen tekrar deneyin.',
        );
      }

      return SocialAuthResult(
        provider: SocialProvider.google,
        token: idToken,
        email: account.email,
        displayName: account.displayName,
        avatarUrl: account.photoUrl,
      );
    } on PlatformException catch (error) {
      if (error.code == 'sign_in_failed' && error.message != null) {
        final needsPlayServices = error.message!.contains('12500') ||
            error.message!.toLowerCase().contains('google play');
        if (needsPlayServices && !kIsWeb) {
          throw SocialAuthException(
            'Google girişi için bu cihazda Google Play Hizmetleri yüklü olmalıdır. '
            'Lütfen Google Play Hizmetleri bulunan bir cihaz veya emülatör kullanın.',
          );
        }
      }
      throw SocialAuthException('Google girişi başarısız: ${error.message ?? error.code}');
    } on MissingPluginException {
      throw SocialAuthException(
        'Google girişi bu platformda desteklenmiyor. Lütfen mobil cihazda deneyin.',
      );
    } catch (error) {
      if (error is SocialAuthException) rethrow;
      throw SocialAuthException('Google girişi başarısız: $error');
    }
  }

  Future<SocialAuthResult> signInWithFacebook() async {
    try {
      final result = await FacebookAuth.instance.login(
        permissions: const ['email', 'public_profile'],
      );

      switch (result.status) {
        case LoginStatus.success:
          final accessToken = result.accessToken;
          if (accessToken == null || accessToken.token.isEmpty) {
            throw SocialAuthException('Facebook erişim anahtarı alınamadı.');
          }

          Map<String, dynamic>? userData;
          try {
            userData = await FacebookAuth.instance.getUserData(
              fields: 'name,email,picture.width(200)',
            );
          } catch (_) {
            userData = null;
          }

          return SocialAuthResult(
            provider: SocialProvider.facebook,
            token: accessToken.token,
            email: userData?['email'] as String?,
            displayName: userData?['name'] as String?,
            avatarUrl: (userData?['picture'] as Map?)?['data']?['url'] as String?,
          );
        case LoginStatus.cancelled:
          throw SocialAuthException('Facebook girişi iptal edildi.');
        case LoginStatus.failed:
        case LoginStatus.operationInProgress:
        default:
          throw SocialAuthException(
            result.message ?? 'Facebook girişi başarısız oldu.',
          );
      }
    } on MissingPluginException {
      throw SocialAuthException(
        'Facebook girişi bu platformda desteklenmiyor. Lütfen mobil cihazda deneyin.',
      );
    } on PlatformException catch (error) {
      final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
      if (isAndroid) {
        throw SocialAuthException(
          'Facebook uygulaması ya da Google Play Hizmetleri eksik görünüyor. '
          'Lütfen cihazınızda Facebook uygulamasının kurulu olduğundan veya geçerli bir tarayıcı bulunduğundan emin olun.',
        );
      }
      throw SocialAuthException('Facebook girişi başarısız: ${error.message ?? error.code}');
    } catch (error) {
      if (error is SocialAuthException) rethrow;
      throw SocialAuthException('Facebook girişi başarısız: $error');
    }
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      await FacebookAuth.instance.logOut();
    } catch (_) {
      // Sessizce görmezden gel
    }
  }
}
