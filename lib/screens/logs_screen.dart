import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../services/logger_service.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({Key? key}) : super(key: key);

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final LoggerService _logger = LoggerService();
  final ScrollController _scrollController = ScrollController();
  String _logs = '加载中...';
  bool _isLoading = true;
  int _selectedLines = 500;
  List<File> _logFiles = [];
  File? _selectedFile;

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _loadLogFiles();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final logs = await _logger.getRecentLogs(lines: _selectedLines);
      setState(() {
        _logs = logs.isEmpty ? '暂无日志' : logs;
        _isLoading = false;
      });

      // 滚动到底部
      if (_scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    } catch (e) {
      setState(() {
        _logs = '加载日志失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLogFiles() async {
    try {
      final files = await _logger.getAllLogFiles();
      setState(() {
        _logFiles = files;
        if (files.isNotEmpty && _selectedFile == null) {
          _selectedFile = files.first;
        }
      });
    } catch (e) {
      debugPrint('Failed to load log files: $e');
    }
  }

  Future<void> _readSelectedFile() async {
    if (_selectedFile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final content = await _selectedFile!.readAsString();
      setState(() {
        _logs = content.isEmpty ? '文件为空' : content;
        _isLoading = false;
      });

      // 滚动到底部
      if (_scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    } catch (e) {
      setState(() {
        _logs = '读取文件失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _logs));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('日志已复制到剪贴板')),
      );
    }
  }

  Future<void> _clearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有日志吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _logger.clearLogs();
      await _loadLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('日志已清空')),
        );
      }
    }
  }

  String _getFileName(File file) {
    final path = file.path;
    final parts = path.split('/');
    return parts.last;
  }

  String _getFileDate(File file) {
    try {
      final stat = file.statSync();
      final date = stat.modified;
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '未知';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('应用日志'),
        actions: [
          // 选择日志行数
          PopupMenuButton<int>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedLines = value;
              });
              _loadLogs();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 100, child: Text('最近 100 行')),
              const PopupMenuItem(value: 500, child: Text('最近 500 行')),
              const PopupMenuItem(value: 1000, child: Text('最近 1000 行')),
              const PopupMenuItem(value: 5000, child: Text('最近 5000 行')),
            ],
          ),
          // 刷新
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: '刷新',
          ),
          // 复制
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyToClipboard,
            tooltip: '复制日志',
          ),
          // 清空
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearLogs,
            tooltip: '清空日志',
          ),
        ],
      ),
      body: Column(
        children: [
          // 日志文件选择器
          if (_logFiles.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Text('日志文件: ', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: DropdownButton<File>(
                      value: _selectedFile,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: _logFiles.map((file) {
                        return DropdownMenuItem<File>(
                          value: file,
                          child: Text(
                            '${_getFileName(file)} (${_getFileDate(file)})',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (file) {
                        if (file != null) {
                          setState(() {
                            _selectedFile = file;
                          });
                          _readSelectedFile();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          // 日志内容
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? const Center(child: Text('暂无日志'))
                    : Container(
                        color: Colors.black,
                        padding: const EdgeInsets.all(8),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: SelectableText(
                            _logs,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Colors.green,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

