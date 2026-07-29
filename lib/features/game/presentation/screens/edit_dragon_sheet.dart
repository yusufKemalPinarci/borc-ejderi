import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  late final TextEditingController _plannedCtrl;

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
    _plannedCtrl = TextEditingController(
      text: d.plannedMonthly > 0 ? d.plannedMonthly.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    _totalCtrl.dispose();
    _plannedCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final balance = double.tryParse(_balanceCtrl.text.replaceAll(',', '.'));
    final total = double.tryParse(_totalCtrl.text.replaceAll(',', '.'));
    final planned =
        double.tryParse(_plannedCtrl.text.replaceAll(',', '.')) ?? 0;
    if (balance == null || balance < 0) return;

    await ref.read(gameControllerProvider.notifier).updateDragon(
          id: widget.dragon.id,
          name: _nameCtrl.text,
          balance: balance,
          totalHp: total,
          plannedMonthly: planned,
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final d = widget.dragon;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(d.isDebt ? 'Ejderhayı sil?' : 'Hedefi sil?'),
        content: Text(
          '"${d.name}" listeden kalkacak. Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(gameControllerProvider.notifier).deleteDragon(d.id);
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
                controller: _plannedCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Aylık ödeme hedefi (TL)',
                  helperText: 'İsteğe bağlı — borçsuz tarih tahmini için',
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              child: const Text('Kaydet'),
            ),
            TextButton(
              onPressed: _delete,
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Sil'),
            ),
          ],
        ),
      ),
    );
  }
}
