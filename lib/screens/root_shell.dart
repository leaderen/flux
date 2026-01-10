import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/plan.dart';
import '../services/latency_test_service.dart';
import '../services/subscription_service.dart';

import '../services/unified_vpn_service.dart';
import '../services/platform_service.dart';
import '../services/tray_service.dart';
import '../models/server_node.dart';
import '../theme/app_colors.dart';
import 'account_screen.dart';
import 'home_dashboard.dart';
import 'plans_screen.dart';
import 'orders_screen.dart';
import 'logs_screen.dart';
import '../widgets/animated_background.dart';
import '../widgets/flux_loader.dart';
import '../widgets/glass_nav_bar.dart';
import '../widgets/desktop_nav.dart';

import 'package:window_manager/window_manager.dart';

enum ShellStatus { disconnected, connecting, connected, error }

class RootShell extends StatefulWidget {
  final VoidCallback onLogout;
  const RootShell({super.key, required this.onLogout});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with WindowListener {
  final _subscriptionService = SubscriptionService();
  final _latencyService = LatencyTestService();
  final _vpnService = UnifiedVpnService.instance;
  final _trayService = TrayService.instance;
  
  ShellStatus _status = ShellStatus.disconnected;
  String _statusMessage = '未连接';
  int _index = 0;
  bool _isSwitching = false;
  int _accountReload = 0;
  bool _isConnecting = false;
  List<ServerNode>? _nodesCache;
  
  // 判断是否是桌面平台
  bool get _isDesktop => !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  
  @override
  void initState() {
    super.initState();
    _vpnService.statusStream.listen(_onVpnStatusChanged);
    _checkInitialStatus();
    _initTray();
    
    // 初始化窗口监听
    if (_isDesktop) {
      windowManager.addListener(this);
      _initWindow();
    }
  }
  
  Future<void> _initWindow() async {
    await windowManager.setPreventClose(true);
  }
  
  @override
  void dispose() {
    if (_isDesktop) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }
  
  @override
  void onWindowClose() async {
    if (_isDesktop) {
      bool isPreventClose = await windowManager.isPreventClose();
      if (isPreventClose) {
        await windowManager.hide();
      }
    }
  }
  
  Future<void> _initTray() async {
    if (_isDesktop) {
      await _trayService.init(
        onConnect: _toggleConnection,
        onDisconnect: _toggleConnection,
        onShowWindow: () async {
          await windowManager.show();
          await windowManager.focus();
        },
        onQuit: () async {
          // 彻底退出前取消阻止关闭
          await windowManager.setPreventClose(false);
          exit(0);
        },
      );
    }
  }
  
  Future<void> _checkInitialStatus() async {
    final isConnected = await _vpnService.isConnected();
    if (mounted && isConnected) {
      setState(() {
        _status = ShellStatus.connected;
        _statusMessage = '已连接';
      });
    }
  }
  
  void _onVpnStatusChanged(bool isConnected) {
    if (!mounted) return;
    
    print('[RootShell] VPN status changed: $isConnected, current status: $_status');
    
    // 处理连接状态变化
    if (isConnected) {
      // 连接成功
      if (_status == ShellStatus.connecting) {
        setState(() {
          _status = ShellStatus.connected;
          _statusMessage = '已连接';
        });
      } else if (_status != ShellStatus.connected) {
        setState(() {
          _status = ShellStatus.connected;
          _statusMessage = '已连接';
        });
      }
    } else {
      // 断开连接
      final logger = LoggerService();
      if (_status == ShellStatus.connecting) {
        // 连接失败 - 但需要等待一下，因为状态可能还在变化
        // iOS VPN 连接是异步的，可能需要几秒钟
        logger.warning('RootShell', 'Status changed to disconnected while connecting - waiting for final status...');
        print('[RootShell] ⚠️ Status changed to disconnected while connecting - waiting for final status...');
        // 不立即设置为错误，等待一下看是否还会变化
        Future.delayed(const Duration(seconds: 3), () async {
          if (mounted && _status == ShellStatus.connecting) {
            // 如果 3 秒后还是连接中状态，说明真的失败了
            await logger.error('RootShell', 'Connection failed after 3 seconds wait');
            setState(() {
              _status = ShellStatus.error;
              _statusMessage = '连接失败，请检查日志或重试';
            });
          }
        });
      } else if (_status == ShellStatus.connected) {
        // VPN 被后台杀死
        logger.info('RootShell', 'VPN disconnected (was connected)');
        setState(() {
          _status = ShellStatus.disconnected;
          _statusMessage = 'VPN 已断开';
        });
      }
    }
  }

  Future<void> _openCheckout(Plan plan) async {
    await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => OrdersScreen(
          selectedPlan: plan,
          onPickPlan: () => Navigator.of(context).pop(),
          onPaid: _handlePaid,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
    
    // 无论如何返回后都刷新订阅信息（可能支付成功但用户用返回键关闭）
    if (mounted) {
      setState(() {
        _accountReload++;
      });
    }
  }

  void _handlePaid() {
    setState(() {
      _accountReload++;
      _index = 0;
    });
  }

  Future<void> _switchTab(int next) async {
    if (next == _index || _isSwitching) return;
    setState(() => _isSwitching = true);
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (!mounted) return;
    setState(() {
      _index = next;
      _isSwitching = false;
    });
  }

  Future<void> _toggleConnection() async {
    // 防止重复点击
    if (_isConnecting) return;
    
    if (_status == ShellStatus.connected) {
      _isConnecting = true;
      setState(() {
        _status = ShellStatus.connecting;
        _statusMessage = '正在断开...';
      });
      try {
        await _vpnService.disconnect();
        setState(() {
          _status = ShellStatus.disconnected;
          _statusMessage = '已断开';
        });
      } catch (e) {
        setState(() {
          _status = ShellStatus.error;
          _statusMessage = '断开失败: $e';
        });
      } finally {
        _isConnecting = false;
      }
      return;
    }

    _isConnecting = true;
    setState(() {
      _status = ShellStatus.connecting;
      _statusMessage = '正在拉取节点...';
    });

    try {
      // 异步拉取节点，避免阻塞 UI
      final nodes = await _subscriptionService.fetchNodes().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('拉取节点超时'),
      );
      
      if (nodes.isEmpty) {
        setState(() {
          _status = ShellStatus.error;
          _statusMessage = '没有可用节点';
        });
        return;
      }

      // 更新状态：测试延迟
      setState(() {
        _statusMessage = '正在测试节点延迟...';
      });

      // 异步测试延迟，限制测试时间
      await _latencyService.testNodesLatency(nodes).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          // 超时后继续使用第一个节点
        },
      );
      
      final bestNode = _latencyService.findBestNode(nodes) ?? nodes.first;
      
      // 更新状态：正在连接
      setState(() {
        _statusMessage = '正在连接 ${bestNode.name}...';
      });

      final logger = LoggerService();
      await logger.info('RootShell', 'Attempting to connect to ${bestNode.name} (${bestNode.protocol})');
      print('[RootShell] Attempting to connect to ${bestNode.name} (${bestNode.protocol})');
      
      final success = await _vpnService.connect(bestNode).timeout(
        const Duration(seconds: 20), // 增加超时时间，因为 iOS VPN 连接需要时间
        onTimeout: () {
          logger.warning('RootShell', 'Connection timeout (20s) - but VPN may still be connecting');
          print('[RootShell] ⚠️ Connection timeout (20s) - but VPN may still be connecting');
          // 不立即返回 false，等待状态流更新
          return true; // 返回 true 让状态流处理
        },
      );

      await logger.info('RootShell', 'Connection result: $success');
      print('[RootShell] Connection result: $success');
      
      // 如果连接返回 false，说明启动失败
      if (!success) {
        setState(() {
          _status = ShellStatus.error;
          _statusMessage = '连接启动失败，请检查日志';
        });
      } else {
        // 如果返回 true，说明启动成功，等待状态流更新
        // 给状态流一些时间来处理状态变化
        print('[RootShell] ✅ Connection initiated, waiting for status update...');
        // 状态会通过 _onVpnStatusChanged 更新
      }
    } catch (e) {
      setState(() {
        _status = ShellStatus.error;
        _statusMessage = '连接错误: ${e.toString().replaceAll('Exception: ', '')}';
      });
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> _connectNode(ServerNode node) async {
    if (_isConnecting) return;
    _isConnecting = true;
    setState(() {
      _status = ShellStatus.connecting;
      _statusMessage = '正在连接 ${node.name}...';
    });
    try {
      await _vpnService.disconnect();
      final success = await _vpnService.connect(node);
      setState(() {
        _status = success ? ShellStatus.connected : ShellStatus.error;
        _statusMessage = success ? '已连接 ${node.name}' : '连接失败';
      });
    } catch (e) {
      setState(() {
        _status = ShellStatus.error;
        _statusMessage = '连接错误: $e';
      });
    } finally {
      _isConnecting = false;
    }
  }

  bool _isLoadingNodes = false;

  Future<void> _showNodePicker() async {
    if (_isConnecting || _isLoadingNodes) return;
    
    setState(() => _isLoadingNodes = true);
    
    try {
      _nodesCache ??= await _subscriptionService.fetchNodes();
      
      if (!mounted) {
        // Mounted check already covered by logic flow, but good to be safe if async gap exists
        return; 
      }

      final nodes = _nodesCache ?? []; // Local var for safety
      
      // Stop loading before showing modal so UI is clean
      setState(() => _isLoadingNodes = false);

      await showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          if (nodes.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Text('暂无节点', style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return SafeArea(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: nodes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final node = nodes[index];
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: AppColors.border),
                  ),
                  title: Text(node.name, style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(
                    '${node.address}:${node.port} · ${node.protocol.toUpperCase()}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  onTap: () {
                    Navigator.of(context).pop();
                    _connectNode(node);
                  },
                );
              },
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
         setState(() => _isLoadingNodes = false);
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('加载节点失败: $e')),
         );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeDashboard(
        onConnectPressed: _toggleConnection,
        isConnected: _status == ShellStatus.connected,
        isConnecting: _isConnecting || _status == ShellStatus.connecting,
        statusMessage: _statusMessage,
      ),
      PlansScreen(
        onChoose: _openCheckout,
      ),
      AccountScreen(
        onLogout: widget.onLogout,
        connectionStatus: _statusMessage,
        connectionState: _status.name,
        reloadToken: _accountReload,
      ),
    ];

