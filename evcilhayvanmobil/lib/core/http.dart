import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🔗 Sunucu bağlantı adresi
/// Android emulator → 10.0.2.2
/// Web / masaüstü → localhost
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://10.0.2.2:4000',
);

class HttpClient {
  late final Dio dio;
  static final HttpClient _instance = HttpClient._internal();

  factory HttpClient() => _instance;

  HttpClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(AuthInterceptor());
  }
}

class AuthInterceptor extends Interceptor {
  /// 🔓 Token istemeyen (public) endpoint listesi
  final List<String> _publicPaths = [
    '/api/auth/login',
    '/api/auth/register',
    '/api/auth/verify-email',
    '/api/auth/forgot-password',
    '/api/auth/reset-password',
    '/api/health',
  ];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // ✅ 1. Public endpoint’leri kontrol et
    bool isPublic = false;
    final String normalizedPath = Uri.parse(options.path).path;

    // Tam eşleşme varsa
    if (_publicPaths.contains(normalizedPath)) {
      isPublic = true;
    }

    // GET /api/pets ve yalnızca tekil ilan sayfalarını public say
    if (options.method == 'GET') {
      if (normalizedPath == '/api/pets' || _isPublicPetDetailPath(normalizedPath)) {
        isPublic = true;
      }
    }

    // ✅ 2. Public olmayan istekler için token ekle
    if (!isPublic) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      print('⚠️ [HTTP] Token geçersiz veya süresi dolmuş!');
    }
    return super.onError(err, handler);
  }

  bool _isPublicPetDetailPath(String path) {
    final uri = Uri.parse(path);
    final segments = uri.pathSegments;

    if (segments.length != 3) {
      return false;
    }

    if (segments[0] != 'api' || segments[1] != 'pets') {
      return false;
    }

    const protectedSegments = {'me', 'feed'};
    final detailSegment = segments[2].toLowerCase();

    return !protectedSegments.contains(detailSegment);
  }
}