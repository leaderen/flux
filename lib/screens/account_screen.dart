import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/user_info.dart';
import '../services/v2board_api.dart';
import '../services/api_config.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/animated_card.dart';
import '../widgets/staggered_list.dart';
import '../widgets/section_header.dart';
import '../widgets/flux_loader.dart';

class AccountScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final String connectionStatus;
  final String connectionState;
  final int reloadToken;
  const AccountScreen({
    super.key,
    required this.onLogout,
    required this.connectionStatus,
    required this.connectionState,
    this.reloadToken = 0,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _api = V2BoardApi();
  late Future<Map<String, dynamic>> _accountFuture;

  @override
  void initState() {
    super.initState();
    _accountFuture = _loadAccount();
  }

  @override
  void didUpdateWidget(covariant AccountScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadToken != widget.reloadToken) {
      setState(() {
        _accountFuture = _loadAccount();
      });
    }
  }

  Future<Map<String, dynamic>> _loadAccount() async {
    // 确保 token 已加载
    final config = ApiConfig();
    await config.refreshAuthCache();
    
    final results = await Future.wait([
      _api.getUserInfo(),
      _api.getUserCommonConfig(),
      _api.getUserSubscribe(), // Fetch subscription info
    ]);
    return {
      'user': UserInfo.fromJson(results[0]['data'] ?? {}),
      'config': results[1]['data'] ?? {},
      'subscribe': results[2]['data'] ?? {},
    };
  }

  Future<void> _logout() async {
    // 用户反馈：不用走 logout 接口，直接清除本地状态跳转
    await ApiConfig().clearAuth();
    if (mounted) widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _accountFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final err = snapshot.error;
          final statusCode = err is V2BoardApiException ? err.statusCode : null;
          final isAuthExpired = statusCode == 401 || statusCode == 403;
          String message = err is V2BoardApiException
              ? err.message
              : AppLocalizations.of(context)!.networkError;
          
          // 如果错误信息包含 "token is null"，提供更友好的提示
          if (message.toLowerCase().contains('token is null') || 
              message.toLowerCase().contains('token') && message.toLowerCase().contains('null')) {
            message = AppLocalizations.of(context)!.tokenExpiredMsg;
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAuthExpired ? Icons.error_outline : Icons.warning_amber_rounded,
                    size: 48,
                    color: AppColors.accentWarm,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: const TextStyle(
                      color: AppColors.accentWarm,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => setState(() {
                          _accountFuture = _loadAccount();
                        }),
                        child: Text(AppLocalizations.of(context)!.retry),
                      ),
                      if (isAuthExpired) ...[
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            await ApiConfig().clearAuth();
                            if (context.mounted) widget.onLogout();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                          ),
                          child: Text(AppLocalizations.of(context)!.login),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: FluxLoader());
        }
        final user = snapshot.data!['user'] as UserInfo;

        // final config = snapshot.data!['config'] as Map<String, dynamic>;
        
        final subInfo = snapshot.data!['subscribe'] as Map<String, dynamic>? ?? {};
        // Calculate usage if available
        final upload = subInfo['u'] as int? ?? 0;
        final download = subInfo['d'] as int? ?? 0;
        final total = subInfo['transfer_enable'] as int? ?? 1;
        final used = upload + download;
        final percent = (used / total).clamp(0.0, 1.0);

        return StaggeredList(
          padding: const EdgeInsets.all(20),
          children: [
            SectionHeader(title: AppLocalizations.of(context)!.connectionStatus),
            const SizedBox(height: 16),
            AnimatedCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                   // ... (Status dot logic - keep existing or simple)
                   AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: widget.connectionState == 'connected'
                          ? AppColors.success
                          : widget.connectionState == 'connecting'
                              ? AppColors.accent
                              : widget.connectionState == 'error'
                                  ? AppColors.danger
                                  : AppColors.textSecondary,
                      shape: BoxShape.circle,
                      boxShadow: [
                         if (widget.connectionState == 'connected')
                          BoxShadow(color: AppColors.success.withValues(alpha: 0.4), blurRadius: 8),
                      ],
                    ),
                   ),
                   const SizedBox(width: 12),
                   Text(widget.connectionStatus, style: TextStyle(color: AppColors.textPrimary)),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            SectionHeader(title: AppLocalizations.of(context)!.subscription),
            const SizedBox(height: 16),
            AnimatedCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.star, color: AppColors.accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(
                             subInfo['plan'] != null ? (subInfo['plan']['name'] ?? AppLocalizations.of(context)!.unknownPlan) : AppLocalizations.of(context)!.noSubscription,
                             style: const TextStyle(
                               color: AppColors.textPrimary,
                               fontWeight: FontWeight.bold,
                               fontSize: 16,
                             ),
                           ),
                           if (subInfo['expired_at'] != null)
                             Text(
                               '${AppLocalizations.of(context)!.expireDate}: ${Formatters.formatEpoch(subInfo['expired_at'])}',
                               style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                             ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent,
                      backgroundColor: AppColors.surfaceAlt,
                      valueColor: AlwaysStoppedAnimation(AppColors.accent),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Text(
                         '${AppLocalizations.of(context)!.usedTraffic}: ${Formatters.formatBytes(used)}',
                         style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                       ),
                       Text(
                         '${AppLocalizations.of(context)!.totalTraffic}: ${Formatters.formatBytes(total)}',
                         style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                       ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (subInfo['reset_day'] != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.refresh, size: 16, color: AppColors.accentWarm),
                          const SizedBox(width: 8),
                          Text(
                            '${AppLocalizations.of(context)!.trafficResetInfo} ${subInfo['reset_day']}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            SectionHeader(title: AppLocalizations.of(context)!.basicInfo),
            const SizedBox(height: 16),
            AnimatedCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildInfoRow(context, Icons.email, AppLocalizations.of(context)!.email, user.email),
                   const SizedBox(height: 12),
                   _buildInfoRow(context, Icons.account_balance_wallet, AppLocalizations.of(context)!.balance, Formatters.formatCurrency(user.balance)),
                ],
              ),
            ),

            // 法律信息和关于
            const SizedBox(height: 24),
            AnimatedCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildLinkRow(
                    context,
                    Icons.description_outlined,
                    AppLocalizations.of(context)!.termsOfService,
                    () => _openUrl(''),
                  ),
                  const Divider(height: 24, color: AppColors.border),
                  _buildLinkRow(
                    context,
                    Icons.privacy_tip_outlined,
                    AppLocalizations.of(context)!.privacyPolicy,
                    () => _openUrl(''),
                  ),
                  const Divider(height: 24, color: AppColors.border),
                  _buildLinkRow(
                    context,
                    Icons.info_outline,
                    '${AppLocalizations.of(context)!.about} Flux',
                    () => _showAboutDialog(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            AnimatedCard(
              onTap: _logout,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: AppColors.danger, size: 20),
                  SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.logout,
                    style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            // 版本号
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Flux v1.0.0',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.accent.withValues(alpha: 0.7)),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
  
  Widget _buildLinkRow(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.accent.withOpacity(0.7)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
  
  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
  
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.blur_on, color: AppColors.accent, size: 28),
            SizedBox(width: 12),
            Text('Flux', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.aboutFluxDesc,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _buildAboutFeature(Icons.hub_rounded, AppLocalizations.of(context)!.ixpAccess, AppLocalizations.of(context)!.ixpAccessDesc),
            const SizedBox(height: 12),
            _buildAboutFeature(Icons.speed_rounded, AppLocalizations.of(context)!.fastStable, AppLocalizations.of(context)!.fastStableDesc),
            const SizedBox(height: 12),
            _buildAboutFeature(Icons.security_rounded, AppLocalizations.of(context)!.noLogs, AppLocalizations.of(context)!.noLogsDesc),
            const SizedBox(height: 12),
            _buildAboutFeature(Icons.lock_rounded, AppLocalizations.of(context)!.secureEncryption, AppLocalizations.of(context)!.strongEncryptionDesc),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAboutFeature(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.accent),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
