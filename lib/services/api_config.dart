import 'package:shared_preferences/shared_preferences.dart';
import 'remote_config_service.dart';

class ApiConfig {
  static const _tokenKey = 'api_token';
  static const _authDataKey = 'api_auth_data';

  static String? _tokenCache;
  static String? _authDataCache;

  final RemoteConfigService _remoteConfig = RemoteConfigService();

  /// 获取 API 基础 URL
  /// 优先使用远程配置的域名，失败时回退到默认域名
  Future<String> getBaseUrl() async {
    try {
      return await _remoteConfig.getActiveDomain();
    } catch (e) {
      // 远程配置获取失败，返回默认域名
      return 'YOUR_API_URL_HERE';
    }
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

