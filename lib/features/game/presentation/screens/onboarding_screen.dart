import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../game_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _heroCtrl = TextEditingController(text: 'Kahraman');
  final _budgetCtrl = TextEditingController(text: '15000');
  final _dragonCtrl = TextEditingController(text: 'Kredi Kartı');
  final _amountCtrl = TextEditingController(text: '25000');
  final _rateCtrl = TextEditingController(text: '3.5');
  final _minCtrl = TextEditingController(text: '500');

  @override
  void dispose() {
    _heroCtrl.dispose();
    _budgetCtrl.dispose();
    _dragonCtrl.dispose();
    _amountCtrl.dispose();
    _rateCtrl.dispose();
    _minCtrl.dispose();
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
                'Borçlarını listele, Kartopu veya Çığ stratejisini seç, '
                'ödeme kaydet. 1 TL ödeme = 1 hasar; birikim = güç XP. '
                'Türkiye için, tamamen offline.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 36),
              TextField(
                controller: _heroCtrl,
                decoration: const InputDecoration(labelText: 'Kahraman adı'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _budgetCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Aylık gelir / kasa (TL)',
                  hintText: 'Bu ay borç ve yaşam için ayırdığın tutar',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _dragonCtrl,
                decoration: const InputDecoration(
                  labelText: 'İlk borç adı',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kalan bakiye (TL)',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _rateCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Yıllık faiz (%)',
                  hintText: 'Bilmiyorsan 0',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _minCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Asgari ödeme (TL)',
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () async {
                  final debt = double.tryParse(
                        _amountCtrl.text.replaceAll(',', '.'),
                      ) ??
                      0;
                  final budget = double.tryParse(
                        _budgetCtrl.text.replaceAll(',', '.'),
                      ) ??
                      0;
                  final rate = double.tryParse(
                        _rateCtrl.text.replaceAll(',', '.'),
                      ) ??
                      0;
                  final minPay = double.tryParse(
                        _minCtrl.text.replaceAll(',', '.'),
                      ) ??
                      0;
                  if (debt <= 0 || budget <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gelir ve borç bakiyesini gir'),
                      ),
                    );
                    return;
                  }
                  await ref
                      .read(gameControllerProvider.notifier)
                      .completeOnboarding(
                        heroName: _heroCtrl.text,
                        dragonName: _dragonCtrl.text,
                        debtAmount: debt,
                        monthlyBudget: budget,
                        kind: TargetKind.debt,
                        interestRate: rate,
                        minPayment: minPay,
                      );
                },
                child: const Text('Maceraya başla'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