    // 桌面端使用侧边导航
    if (_isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // 侧边导航
            DesktopNav(
              selectedIndex: _index,
              onDestinationSelected: _switchTab,
            ),
            // 主内容区
            Expanded(
              child: Stack(
                children: [
                  // Global Background
                  const Positioned.fill(
                    child: AnimatedMeshBackground(
                      child: SizedBox.expand(),
                    ),
                  ),
                  // 顶部工具栏
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.bug_report, color: AppColors.textPrimary),
                            tooltip: '查看日志',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const LogsScreen()),
                              );
                            },
                          ),
                          IconButton(
                            icon: _isLoadingNodes 
                                ? const SizedBox(
                                    width: 20, 
                                    height: 20, 
                                    child: FluxLoader(size: 20, color: AppColors.textPrimary)
                                  )
                                : const Icon(Icons.storage_rounded, color: AppColors.textPrimary),
                            tooltip: '节点列表',
                            onPressed: _showNodePicker,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Content
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        opacity: _isSwitching ? 0.0 : 1.0,
                        child: IndexedStack(
                          index: _index,
                          children: pages,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 移动端使用底部导航
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.blur_on, color: AppColors.accent),
            const SizedBox(width: 8),
            const Text('Flux'),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.bug_report, color: AppColors.textPrimary),
              tooltip: '查看日志',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LogsScreen()),
                );
              },
            ),
            IconButton(
              icon: _isLoadingNodes 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: FluxLoader(size: 20, color: AppColors.textPrimary)
                    )
                  : const Icon(Icons.storage_rounded, color: AppColors.textPrimary),
              tooltip: '节点列表',
              onPressed: _showNodePicker,
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          // Global Background
          const Positioned.fill(
            child: AnimatedMeshBackground(
              child: SizedBox.expand(),
            ),
          ),
          // Content
          Positioned.fill(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              opacity: _isSwitching ? 0.0 : 1.0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                offset: _isSwitching ? const Offset(0.01, 0.01) : Offset.zero,
                child: IndexedStack(
                  index: _index,
                  children: pages,
                ),
              ),
            ),
          ),
          // Floating Nav Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GlassNavBar(
              selectedIndex: _index,
              onDestinationSelected: _switchTab,
            ),
          ),
        ],
      ),
    );
  }
}
