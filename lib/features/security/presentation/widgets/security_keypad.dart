import 'package:flutter/material.dart';
import 'package:cakeu/core/theme/app_colors.dart';

/// Reusable indicator dots for PIN inputs.
class PinIndicatorDots extends StatelessWidget {
  final int totalDots;
  final int filledDots;
  final double dotSize;
  final double spacing;
  final Color activeColor;
  final Color inactiveColor;

  const PinIndicatorDots({
    super.key,
    this.totalDots = 6,
    required this.filledDots,
    this.dotSize = 16,
    this.spacing = 8,
    this.activeColor = AppColors.primary,
    this.inactiveColor = AppColors.border,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalDots, (index) {
        final isFilled = index < filledDots;
        return Container(
          margin: EdgeInsets.symmetric(horizontal: spacing),
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? activeColor : inactiveColor,
          ),
        );
      }),
    );
  }
}

/// Unified 4x3 Security Keypad widget used across PIN setup and PIN verification screens.
class SecurityKeypad extends StatelessWidget {
  final ValueChanged<String> onKeyPressed;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometricPressed;
  final bool showBiometric;
  final double buttonWidth;
  final double buttonHeight;
  final double verticalPadding;
  final double fontSize;

  const SecurityKeypad({
    super.key,
    required this.onKeyPressed,
    required this.onBackspace,
    this.onBiometricPressed,
    this.showBiometric = false,
    this.buttonWidth = 74,
    this.buttonHeight = 62,
    this.verticalPadding = 6,
    this.fontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      [showBiometric ? 'biometric' : '', '0', 'backspace'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows)
          Padding(
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((key) => _buildKey(context, key)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildKey(BuildContext context, String key) {
    if (key.isEmpty) {
      return SizedBox(width: buttonWidth, height: buttonHeight);
    }

    if (key == 'biometric') {
      return InkWell(
        onTap: onBiometricPressed,
        borderRadius: BorderRadius.circular(buttonHeight / 2),
        child: SizedBox(
          width: buttonWidth,
          height: buttonHeight,
          child: const Center(
            child: Icon(
              Icons.fingerprint_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
        ),
      );
    }

    if (key == 'backspace') {
      return InkWell(
        onTap: onBackspace,
        borderRadius: BorderRadius.circular(buttonHeight / 2),
        child: SizedBox(
          width: buttonWidth,
          height: buttonHeight,
          child: const Center(
            child: Icon(
              Icons.backspace_outlined,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => onKeyPressed(key),
      borderRadius: BorderRadius.circular(buttonHeight / 2),
      child: Container(
        width: buttonWidth,
        height: buttonHeight,
        alignment: Alignment.center,
        child: Text(
          key,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
