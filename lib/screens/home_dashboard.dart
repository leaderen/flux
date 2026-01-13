import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../l10n/generated/app_localizations.dart';

class HomeDashboard extends StatefulWidget {
  final VoidCallback onConnectPressed;
  final bool isConnected;
  final bool isConnecting;
  final String statusMessage;

  const HomeDashboard({
    super.key,
    required this.onConnectPressed,
    required this.isConnected,
    this.isConnecting = false,
    this.statusMessage = '',
  });

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  @override
  Widget build(BuildContext context) {
    final isBusy = widget.isConnecting;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Simplified Button (Flat Style)
            GestureDetector(
              onTap: isBusy ? null : widget.onConnectPressed,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isConnected 
                      ? Colors.green.withOpacity(0.1) 
                      : AppColors.surface,
                  border: Border.all(
                    color: widget.isConnected 
                        ? Colors.green 
                        : (isBusy ? AppColors.accent : AppColors.border),
                    width: isBusy ? 2 : 4,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.power_settings_new_rounded,
                  size: 64,
                  color: widget.isConnected 
                      ? Colors.green 
                      : (isBusy ? AppColors.accent : AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.statusMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: widget.isConnected ? Colors.green : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Simplified Grid
            _buildFeatureRow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: [
            _buildFeatureTile(Icons.security, AppLocalizations.of(context)!.secureEncryption),
            _buildFeatureTile(Icons.speed, AppLocalizations.of(context)!.fastConnection),
            _buildFeatureTile(Icons.lock_outline, AppLocalizations.of(context)!.privacyProtection),
            _buildFeatureTile(Icons.public, AppLocalizations.of(context)!.globalNodes),
          ],
        );
      },
    );
  }

  Widget _buildFeatureTile(IconData icon, String title) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
