import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/payment_method.dart';
import '../models/plan.dart';
import '../services/v2board_api.dart';
import '../theme/app_colors.dart';
import '../widgets/glow_button.dart';
import '../widgets/gradient_card.dart';
import '../widgets/section_header.dart';
import '../widgets/flux_loader.dart';
import '../l10n/generated/app_localizations.dart';

import 'order_success_screen.dart';

class OrdersScreen extends StatefulWidget {
  final Plan? selectedPlan;
  final VoidCallback? onPickPlan;
  final VoidCallback? onPaid;
  const OrdersScreen({
    super.key,
    this.selectedPlan,
    this.onPickPlan,
    this.onPaid,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _api = V2BoardApi();
  final _couponController = TextEditingController();
  String _period = 'month_price';
  bool _loading = false;
  PaymentMethod? _method;
  String? _message;
  Future<List<PaymentMethod>>? _methodsFuture;
  List<PaymentMethod>? _cachedMethods;

  bool _isPolling = false;

  @override
  void initState() {
    super.initState();
    _loadMethodsData();
    final allowed = _availablePeriods(widget.selectedPlan);
    _period = allowed.isNotEmpty ? allowed.first : 'month_price';
  }

  @override
  void didUpdateWidget(covariant OrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPlan?.id != widget.selectedPlan?.id) {
      final allowed = _availablePeriods(widget.selectedPlan);
      if (!allowed.contains(_period)) {
        setState(() {
          _period = allowed.isNotEmpty ? allowed.first : 'month_price';
        });
      }
    }
  }

  List<String> _availablePeriods(Plan? plan) {
    if (plan == null) return const ['month_price'];
    final items = <String>[];
    // 显示所有周期选项，即使价格为0也显示（允许免费套餐）
    if (plan.monthPrice != null) items.add('month_price');
    if (plan.quarterPrice != null) items.add('quarter_price');
    if (plan.halfYearPrice != null) items.add('half_year_price');
    if (plan.yearPrice != null) items.add('year_price');
    if (plan.twoYearPrice != null) items.add('two_year_price');
    if (plan.threeYearPrice != null) items.add('three_year_price');
    if (plan.onetimePrice != null) items.add('onetime_price');
    if (plan.resetPrice != null) items.add('reset_price');
    return items.isEmpty ? const ['month_price'] : items;
  }

  String _periodLabel(String value) {
    switch (value) {
      case 'month_price':
        return AppLocalizations.of(context)!.monthPrice;
      case 'quarter_price':
        return AppLocalizations.of(context)!.quarterPrice;
      case 'half_year_price':
        return AppLocalizations.of(context)!.halfYearPrice;
      case 'year_price':
        return AppLocalizations.of(context)!.yearPrice;
      case 'two_year_price':
        return AppLocalizations.of(context)!.twoYearPrice;
      case 'three_year_price':
        return AppLocalizations.of(context)!.threeYearPrice;
      case 'onetime_price':
        return AppLocalizations.of(context)!.onetimePrice;
      case 'reset_price':
        return AppLocalizations.of(context)!.resetPrice;
      default:
        return value;
    }
  }



  void _loadMethodsData() {
    _methodsFuture = _loadMethods().then((methods) {
      if (mounted) {
        _cachedMethods = methods;
      }
      return methods;
    });
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<List<PaymentMethod>> _loadMethods() async {
    final data = await _api.getPaymentMethods();
    final list = (data['data'] as List? ?? [])
        .map((item) => PaymentMethod.fromJson(item as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<void> _createOrder() async {
    final plan = widget.selectedPlan;
    if (plan == null) {
      setState(() => _message = AppLocalizations.of(context)!.selectPlanFirst);
      return;
    }
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      // 1. 创建订单
      final data = await _api.saveOrder(
        plan.id,
        _period,
        couponCode: _couponController.text.trim().isEmpty ? null : _couponController.text.trim(),
      );
      final tradeNo = data['data']?.toString();
      if (tradeNo == null || tradeNo.isEmpty) {
        if (mounted) {
          setState(() => _message = '${AppLocalizations.of(context)!.orderCreationFail}: ${AppLocalizations.of(context)!.noOrderId}');
        }
        return;
      }
      
      // 自动发起支付流程
      await _checkoutOrder(tradeNo, _method?.id);
    } catch (e) {
      // 检查是否是有未支付订单的错误
      final errorMsg = e.toString();
      final unpaidTradeNo = _extractUnpaidTradeNo(errorMsg);
      
      if (unpaidTradeNo != null && mounted) {
        // 显示继续支付/取消订单对话框
        await _showUnpaidOrderDialog(unpaidTradeNo);
      } else if (mounted) {
        setState(() => _message = '${AppLocalizations.of(context)!.purchaseFailed}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
  
  /// 从错误信息中提取未支付订单号
  String? _extractUnpaidTradeNo(String errorMsg) {
    // 尝试匹配订单号格式（通常是数字）
    final regex = RegExp(r'(\d{20,})');
    final match = regex.firstMatch(errorMsg);
    if (match != null) {
      return match.group(1);
    }
    // 如果包含"待支付"或"未支付"关键词，但没有订单号，返回 placeholder
    if (errorMsg.contains(AppLocalizations.of(context)!.unpaidOrder) || errorMsg.contains(AppLocalizations.of(context)!.unpaidOrder) || errorMsg.contains('unpaid')) {
      return 'UNKNOWN';
    }
    return null;
  }
  
  /// 显示未支付订单处理对话框
  Future<void> _showUnpaidOrderDialog(String tradeNo) async {
    final isUnknown = tradeNo == 'UNKNOWN';
    
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context)!.unpaidOrder,
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: Text(
          isUnknown 
            ? AppLocalizations.of(context)!.unpaidOrderMessage
            : '${AppLocalizations.of(context)!.order}: $tradeNo\n\n${AppLocalizations.of(context)!.payment}...',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text(
              AppLocalizations.of(context)!.cancelOrder,
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'continue'),
            child: Text(
              AppLocalizations.of(context)!.continuePayment,
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
    
    if (result == 'cancel' && !isUnknown) {
      // 取消订单
      await _cancelOrder(tradeNo);
    } else if (result == 'continue' && !isUnknown) {
      // 继续支付
      await _checkoutOrder(tradeNo, _method?.id);
    }
  }
  
  /// 取消订单
  Future<void> _cancelOrder(String tradeNo) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _message = AppLocalizations.of(context)!.cancelingOrder;
    });
    try {
      await _api.cancelOrder(tradeNo);
      if (mounted) {
        setState(() => _message = AppLocalizations.of(context)!.orderCanceled);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _message = '${AppLocalizations.of(context)!.cancelOrder}失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _checkoutOrder(String tradeNo, int? methodId) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _message = AppLocalizations.of(context)!.submittingOrder;
    });
    try {
      // 1. 提交支付请求
      final result = await _api.checkoutOrder(tradeNo, methodId ?? 0);
      
      // 2. 检查提交结果
      final data = result['data'];

      // 请求完成后立即取消 loading，避免按钮一直转圈
      if (mounted) {
        setState(() => _loading = false);
      }
      
      // 如果返回的是 URL，直接跳转支付
      if (data is String && (data.startsWith('http') || data.startsWith('alipays://') || data.startsWith('weixin://'))) {
         final uri = Uri.parse(data);
         if (await canLaunchUrl(uri)) {
           await launchUrl(uri, mode: LaunchMode.externalApplication);
         } else {
           throw Exception('${AppLocalizations.of(context)!.cannotOpenPaymentLink}: $data');
         }
      } else {
        // 余额支付或其他同步支付方式
        final success = data == true || data == 1;
        if (!success) {
           // 检查 type，有些接口 type -1 表示错误
           throw Exception('${AppLocalizations.of(context)!.paymentRequestFailed}: ${result['message'] ?? '未知错误'}');
        }
      }

      // 3. 开始轮询检查订单状态(后台执行)
      _startPolling(tradeNo);

    } catch (e) {
      if (mounted) {
        setState(() {
           _message = '${AppLocalizations.of(context)!.paymentException}: $e';
           _loading = false;
        });
      }
    }
  }

  Future<void> _startPolling(String tradeNo) async {
      if (_isPolling || !mounted) return;
      _isPolling = true;

      if (mounted) {
        setState(() => _message = AppLocalizations.of(context)!.confirmPaymentResult);
      }

      const maxRetries = 60; // 最多轮询 60 次
      const interval = Duration(seconds: 1);
      bool orderPaid = false;

      try {
        for (var i = 0; i < maxRetries; i++) {
          if (!mounted) break;
          
          final checkRes = await _api.checkOrder(tradeNo);
          // API 返回: {"data":1} 表示已支付/开通成功; {"data":0} 表示未支付
          final status = checkRes['data'];
          print('Order check status: $status (${status.runtimeType})');
          
          if (status == 1 || status == true || status == '1' || status == 3 || status == '3') {
            orderPaid = true;
            break;
          }

          await Future.delayed(interval);
        }

        if (mounted) {
          if (orderPaid) {
            setState(() {
              _message = AppLocalizations.of(context)!.orderSuccess;
            });
            if (mounted) {
              widget.onPaid?.call();
              
              // 跳转到成功页面
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderSuccessScreen(
                    plan: widget.selectedPlan!,
                    period: _period,
                    tradeNo: tradeNo,
                  ),
                ),
              );
              
              if (mounted && result == true) {
                Navigator.of(context).pop(true);
              }
            }
          } else {
            setState(() {
              _message = AppLocalizations.of(context)!.paymentResultTimeout;
            });
          }
        }
      } catch (e) {
        if (mounted) {
           setState(() => _message = '${AppLocalizations.of(context)!.queryStatusFailed}: $e');
        }
      } finally {
        _isPolling = false;
      }
  }



  @override
  Widget build(BuildContext context) {
    final methodsFuture = _methodsFuture ??= _loadMethods().then((methods) {
      if (mounted) {
        _cachedMethods = methods;
      }
      return methods;
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.payment),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.heroGlow),
        child: FutureBuilder<List<PaymentMethod>>(
          future: methodsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              final err = snapshot.error;
              final message =
                  err is V2BoardApiException ? err.message : AppLocalizations.of(context)!.networkErrorRetry;
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      style: const TextStyle(color: AppColors.accentWarm),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _cachedMethods = null;
                          _loadMethodsData();
                        });
                      },
                      child: Text(AppLocalizations.of(context)!.retry),
                    ),
                  ],
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: FluxLoader());
            }
            final methods = snapshot.data ?? [];
            if (methods.isNotEmpty && _method == null) {
              _method = methods.first;
            }
            final periods = _availablePeriods(widget.selectedPlan);
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SectionHeader(title: AppLocalizations.of(context)!.orderAndPay),
                const SizedBox(height: 12),
                if (widget.selectedPlan == null) ...[
                  GradientCard(
                    child: Row(
                      children: [
                        const Icon(Icons.layers, color: AppColors.accent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.selectPlanPrompt,
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onPickPlan,
                          child: Text(AppLocalizations.of(context)!.goSelect),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                GradientCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.selectedPlan?.name ?? AppLocalizations.of(context)!.noPlanSelected,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        key: ValueKey(_period),
                        initialValue: _period,
                        items: periods
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(_periodLabel(p)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _period = value);
                        },
                        decoration: InputDecoration(labelText: AppLocalizations.of(context)!.subscriptionPeriod),
                      ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _couponController,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.coupon),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: GlowButton(
                      label: AppLocalizations.of(context)!.buyNow,
                      onPressed: _loading ? null : _createOrder,
                      isLoading: _loading,
                      icon: Icons.shopping_cart_checkout,
                    ),
                  ),
                ],
              ),
            ),
            if (methods.isNotEmpty) ...[
              const SizedBox(height: 18),
              SectionHeader(title: AppLocalizations.of(context)!.payMethod),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: methods.map((method) {
                  final selected = _method?.id == method.id;
                  return GestureDetector(
                    onTap: () => setState(() => _method = method),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.surfaceAlt : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected ? AppColors.accent : AppColors.border,
                        ),
                      ),
                      child: Text(method.name),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (_message != null) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _message!,
                  style: const TextStyle(color: AppColors.accentWarm),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
              ],
            );
          },
        ),
      ),
    );
  }
}
