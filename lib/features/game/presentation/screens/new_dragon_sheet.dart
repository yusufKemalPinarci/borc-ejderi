import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final _nameCtrl = TextEditingController(text: 'Yeni Hedef Ejderi');
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Yeni ejderha',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'İsim'),
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
              await ref.read(gameControllerProvider.notifier).setNewDragon(
                    name: _nameCtrl.text,
                    amount: amount,
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Çağır'),
          ),
        ],
      ),
    );
  }
}
