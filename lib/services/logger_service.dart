import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// 日志服务 - 收集和管理应用日志
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  static const int _maxLogLines = 5000; // 最大日志行数
  static const int _maxLogFiles = 5; // 最大日志文件数
  File? _logFile;
  final List<String> _inMemoryLogs = [];
  final int _maxInMemoryLogs = 500; // 内存中保留的日志行数

  /// 初始化日志服务
  Future<void> init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      // 使用日期作为日志文件名
      final dateFormat = DateFormat('yyyy-MM-dd');
      final today = dateFormat.format(DateTime.now());
      _logFile = File('${logDir.path}/app_$today.log');

      // 清理旧日志文件
      await _cleanOldLogs(logDir);
    } catch (e) {
      debugPrint('[LoggerService] Failed to init: $e');
    }
  }

  /// 清理旧日志文件
  Future<void> _cleanOldLogs(Directory logDir) async {
    try {
      final files = await logDir.list().toList();
      final logFiles = files
          .whereType<File>()
          .where((f) => f.path.contains('app_') && f.path.endsWith('.log'))
          .toList();

      // 按修改时间排序
      logFiles.sort((a, b) {
        try {
          return b.lastModifiedSync().compareTo(a.lastModifiedSync());
        } catch (_) {
          return 0;
        }
      });

      // 删除超过最大数量的文件
      if (logFiles.length > _maxLogFiles) {
        for (var i = _maxLogFiles; i < logFiles.length; i++) {
          try {
            await logFiles[i].delete();
          } catch (_) {
            // ignore
          }
        }
      }
    } catch (e) {
      debugPrint('[LoggerService] Failed to clean old logs: $e');
    }
  }

  /// 写入日志
  Future<void> log(String level, String tag, String message, {String? stackTrace}) async {
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());
    final logEntry = '[$timestamp] [$level] [$tag] $message';
    
    if (stackTrace != null) {
      final fullLog = '$logEntry\n$stackTrace';
      _addToMemory(fullLog);
      await _writeToFile(fullLog);
    } else {
      _addToMemory(logEntry);
      await _writeToFile(logEntry);
    }

    // 同时输出到控制台（开发模式）
    if (kDebugMode) {
      debugPrint(logEntry);
    }
  }

  /// 添加到内存日志
  void _addToMemory(String logEntry) {
    _inMemoryLogs.add(logEntry);
    if (_inMemoryLogs.length > _maxInMemoryLogs) {
      _inMemoryLogs.removeAt(0);
    }
  }

  /// 写入文件
  Future<void> _writeToFile(String logEntry) async {
    if (_logFile == null) {
      await init();
    }

    try {
      if (_logFile != null) {
        await _logFile!.writeAsString('$logEntry\n', mode: FileMode.append);
        
        // 检查文件大小，如果太大则轮转
        final stat = await _logFile!.stat();
        if (stat.size > 10 * 1024 * 1024) { // 10MB
          await _rotateLog();
        }
      }
    } catch (e) {
      debugPrint('[LoggerService] Failed to write log: $e');
    }
  }

  /// 轮转日志文件
  Future<void> _rotateLog() async {
    try {
      if (_logFile == null) return;

      final oldPath = _logFile!.path;
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final newPath = oldPath.replaceAll('.log', '_$timestamp.log');

      await _logFile!.rename(newPath);
      await init(); // 重新初始化，创建新文件
    } catch (e) {
      debugPrint('[LoggerService] Failed to rotate log: $e');
    }
  }

  /// 获取所有日志（内存 + 文件）
  Future<String> getAllLogs({int? maxLines}) async {
    final buffer = StringBuffer();
    
    // 先添加文件中的日志
    try {
      if (_logFile != null && await _logFile!.exists()) {
        final fileContent = await _logFile!.readAsString();
        final lines = fileContent.split('\n');
        
        int startIndex = 0;
        if (maxLines != null && lines.length > maxLines) {
          startIndex = lines.length - maxLines;
        }
        
        for (var i = startIndex; i < lines.length; i++) {
          if (lines[i].trim().isNotEmpty) {
            buffer.writeln(lines[i]);
          }
        }
      }
    } catch (e) {
      buffer.writeln('[LoggerService] Failed to read log file: $e');
    }

    // 添加内存中的日志（如果文件读取失败或为空）
    if (buffer.isEmpty && _inMemoryLogs.isNotEmpty) {
      int startIndex = 0;
      if (maxLines != null && _inMemoryLogs.length > maxLines) {
        startIndex = _inMemoryLogs.length - maxLines;
      }
      
      for (var i = startIndex; i < _inMemoryLogs.length; i++) {
        buffer.writeln(_inMemoryLogs[i]);
      }
    }

    return buffer.toString();
  }

  /// 获取最近的日志
  Future<String> getRecentLogs({int lines = 500}) async {
    return getAllLogs(maxLines: lines);
  }

  /// 清空日志
  Future<void> clearLogs() async {
    try {
      _inMemoryLogs.clear();
      if (_logFile != null && await _logFile!.exists()) {
        await _logFile!.writeAsString('');
      }
    } catch (e) {
      debugPrint('[LoggerService] Failed to clear logs: $e');
    }
  }

  /// 获取日志文件路径
  Future<String?> getLogFilePath() async {
    if (_logFile == null) {
      await init();
    }
    return _logFile?.path;
  }

  /// 获取所有日志文件
  Future<List<File>> getAllLogFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');
      if (!await logDir.exists()) {
        return [];
      }

      final files = await logDir.list().toList();
      return files
          .whereType<File>()
          .where((f) => f.path.contains('app_') && f.path.endsWith('.log'))
          .toList()
        ..sort((a, b) {
          try {
            return b.lastModifiedSync().compareTo(a.lastModifiedSync());
          } catch (_) {
            return 0;
          }
        });
    } catch (e) {
      debugPrint('[LoggerService] Failed to get log files: $e');
      return [];
    }
  }

  // 便捷方法
  Future<void> debug(String tag, String message, {String? stackTrace}) =>
      log('DEBUG', tag, message, stackTrace: stackTrace);

  Future<void> info(String tag, String message, {String? stackTrace}) =>
      log('INFO', tag, message, stackTrace: stackTrace);

  Future<void> warning(String tag, String message, {String? stackTrace}) =>
      log('WARN', tag, message, stackTrace: stackTrace);

  Future<void> error(String tag, String message, {String? stackTrace}) =>
      log('ERROR', tag, message, stackTrace: stackTrace);
}

