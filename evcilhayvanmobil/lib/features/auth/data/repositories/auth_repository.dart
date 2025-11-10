// lib/features/auth/data/repositories/auth_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import 'package:evcilhayvanmobil/core/http.dart';
import 'package:evcilhayvanmobil/features/pets/data/repositories/pets_repository.dart';

import '../../domain/user_model.dart'; 

// 1. AuthRepository Provider'ı (Değişiklik yok)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = HttpClient().dio;
  return AuthRepository(dio);
});

// 2. Auth (Kullanıcı Giriş/Kayıt) sınıfı
class AuthRepository {
  final Dio _dio;
  AuthRepository(this._dio);

  Future<User> _persistAndParseUser(Response response) async {
    final token = response.data['token'] as String?;
    final userJson = response.data['user'] as Map<String, dynamic>?;
    if (token == null || userJson == null) {
      throw Exception('Sunucudan beklenmeyen yanıt alındı.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    return User.fromJson(userJson);
  }

  // --- YENİ EKLENEN getAllUsers METODU ---
  /**
   * (AUTH) Diğer tüm kullanıcıları listeler.
   * Backend: GET /api/auth/users
   */
  Future<List<User>> getAllUsers() async {
    try {
      // Token, interceptor tarafından otomatik eklenecek
      final response = await _dio.get('/api/auth/users');
      
      // Backend'den gelen cevabın yapısı: { ok: true, users: [...] }
      final List<dynamic> userListJson = response.data['users'];
      
      // Gelen ham JSON listesini, User.fromJson kullanarak User nesneleri listesine çevir.
      final List<User> users = userListJson.map((json) => User.fromJson(json)).toList();
      return users;

    } on DioException catch (e) {
      throw Exception('Kullanıcılar alınamadı: ${e.response?.data['message']}');
    } catch (e) {
      throw Exception('Bir hata oluştu: $e');
    }
  }
  // --- YENİ METOD BİTTİ ---

  /* --- MEVCUT METODLAR (Değişiklik yok) --- */

  Future<User> updateProfile({
    required String name, required String city, required String about,
  }) async { /* ... (kod aynı) ... */ 
    try {
      final response = await _dio.put(
        '/api/auth/me',
        data: { 'name': name, 'city': city, 'about': about, },
      );
      return User.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw Exception('Profil güncellenemedi: ${e.response?.data['message']}');
    } catch (e) {
      throw Exception('Bir hata oluştu: $e');
    }
  }
  Future<User> login(String email, String password) async { /* ... (kod aynı) ... */
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: { 'email': email, 'password': password },
      );
      return _persistAndParseUser(response);
    } on DioException catch (e) {
      if (e.response?.data['notVerified'] == true) {
        throw VerificationRequiredException(
          e.response?.data['message'] ?? 'Hesap doğrulanmamış',
          email: e.response?.data['email'] ?? email,
        );
      }
      final String errorMessage = e.response?.data['message'] ?? 'Giriş yapılamadı';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Bir hata oluştu: $e');
    }
  }
  Future<String> register({
    required String name, required String email, required String password, String? city,
  }) async { /* ... (kod aynı) ... */ 
    try {
      final response = await _dio.post(
        '/api/auth/register',
        data: {
          'name': name, 'email': email, 'password': password, 'city': city,
        },
      );
      return response.data['email'] ?? email;
    } on DioException catch (e) {
      final String errorMessage = e.response?.data['message'] ?? 'Kayıt olunamadı';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Bir hata oluştu: $e');
    }
  }
  Future<User> verifyEmail({required String email, required String code}) async { /* ... (kod aynı) ... */
    try {
      final response = await _dio.post(
        '/api/auth/verify-email',
        data: { 'email': email, 'code': code },
      );
      return _persistAndParseUser(response);
    } on DioException catch (e) {
      final String errorMessage = e.response?.data['message'] ?? 'Doğrulama başarısız';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Bir hata oluştu: $e');
    }
  }
  Future<void> forgotPassword({required String email}) async { /* ... (kod aynı) ... */ 
    try {
      await _dio.post(
        '/api/auth/forgot-password',
        data: {'email': email},
      );
      return;
    } on DioException catch (e) {
      final String errorMessage = e.response?.data['message'] ?? 'Kod gönderilemedi';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Bir hata oluştu: $e');
    }
  }
  Future<void> resetPassword({
    required String email, required String code, required String newPassword,
  }) async { /* ... (kod aynı) ... */ 
    try {
      await _dio.post(
        '/api/auth/reset-password',
        data: {
          'email': email, 'code': code, 'newPassword': newPassword,
        },
      );
      return;
    } on DioException catch (e) {
      final String errorMessage = e.response?.data['message'] ?? 'Şifre sıfırlanamadı';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Bir hata oluştu: $e');
    }
  }
  Future<String?> getToken() async { /* ... (kod aynı) ... */ 
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
  Future<User> me() async { /* ... (kod aynı) ... */ 
    try {
      final response = await _dio.get('/api/auth/me');
      final Map<String, dynamic> userJson = response.data['user'];
      return User.fromJson(userJson);
    } on DioException catch (e) {
      throw Exception('Lütfen tekrar giriş yapın: ${e.message}');
    } catch (e) {
      throw Exception('Profil alınamadı: $e');
    }
  }
  Future<void> logout() async { /* ... (kod aynı) ... */ 
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
  Future<User> uploadAvatar(XFile imageFile) async { /* ... (kod aynı) ... */
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        "avatar": await MultipartFile.fromFile(
          imageFile.path, 
          filename: fileName
        ),
      });
      final response = await _dio.post(
        '/api/auth/avatar',
        data: formData,
      );
      return User.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw Exception('Resim yüklenemedi: ${e.response?.data['message']}');
    }
  }

  Future<User> loginWithGoogleToken(String idToken) async {
    try {
      final response = await _dio.post(
        '/api/auth/oauth/google',
        data: {'idToken': idToken},
      );
      return _persistAndParseUser(response);
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Google ile giriş başarısız';
      throw Exception(message);
    } catch (e) {
      throw Exception('Google ile giriş başarısız: $e');
    }
  }

  Future<User> loginWithFacebookToken(String accessToken) async {
    try {
      final response = await _dio.post(
        '/api/auth/oauth/facebook',
        data: {'accessToken': accessToken},
      );
      return _persistAndParseUser(response);
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Facebook ile giriş başarısız';
      throw Exception(message);
    } catch (e) {
      throw Exception('Facebook ile giriş başarısız: $e');
    }
  }
}

// Özel Hata Sınıfı (Değişiklik yok)
class VerificationRequiredException implements Exception {
  final String message;
  final String email;
  VerificationRequiredException(this.message, {required this.email});
  @override
  String toString() => message;
}

// Global Auth Provider (Değişiklik yok)
final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider), ref);
});
class AuthNotifier extends StateNotifier<User?> {
  final AuthRepository _authRepository;
  final Ref _ref; 
  AuthNotifier(this._authRepository, this._ref) : super(null) { /* _loadUser() çağrısı yok */ }
  void loginSuccess(User user) {
    state = user;
    _ref.invalidate(myPetsProvider); 
  }
  Future<void> logout() async {
    await _authRepository.logout();
    state = null; 
    _ref.invalidate(myPetsProvider);
  }
}

// --- YENİ EKLENEN allUsersProvider ---
// "Bağlan" ekranında gösterilecek tüm kullanıcıların listesi
final allUsersProvider = FutureProvider<List<User>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.getAllUsers();
});
// --- YENİ PROVIDER BİTTİ ---