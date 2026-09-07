import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cakeu/core/theme/app_colors.dart';

class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            context,
            icon: Icons.camera_alt_rounded,
            label: 'Scan Struk AI',
            color: AppColors.primary,
            onTap: () => context.go('/chatbot'),
          ),
          _buildActionButton(
            context,
            icon: Icons.add_circle_outline_rounded,
            label: 'Catat Manual',
            color: AppColors.secondary,
            onTap: () => context.push('/transactions/add'),
          ),
          _buildActionButton(
            context,
            icon: Icons.pie_chart_outline_rounded,
            label: 'Laporan',
            color: AppColors.accent,
            onTap: () => context.go('/reports'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
