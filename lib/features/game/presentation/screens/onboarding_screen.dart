import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _heroCtrl = TextEditingController(text: 'Kahraman');
  final _dragonCtrl = TextEditingController(text: 'Kredi Kartı Ejderi');
  final _amountCtrl = TextEditingController(text: '25000');

  @override
  void dispose() {
    _heroCtrl.dispose();
    _dragonCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF101820),
              Color(0xFF1A0F0A),
              Color(0xFF1C2834),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            children: [
              Text(
                'Borç Ejderi',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Borcunu bir ejderhaya çevir. Her ödeme bir darbe. '
                'Tamamen offline — crew agentlar birlikte planlar.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 36),
              TextField(
                controller: _heroCtrl,
                decoration: const InputDecoration(labelText: 'Kahraman adı'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _dragonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ejderha adı (borç rumuzu)',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Toplam borç / hedef (TL)',
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () async {
                  final amount = double.tryParse(
                        _amountCtrl.text.replaceAll(',', '.'),
                      ) ??
                      0;
                  if (amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Geçerli bir tutar gir')),
                    );
                    return;
                  }
                  await ref
                      .read(gameControllerProvider.notifier)
                      .completeOnboarding(
                        heroName: _heroCtrl.text,
                        dragonName: _dragonCtrl.text,
                        debtAmount: amount,
                      );
                },
                child: const Text('Ejderhayı çağır'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
