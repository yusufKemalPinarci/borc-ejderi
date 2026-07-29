import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../game_controller.dart';
import 'arena_tab.dart';
import 'debts_tab.dart';
import 'ledger_tab.dart';
import 'victories_tab.dart';
import 'wallet_sheet.dart';

class ShellTabIndex extends Notifier<int> {
  @override
  int build() => 0;

  void set(int index) => state = index.clamp(0, 3);
}

/// Kabuk sekme indeksi (0 Savaş, 1 Borçlar, 2 Kale, 3 Günlük).
final shellTabIndexProvider =
    NotifierProvider<ShellTabIndex, int>(ShellTabIndex.new);

/// Debt Payoff Planner + Fortune City kale: her sekmenin tek işi var.
class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key});

  static const _titles = ['Savaş', 'Borçlar', 'Kale', 'Günlük'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider).asData?.value;
    final hero = state?.hero;
    final index = ref.watch(shellTabIndexProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1210), AppTheme.ink, Color(0xFF0B1016)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _titles[index.clamp(0, _titles.length - 1)],
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    if (hero != null) ...[
                      Text(
                        'Sv.${hero.level}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.gold,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Kasa',
                        onPressed: () => showWalletSheet(context),
                        icon: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: AppTheme.gold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: index.clamp(0, 3),
                  children: const [
                    ArenaTab(),
                    DebtsTab(),
                    VictoriesTab(),
                    LedgerTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index.clamp(0, 3),
        onDestinationSelected: (i) =>
            ref.read(shellTabIndexProvider.notifier).set(i),
        backgroundColor: AppTheme.slate,
        indicatorColor: AppTheme.ember.withValues(alpha: 0.25),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.whatshot_outlined),
            selectedIcon: Icon(Icons.whatshot),
            label: 'Savaş',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Borçlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_work_outlined),
            selectedIcon: Icon(Icons.home_work),
            label: 'Kale',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Günlük',
          ),
        ],
      ),
    );
  }
}
