import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const _tokenKey = 'api_token';
  static const _authDataKey = 'api_auth_data';
  static const _baseUrlKey = 'api_base_url';

  static String? _tokenCache;
  static String? _authDataCache;

  // 从编译时常量获取 API URL（通过 --dart-define=API_BASE_URL=xxx 传递）
  // 如果没有定义，则使用默认值或从 SharedPreferences 读取
  static const String _buildTimeApiUrl = 
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  Future<String> getBaseUrl() async {
    // 优先使用编译时传入的 API URL
    if (_buildTimeApiUrl.isNotEmpty) {
      return _buildTimeApiUrl;
    }
    
    // 其次从 SharedPreferences 读取用户配置的 URL
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_baseUrlKey);
    if (savedUrl != null && savedUrl.isNotEmpty) {
      return savedUrl;
    }
    
    // 最后使用默认值
    return 'https://node.quicklian.com/api/v1';
  }

  /// 设置 API 基础 URL（运行时配置）
  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url);
  }

  /// 获取保存的 API URL（如果存在）
  Future<String?> getSavedBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_baseUrlKey);
  }

  Future<String?> getToken() async {
    final cached = _tokenCache;
    if (cached != null) return cached;
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_tokenKey);
    _tokenCache = value;
    return value;
  }

  Future<void> setToken(String? token) async {
    _tokenCache = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove(_tokenKey);
      return;
    }
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getAuthData() async {
    final cached = _authDataCache;
    if (cached != null) return cached;
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_authDataKey);
    _authDataCache = value;
    return value;
  }

  Future<void> setAuthData(String? value) async {
    _authDataCache = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.isEmpty) {
      await prefs.remove(_authDataKey);
      return;
    }
    await prefs.setString(_authDataKey, value);
  }

  Future<void> clearAuth() async {
    _tokenCache = null;
    _authDataCache = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_authDataKey);
  }

  Future<void> refreshAuthCache() async {
    final prefs = await SharedPreferences.getInstance();
    _tokenCache = prefs.getString(_tokenKey);
    _authDataCache = prefs.getString(_authDataKey);
  }
}
