import 'dart:io';

import 'package:flutter/services.dart';
import '../models/server_node.dart';
import 'dart:convert';
import 'v2ray_service_windows.dart';

/// V2ray服务 - 通过MethodChannel与Android端通信
class V2rayService {
  static const MethodChannel _channel = MethodChannel('com.flux.app/v2ray');
  static const EventChannel _statusChannel =
      EventChannel('com.flux.app/v2ray_status');
  static Stream<bool>? _statusStream;

  Stream<bool> get statusStream {
    if (Platform.isWindows) {
      return V2rayServiceWindows().statusStream;
    }
    return _statusStream ??=
        _statusChannel.receiveBroadcastStream().map((event) {
      if (event is bool) return event;
      return event == true;
    });
  }

  /// 连接到指定节点
  Future<bool> connect(ServerNode node) async {
    if (Platform.isWindows) {
      return await V2rayServiceWindows().connect(node);
    }
    try {
      // 生成完整的 Xray 配置（包含 inbounds 和 outbounds）
      final fullConfig = _buildFullXrayConfig(node);
      final configJson = jsonEncode(fullConfig);
      
      print('[V2rayService] Connecting to ${node.name} (${node.protocol})');
      print('[V2rayService] Address: ${node.address}:${node.port}');
      print('[V2rayService] Config length: ${configJson.length} bytes');
      
      final result = await _channel.invokeMethod<dynamic>(
        'connect',
        {'config': configJson},
      );
      
      // 处理返回结果
      bool success = false;
      String? errorMessage;
      
      if (result is bool) {
        success = result;
      } else if (result is Map) {
        success = result['success'] == true;
        errorMessage = result['error']?.toString();
      }
      
      if (success) {
        print('[V2rayService] ✅ Connection initiated successfully');
      } else {
        final error = errorMessage ?? 'result is false';
        print('[V2rayService] ❌ Connection failed: $error');
      }
      
      return success;
    } on PlatformException catch (e) {
      print('[V2rayService] ❌ PlatformException: ${e.code} - ${e.message}');
      print('[V2rayService] Details: ${e.details}');
      print('[V2rayService] StackTrace: ${e.stackTrace}');
      return false;
    } catch (e, stackTrace) {
      print('[V2rayService] ❌ Error: $e');
      print('[V2rayService] StackTrace: $stackTrace');
      return false;
    }
  }
  
  /// 构建完整的 Xray 配置（包含 inbounds 和 outbounds）
  Map<String, dynamic> _buildFullXrayConfig(ServerNode node) {
    final outbound = node.toV2rayConfig();
    
    return {
      'log': {
        'loglevel': 'warning',
      },
      'inbounds': [
        {
          'tag': 'socks',
          'port': 10808,
          'protocol': 'socks',
          'settings': {
            'auth': 'noauth',
            'udp': true,
            'ip': '127.0.0.1',
          },
          'sniffing': {
            'enabled': true,
            'destOverride': ['http', 'tls'],
          },
        },
        {
          'tag': 'http',
          'port': 10809,
          'protocol': 'http',
          'settings': {
            'userLevel': 8,
          },
        },
      ],
      'outbounds': [
        outbound,
        {
          'tag': 'direct',
          'protocol': 'freedom',
        },
      ],
      'routing': {
        'domainStrategy': 'IPIfNonMatch',
        'rules': [
          {
            'type': 'field',
            'ip': ['geoip:private', 'geoip:cn'],
            'outboundTag': 'direct',
          },
          {
            'type': 'field',
            'domain': ['geosite:cn'],
            'outboundTag': 'direct',
          },
        ],
      },
    };
  }

  /// 断开连接
  Future<bool> disconnect() async {
    if (Platform.isWindows) {
      return await V2rayServiceWindows().disconnect();
    }
    try {
      print('[V2rayService] Disconnecting...');
      final result = await _channel.invokeMethod<bool>('disconnect');
      print('[V2rayService] Disconnect result: $result');
      return result ?? false;
    } on PlatformException catch (e) {
      print('[V2rayService] Disconnect PlatformException: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('[V2rayService] Disconnect error: $e');
      return false;
    }
  }

  /// 获取连接状态
  Future<bool> isConnected() async {
    if (Platform.isWindows) {
      return await V2rayServiceWindows().isConnected();
    }
    try {
      final result = await _channel.invokeMethod<bool>('isConnected');
      return result ?? false;
    } on PlatformException catch (e) {
      print('[V2rayService] isConnected PlatformException: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('[V2rayService] isConnected error: $e');
      return false;
    }
  }
}
