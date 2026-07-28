import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../game_controller.dart';
import 'arena_tab.dart';
import 'debts_tab.dart';
import 'ledger_tab.dart';
import 'victories_tab.dart';
import 'wallet_sheet.dart';

/// Debt Payoff Planner + Hunter Vault tarzı: her sekmenin tek işi var.
class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  int _index = 0;

  static const _titles = ['Savaş', 'Borçlar', 'Zaferler', 'Günlük'];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameControllerProvider).asData?.value;
    final hero = state?.hero;

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
                        _titles[_index],
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
                  index: _index,
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
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
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
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Zaferler',
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
