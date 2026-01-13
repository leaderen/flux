import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/auth_screen.dart';
import 'screens/root_shell.dart';
import 'services/api_config.dart';
import 'services/v2board_api.dart';
import 'theme/app_theme.dart';
import 'widgets/flux_splash.dart';

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1000, 720),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      title: 'Flux',
    );
    
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      
      // 设置窗口图标
      try {
        if (Platform.isLinux || Platform.isWindows) {
          final exePath = Platform.resolvedExecutable;
          final exeDir = File(exePath).parent.path;
          final assetPath = Platform.isWindows 
              ? 'assets/icons/app_icon.ico'
              : 'assets/icons/app_icon.png';
              
          // 尝试构建后的路径
          String iconPath = '$exeDir/data/flutter_assets/$assetPath';
          if (!await File(iconPath).exists()) {
            // 开发环境回退
            iconPath = assetPath;
          }
          
          if (await File(iconPath).exists()) {
            await windowManager.setIcon(iconPath);
          }
        }
      } catch (e) {
        debugPrint('[Main] Error setting icon: $e');
      }
    });
  }
  
  runApp(const FluxApp());
}

class FluxApp extends StatelessWidget {
  const FluxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flux',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      
      // 本地化配置 / Localization configuration
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),      // English
        Locale('zh'),      // 简体中文
        Locale('zh', 'TW'), // 繁體中文
        Locale('ja'),      // 日本語
        Locale('ko'),      // 한국어
        Locale('ru'),      // Русский
        Locale('hi'),      // हिन्दी
        Locale('es'),      // Español
        Locale('pt'),      // Português
        Locale('fr'),      // Français
        Locale('de'),      // Deutsch
        Locale('ar'),      // العربية
        Locale('tr'),      // Türkçe
        Locale('vi'),      // Tiếng Việt
        Locale('th'),      // ไทย
        Locale('id'),      // Indonesia
      ],
      
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _api = V2BoardApi();
  final _config = ApiConfig();
  bool _authed = false;
  bool _isChecking = true;
  final _startTime = DateTime.now();
  
  // 最小启动动画时间（毫秒）- 让动画至少播放这么久
  static const _minSplashDuration = 2500;
  
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await _config.refreshAuthCache();
    final token = await _config.getToken();
    final authData = await _config.getAuthData();
    
    bool authResult = false;
    
    if (token == null && authData == null) {
      authResult = false;
    } else {
      try {
        await _api.getUserInfo();
        authResult = true;
      } catch (_) {
        await _config.clearAuth();
        authResult = false;
      }
    }
    
    // 确保动画至少播放 _minSplashDuration 毫秒
    final elapsed = DateTime.now().difference(_startTime).inMilliseconds;
    if (elapsed < _minSplashDuration) {
      await Future.delayed(Duration(milliseconds: _minSplashDuration - elapsed));
    }
    
    if (mounted) {
      setState(() {
        _authed = authResult;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 检查中显示 Flutter 启动动画
    if (_isChecking) {
      return const FluxSplash();
    }
    if (!_authed) {
      return AuthScreen(
        onAuthed: () => setState(() => _authed = true),
      );
    }
    return RootShell(
      onLogout: () => setState(() => _authed = false),
    );
  }
}
