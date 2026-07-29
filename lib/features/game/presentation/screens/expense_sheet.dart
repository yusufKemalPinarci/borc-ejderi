import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../game_controller.dart';

Future<void> showExpenseSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1C2834),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const ExpenseSheet(),
  );
}

class ExpenseSheet extends ConsumerStatefulWidget {
  const ExpenseSheet({super.key});

  @override
  ConsumerState<ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends ConsumerState<ExpenseSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final wallet =
        ref.watch(gameControllerProvider).asData?.value.hero.wallet ?? 0;
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Yaşam harcaması',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Market, fatura, yol… Kasadan düşer. Borç veya birikime yazılmaz.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Kasa: ${currency.format(wallet)}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Ne için? (opsiyonel)',
              hintText: 'Market, fatura…',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Tutar (TL)'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(
                    _amountCtrl.text.replaceAll(',', '.'),
                  ) ??
                  0;
              if (amount <= 0) return;
              final ok = await ref
                  .read(gameControllerProvider.notifier)
                  .recordLiveExpense(
                    amount: amount,
                    note: _noteCtrl.text,
                  );
              if (!context.mounted) return;
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kasada yeterli para yok')),
                );
                return;
              }
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              messenger.showSnackBar(
                const SnackBar(content: Text('Kayıt alındı · kale güçlendi')),
              );
            },
            child: const Text('Kasadan düş'),
          ),
        ],
      ),
    );
  }
}
