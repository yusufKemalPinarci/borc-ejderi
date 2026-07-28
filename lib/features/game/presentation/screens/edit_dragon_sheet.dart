import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/models.dart';
import '../game_controller.dart';

Future<void> showEditDragonSheet(
  BuildContext context,
  DebtDragon dragon,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1C2834),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => EditDragonSheet(dragon: dragon),
  );
}

class EditDragonSheet extends ConsumerStatefulWidget {
  const EditDragonSheet({super.key, required this.dragon});

  final DebtDragon dragon;

  @override
  ConsumerState<EditDragonSheet> createState() => _EditDragonSheetState();
}

class _EditDragonSheetState extends ConsumerState<EditDragonSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _balanceCtrl;
  late final TextEditingController _totalCtrl;
  late final TextEditingController _rateCtrl;
  late final TextEditingController _minCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.dragon;
    _nameCtrl = TextEditingController(text: d.name);
    _balanceCtrl = TextEditingController(
      text: d.currentHp.toStringAsFixed(0),
    );
    _totalCtrl = TextEditingController(
      text: d.totalHp.toStringAsFixed(0),
    );
    _rateCtrl = TextEditingController(
      text: d.interestRate.toStringAsFixed(1),
    );
    _minCtrl = TextEditingController(
      text: d.minPayment > 0 ? d.minPayment.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    _totalCtrl.dispose();
    _rateCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final balance = double.tryParse(_balanceCtrl.text.replaceAll(',', '.'));
    final total = double.tryParse(_totalCtrl.text.replaceAll(',', '.'));
    final rate = double.tryParse(_rateCtrl.text.replaceAll(',', '.')) ?? 0;
    final min = double.tryParse(_minCtrl.text.replaceAll(',', '.')) ?? 0;
    if (balance == null || balance < 0) return;

    await ref.read(gameControllerProvider.notifier).updateDragon(
          id: widget.dragon.id,
          name: _nameCtrl.text,
          balance: balance,
          totalHp: total,
          interestRate: rate,
          minPayment: min,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final d = widget.dragon;
    final isDebt = d.isDebt;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isDebt ? 'Ejderhayı düzenle' : 'Hedefi düzenle',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'İsim'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _balanceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isDebt ? 'Kalan bakiye (TL)' : 'Biriken (TL)',
              ),
            ),
            if (!isDebt) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _totalCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Hedef tutar (TL)',
                ),
              ),
            ],
            if (isDebt) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _rateCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Yıllık faiz %',
                  helperText: 'Sıralama ve borçsuz tarih için',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _minCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Aylık asgari ödeme (TL)',
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showExtraPaymentSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1C2834),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const ExtraPaymentSheet(),
  );
}

class ExtraPaymentSheet extends ConsumerStatefulWidget {
  const ExtraPaymentSheet({super.key});

  @override
  ConsumerState<ExtraPaymentSheet> createState() => _ExtraPaymentSheetState();
}

class _ExtraPaymentSheetState extends ConsumerState<ExtraPaymentSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final game = ref.read(gameControllerProvider).asData?.value;
      if (game == null || !mounted) return;
      final value = game.extraMonthlyPayment ?? game.resolvedExtraMonthly;
      _ctrl.text = value > 0 ? value.toStringAsFixed(0) : '';
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameControllerProvider).asData?.value;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final mins = game?.totalMinPayments ?? 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Aylık ekstra ateş',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Asgari toplam ${currency.format(mins)}. '
            'Üstüne eklediğin tutar odak ejderhaya gider; '
            'bitince bir sonrakine yuvarlanır.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Ekstra (TL / ay)',
              hintText: 'örn. 1500',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              final v = double.tryParse(_ctrl.text.replaceAll(',', '.'));
              await ref
                  .read(gameControllerProvider.notifier)
                  .setExtraMonthlyPayment(v);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Kaydet'),
          ),
          TextButton(
            onPressed: () async {
              await ref
                  .read(gameControllerProvider.notifier)
                  .setExtraMonthlyPayment(null);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Otomatik tahmine dön'),
          ),
        ],
      ),
    );
  }
}
