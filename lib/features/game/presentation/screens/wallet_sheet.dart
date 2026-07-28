import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../game_controller.dart';

Future<void> showWalletSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1C2834),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const WalletSheet(),
  );
}

class WalletSheet extends ConsumerStatefulWidget {
  const WalletSheet({super.key});

  @override
  ConsumerState<WalletSheet> createState() => _WalletSheetState();
}

class _WalletSheetState extends ConsumerState<WalletSheet> {
  late final TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    final hero = ref.read(gameControllerProvider).asData?.value.hero;
    final suggested = hero != null && hero.monthlyBudget > 0
        ? hero.monthlyBudget.toStringAsFixed(0)
        : '10000';
    _amountCtrl = TextEditingController(text: suggested);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final hero = ref.watch(gameControllerProvider).asData?.value.hero;
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Gelir yükle',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Aylık geliri kasaya ekle. Sonra odak borca ödeme, '
            'yaşam harcaması veya birikim kaydı gir.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (hero != null) ...[
            const SizedBox(height: 12),
            Text(
              'Şu an kasa: ${currency.format(hero.wallet)}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Yüklenecek tutar (TL)',
              hintText: 'örn. 15000',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(
                    _amountCtrl.text.replaceAll(',', '.'),
                  ) ??
                  0;
              if (amount <= 0) return;
              await ref
                  .read(gameControllerProvider.notifier)
                  .loadMonthlyBudget(amount);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Kasaya ekle'),
          ),
        ],
      ),
    );
  }
}
