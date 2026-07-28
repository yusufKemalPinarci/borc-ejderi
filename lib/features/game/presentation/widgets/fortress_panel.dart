import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models.dart';

/// Fortune City bina ızgarası yerine 4 sade sayaç — kişisel kullanım.
class FortressPanel extends StatelessWidget {
  const FortressPanel({super.key, required this.fortress});

  final FortressSummary fortress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.slate.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Kalen',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                fortress.prosperityLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Kayıt yazdıkça odalar artar — şehir simülasyonu yok.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                  color: AppTheme.mist.withValues(alpha: 0.65),
                ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _RoomStat(
                  icon: Icons.whatshot_outlined,
                  label: 'Savaş',
                  value: fortress.battleRooms,
                  color: AppTheme.ember,
                ),
              ),
              Expanded(
                child: _RoomStat(
                  icon: Icons.savings_outlined,
                  label: 'Kumbara',
                  value: fortress.vaultRooms,
                  color: AppTheme.moss,
                ),
              ),
              Expanded(
                child: _RoomStat(
                  icon: Icons.emoji_events_outlined,
                  label: 'Mezar',
                  value: fortress.tombs,
                  color: AppTheme.gold,
                ),
              ),
              Expanded(
                child: _RoomStat(
                  icon: Icons.ac_unit,
                  label: 'Kar',
                  value: fortress.snowflakes,
                  color: AppTheme.mist,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomStat extends StatelessWidget {
  const _RoomStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 11,
              ),
        ),
      ],
    );
  }
}
