import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Text input formatter that adds thousand separators while typing.
///
/// - Supports optional decimal part with a configurable maximum number
///   of decimal digits (defaults to 2).
/// - Does not include a currency symbol; combine with prefix/suffix UI as needed.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  ThousandsSeparatorInputFormatter({this.maxDecimalDigits = 2});

  final int maxDecimalDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;

    // Allow empty value
    if (raw.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Remove all non-digit and non-decimal separator characters
    final sanitized = raw.replaceAll(',', '');

    // If input is just a decimal point, keep as "0."
    if (sanitized == '.') {
      return const TextEditingValue(text: '0.');
    }

    // Split integer and fractional parts
    String integerPart;
    String fractionalPart = '';
    if (sanitized.contains('.')) {
      final parts = sanitized.split('.');
      integerPart = parts[0];
      fractionalPart = parts.length > 1 ? parts[1] : '';
      if (fractionalPart.length > maxDecimalDigits) {
        fractionalPart = fractionalPart.substring(0, maxDecimalDigits);
      }
    } else {
      integerPart = sanitized;
    }

    // Avoid leading zeros like 0001 → 1, but keep 0 if empty
    if (integerPart.isEmpty) integerPart = '0';
    integerPart = int.tryParse(integerPart)?.toString() ?? '0';

    final formatter = NumberFormat.decimalPattern();
    final formattedInteger = formatter.format(int.parse(integerPart));

    final formatted = fractionalPart.isNotEmpty
        ? '$formattedInteger.$fractionalPart'
        : (sanitized.endsWith('.') ? '$formattedInteger.' : formattedInteger);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
