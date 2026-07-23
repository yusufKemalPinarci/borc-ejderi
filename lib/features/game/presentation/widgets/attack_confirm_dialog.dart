import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';

Future<bool> showAttackConfirmDialog({
  required BuildContext context,
  required double amount,
  required double remainingHp,
}) async {
  final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  final pct = remainingHp <= 0 ? 100.0 : (amount / remainingHp * 100);
  final overkill = amount > remainingHp;

  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppTheme.slate,
        title: const Text('Emin misin?'),
        content: Text(
          overkill
              ? '${currency.format(amount)} giriyorsun; ejderhanın kalan canı '
                  '${currency.format(remainingHp)}. Bu darbe ejderhayı bitirir.'
              : '${currency.format(amount)}, kalan canın '
                  '%${pct.toStringAsFixed(0)} kadarı. Yanlışlıkla mı girdin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yine de vur'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
