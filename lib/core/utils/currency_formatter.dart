import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Utility class for formatting currency values in Indonesian Rupiah.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  /// Formats a number as Indonesian Rupiah.
  ///
  /// Example: `format(10000)` → `"Rp10.000"`
  static String format(num amount) {
    return _formatter.format(amount);
  }

  /// Alias for format
  static String formatRupiah(num amount) {
    return _formatter.format(amount);
  }

  /// Formats with a sign prefix for display (e.g., "+Rp10.000" or "-Rp5.000").
  static String formatWithSign(num amount) {
    final formatted = _formatter.format(amount.abs());
    if (amount >= 0) {
      return '+$formatted';
    }
    return '-$formatted';
  }

  /// Compact format for large numbers (e.g., "10rb", "1,5jt").
  static String formatCompact(num amount) {
    if (amount.abs() >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}M';
    } else if (amount.abs() >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount.abs() >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return amount.toString();
  }
}

/// Formatter untuk input TextField agar otomatis memformat titik ribuan (misal: 100000 -> 100.000)
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final cleanDigits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanDigits.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    final number = int.tryParse(cleanDigits) ?? 0;
    final formatted = number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
