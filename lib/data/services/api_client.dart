import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/storage_helper.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();
  
  late Dio _dio;
  
  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Add interceptors
    _dio.interceptors.add(_AuthInterceptor());
    _dio.interceptors.add(_LogInterceptor());
  }
  
  Dio get dio => _dio;
}

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Add access token to requests
    final token = await StorageHelper.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 errors - token expired
    if (err.response?.statusCode == 401) {
      final refreshToken = await StorageHelper.getRefreshToken();
      if (refreshToken != null) {
        try {
          // Try to refresh token
          final dio = Dio(BaseOptions(
            baseUrl: ApiEndpoints.baseUrl,
            headers: {'Content-Type': 'application/json'},
          ));
          
          final response = await dio.post(
            ApiEndpoints.refreshToken,
            data: {'refresh_token': refreshToken},
          );
          
          if (response.statusCode == 200) {
            final data = response.data;
            await StorageHelper.saveTokens(
              accessToken: data['access_token'],
              refreshToken: data['refresh_token'],
            );
            
            // Retry original request
            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer ${data['access_token']}';
            final cloneReq = await ApiClient().dio.fetch(opts);
            handler.resolve(cloneReq);
            return;
          }
        } catch (e) {
          // Refresh failed, clear tokens
          await StorageHelper.clearAll();
        }
      }
    }
    handler.next(err);
  }
}

class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('🚀 REQUEST[${options.method}] => PATH: ${options.path}');
    print('Headers: ${options.headers}');
    if (options.data != null) {
      print('Data: ${options.data}');
    }
    handler.next(options);
  }
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
    print('Data: ${response.data}');
    handler.next(response);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('❌ ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
    print('Message: ${err.message}');
    if (err.response?.data != null) {
      print('Error Data: ${err.response?.data}');
    }
    handler.next(err);
  }
}
