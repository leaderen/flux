import 'dart:io';
import '../models/server_node.dart';

/// 延迟测试服务
class LatencyTestService {
  /// 测试单个节点的延迟
  Future<int?> testLatency(ServerNode node, {Duration timeout = const Duration(seconds: 5)}) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      final socket = await Socket.connect(
        node.address,
        node.port,
        timeout: timeout,
      ).timeout(timeout);
      
      stopwatch.stop();
      final latency = stopwatch.elapsedMilliseconds;
      
      await socket.close();
      
      return latency;
    } catch (e) {
      // 连接失败，返回null表示超时或不可达
      return null;
    }
  }

  /// 批量测试节点延迟
  Future<void> testNodesLatency(List<ServerNode> nodes, {
    Function(ServerNode, int?)? onProgress,
  }) async {
    // 限制测试数量，避免测试时间过长
    final nodesToTest = nodes.length > 20 ? nodes.take(20).toList() : nodes;
    
    for (var node in nodesToTest) {
      final latency = await testLatency(node);
      node.latency = latency;
      
      if (onProgress != null) {
        onProgress(node, latency);
      }
    }
  }

  /// 找到延迟最低的节点
  /// 返回选中的节点和选择原因
  Map<String, dynamic>? findBestNodeWithReason(List<ServerNode> nodes) {
    if (nodes.isEmpty) return null;
    
    // 过滤掉延迟为null的节点
    final validNodes = nodes.where((node) => node.latency != null).toList();
    
    if (validNodes.isEmpty) {
      // 如果没有测试成功的节点，随机选择一个（避免总是选第一个）
      final randomIndex = DateTime.now().millisecondsSinceEpoch % nodes.length;
      return {
        'node': nodes[randomIndex],
        'reason': 'no_valid_latency',
        'total_nodes': nodes.length,
        'tested_nodes': 0,
      };
    }
    
    // 按延迟排序，返回最低延迟的节点
    validNodes.sort((a, b) => (a.latency ?? 999999).compareTo(b.latency ?? 999999));
    
    return {
      'node': validNodes.first,
      'reason': 'lowest_latency',
      'latency': validNodes.first.latency,
      'total_nodes': nodes.length,
      'tested_nodes': validNodes.length,
      'top_3_latencies': validNodes.take(3).map((n) => {
        'name': n.name,
        'latency': n.latency,
      }).toList(),
    };
  }

  /// 找到延迟最低的节点（保持向后兼容）
  ServerNode? findBestNode(List<ServerNode> nodes) {
    final result = findBestNodeWithReason(nodes);
    return result?['node'] as ServerNode?;
  }
}
