import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../game_controller.dart';

Future<void> showNewDragonSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1C2834),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const NewDragonSheet(),
  );
}

class NewDragonSheet extends ConsumerStatefulWidget {
  const NewDragonSheet({super.key});

  @override
  ConsumerState<NewDragonSheet> createState() => _NewDragonSheetState();
}

class _NewDragonSheetState extends ConsumerState<NewDragonSheet> {
  final _nameCtrl = TextEditingController(text: 'Kredi kartı');
  final _amountCtrl = TextEditingController();
  final _plannedCtrl = TextEditingController();
  TargetKind _kind = TargetKind.debt;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _plannedCtrl.dispose();
    super.dispose();
  }

  void _setKind(TargetKind kind) {
    setState(() {
      _kind = kind;
      _nameCtrl.text = kind == TargetKind.savings ? 'Acil fon' : 'Kredi kartı';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final isSavings = _kind == TargetKind.savings;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isSavings ? 'Birikim hedefi' : 'Borç ekle',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 14),
            SegmentedButton<TargetKind>(
              segments: const [
                ButtonSegment(
                  value: TargetKind.debt,
                  label: Text('Borç'),
                  icon: Icon(Icons.whatshot_outlined),
                ),
                ButtonSegment(
                  value: TargetKind.savings,
                  label: Text('Birikim'),
                  icon: Icon(Icons.savings_outlined),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (value) => _setKind(value.first),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: isSavings ? 'Hedef adı' : 'Borç adı',
                hintText: isSavings ? 'Tatil, acil fon…' : 'Kart, ihtiyaç…',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isSavings ? 'Hedef tutar (TL)' : 'Kalan bakiye (TL)',
              ),
            ),
            if (!isSavings) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _plannedCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Aylık ödeme hedefi (TL)',
                  hintText: 'İsteğe bağlı',
                  helperText: 'Boş bırakırsan gelirin %30’u ile tahmin edilir',
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(
                      _amountCtrl.text.replaceAll(',', '.'),
                    ) ??
                    0;
                if (amount <= 0) return;
                final planned = double.tryParse(
                      _plannedCtrl.text.replaceAll(',', '.'),
                    ) ??
                    0;
                await ref.read(gameControllerProvider.notifier).addTarget(
                      name: _nameCtrl.text,
                      amount: amount,
                      kind: _kind,
                      plannedMonthly: planned,
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(isSavings ? 'Hedefi aç' : 'Borcu ekle'),
            ),
          ],
        ),
      ),
    );
  }
}
