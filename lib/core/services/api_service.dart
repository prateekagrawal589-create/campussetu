import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 7),
      receiveTimeout: const Duration(seconds: 12),
      sendTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) options.headers['Authorization'] = 'Bearer $_token';
        if (kDebugMode) debugPrint('→ ${options.method} ${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) debugPrint('← ${response.statusCode} ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) debugPrint('✕ API Error: ${error.message}');
        _retryOnce(error, handler);
      },
    ));
  }

  Future<void> _retryOnce(DioException error, ErrorInterceptorHandler handler) async {
    final opts = error.requestOptions;
    final retries = opts.extra['retries'] ?? 0;
    final shouldRetry = (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.response?.statusCode == 502 ||
        error.response?.statusCode == 503) && retries < 1;
    if (shouldRetry) {
      opts.extra['retries'] = retries + 1;
      await Future.delayed(const Duration(milliseconds: 700));
      try {
        final res = await _dio.fetch(opts);
        handler.resolve(res);
        return;
      } catch (_) {}
    }
    handler.next(error);
  }

  static const String _baseUrl = 'https://campussetu-production.up.railway.app/api/v1';

  late final Dio _dio;
  String? _token;

  void setToken(String token) { _token = token; }
  void clearToken() { _token = null; }

  void warmup() {
    Dio().get('https://campussetu-production.up.railway.app/health').catchError((_) {});
    _dio.get('/health').catchError((_) {});
  }

  Future<List<dynamic>> getPendingRequests() async {
    final res = await _dio.get('/connect/pending');
    final data = res.data;
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return (data as List?) ?? [];
  }

  Future<List<dynamic>> getSentRequests() async {
    final res = await _dio.get('/connect/sent');
    final data = res.data;
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return (data as List?) ?? [];
  }

  Future<List<dynamic>> getMyConnections() async {
    final res = await _dio.get('/connect/my');
    final data = res.data;
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return (data as List?) ?? [];
  }

  Future<void> removeConnection(String connectionId) async {
    await _dio.delete('/connect/$connectionId');
  }

  Dio get dioForDebug => _dio;
  Dio getDioForCustom() => _dio;

  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('/users/me');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getProfile(String userId) async {
    final res = await _dio.get('/users/$userId');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(String userId, Map<String, dynamic> data) async {
    final res = await _dio.put('/users/$userId/profile', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadProfilePhoto(String userId, String filePath) async {
    final formData = FormData.fromMap({'photo': await MultipartFile.fromFile(filePath, filename: 'avatar.jpg')});
    final res = await _dio.post('/users/$userId/photo', data: formData);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getFeed({int page = 1, int limit = 20}) async {
    try {
      final res = await _dio.get('/posts/feed', queryParameters: {'page': page, 'limit': limit});
      return res.data as Map<String, dynamic>;
    } catch (_) {
      final res = await _dio.get('/feed/feed', queryParameters: {'page': page, 'limit': limit});
      return res.data as Map<String, dynamic>;
    }
  }

  Future<Map<String, dynamic>> createPost(Map<String, dynamic> data) async {
    final res = await _dio.post('/posts', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> toggleLike(String postId) async {
    final res = await _dio.post('/posts/$postId/like');
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getComments(String postId) async {
    final res = await _dio.get('/posts/$postId/comments');
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> addComment(String postId, String content) async {
    final res = await _dio.post('/posts/$postId/comment', data: {'content': content});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> discoverStudents({String? college, String? state, String? city, String? branch, int? year, String? skill, String? q, int page = 1}) async {
    try {
      final res = await _dio.get('/users/discover', queryParameters: {if (college != null) 'college': college, if (state != null) 'state': state, if (city != null) 'city': city, if (branch != null) 'branch': branch, if (year != null) 'year': year, if (skill != null) 'skill': skill, if (q != null) 'q': q, 'page': page});
      return res.data as Map<String, dynamic>;
    } catch (_) {
      final res = await _dio.get('/connect/discover', queryParameters: {if (college != null) 'college': college, if (state != null) 'state': state, if (city != null) 'city': city, if (branch != null) 'branch': branch, if (year != null) 'year': year, if (skill != null) 'skill': skill, if (q != null) 'q': q, 'page': page});
      return res.data as Map<String, dynamic>;
    }
  }

  Future<Map<String, dynamic>> sendConnectionRequest(String receiverId) async {
    final res = await _dio.post('/connect/request', data: {'receiver_id': receiverId});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> respondToConnection(String connectionId, String status) async {
    final res = await _dio.put('/connect/$connectionId/respond', data: {'status': status});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createTshare(Map<String, dynamic> data) async {
    final res = await _dio.post('/tshare', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> retrieveTshare(String code) async {
    final res = await _dio.get('/tshare/$code');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getJobs({String? type, String? state, String? city, bool? isRemote, int page = 1}) async {
    final res = await _dio.get('/jobs', queryParameters: {if (type != null) 'type': type, if (state != null) 'state': state, if (city != null) 'city': city, if (isRemote != null) 'is_remote': isRemote, 'page': page});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getProducts({String? category, int page = 1}) async {
    final res = await _dio.get('/products', queryParameters: {if (category != null) 'category': category, 'page': page});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    final res = await _dio.post('/products', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getNotes({String? subject, int? semester}) async {
    final res = await _dio.get('/notes', queryParameters: {if (subject != null) 'subject': subject, if (semester != null) 'semester': semester});
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getChats() async {
    final res = await _dio.get('/chats');
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createChat(Map<String, dynamic> data) async {
    final res = await _dio.post('/chats', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> submitReport(Map<String, dynamic> data) async {
    await _dio.post('/reports', data: data);
  }

  Future<Map<String, dynamic>> getVerificationQueue() async {
    final res = await _dio.get('/admin/verification-queue');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getReportsQueue() async {
    final res = await _dio.get('/admin/reports');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getJobApprovalQueue() async {
    final res = await _dio.get('/admin/jobs/pending');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getHelpingTasks({String? type, bool? mine, String status = 'open', String? q}) async {
    final res = await _dio.get('/helping', queryParameters: {
      if (type != null) 'type': type,
      if (mine == true) 'mine': 'true',
      'status': status,
      if (q != null && q.isNotEmpty) 'q': q,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getHelpingTask(String id) async {
    final res = await _dio.get('/helping/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createHelpingTask({required String title, required String description, required String type, double? amount, int? points, String? deadline, String? imagePath}) async {
    if (imagePath != null) {
      final form = FormData.fromMap({
        'title': title,
        'description': description,
        'type': type,
        if (amount != null) 'amount': amount.toString(),
        if (points != null) 'points': points.toString(),
        if (deadline != null) 'deadline': deadline,
        'image': await MultipartFile.fromFile(imagePath),
      });
      final res = await _dio.post('/helping', data: form);
      return res.data as Map<String, dynamic>;
    }
    final res = await _dio.post('/helping', data: {
      'title': title,
      'description': description,
      'type': type,
      if (amount != null) 'amount': amount,
      if (points != null) 'points': points,
      if (deadline != null) 'deadline': deadline,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> applyHelpingTask(String id) async {
    final res = await _dio.post('/helping/$id/apply');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> acceptHelpingApplicant(String id, String applicantId) async {
    final res = await _dio.post('/helping/$id/accept', data: {'applicant_id': applicantId});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> completeHelpingTask(String id) async {
    final res = await _dio.post('/helping/$id/complete');
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteHelpingTask(String id) async {
    await _dio.delete('/helping/$id');
  }

  Future<Map<String, dynamic>> getUserByCampusId(String campusId) async {
    final res = await _dio.get('/users/by-campus/$campusId');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> transferPoints({required String toCampusId, required int amount}) async {
    final res = await _dio.post(
      '/users/transfer',
      data: {'to_campus_id': toCampusId, 'amount': amount},
      options: Options(extra: {'retries': 1}),
    );
    return res.data as Map<String, dynamic>;
  }
}
