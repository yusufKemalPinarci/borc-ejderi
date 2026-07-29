import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models.dart';

/// Fortune City “şehir” yerine 4 oda — kayıtla doluluk büyür.
class FortressPanel extends StatelessWidget {
  const FortressPanel({super.key, required this.fortress});

  final FortressSummary fortress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.slate.withValues(alpha: 0.95),
            const Color(0xFF1A222C),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.32)),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  fortress.prosperityLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Her kayıt bir odayı güçlendirir.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                  color: AppTheme.mist.withValues(alpha: 0.65),
                ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _FortressRoom(
                  icon: Icons.whatshot_outlined,
                  label: 'Savaş Salonu',
                  value: fortress.battleRooms,
                  fill: fortress.fillRatio(fortress.battleRooms),
                  color: AppTheme.ember,
                ),
              ),
              Expanded(
                child: _FortressRoom(
                  icon: Icons.savings_outlined,
                  label: 'Kumbara',
                  value: fortress.vaultRooms,
                  fill: fortress.fillRatio(fortress.vaultRooms),
                  color: AppTheme.moss,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _FortressRoom(
                  icon: Icons.emoji_events_outlined,
                  label: 'Mezarlık',
                  value: fortress.tombs,
                  fill: fortress.fillRatio(fortress.tombs, softCap: 6),
                  color: AppTheme.gold,
                ),
              ),
              Expanded(
                child: _FortressRoom(
                  icon: Icons.ac_unit,
                  label: 'Kar Ocağı',
                  value: fortress.snowflakes,
                  fill: fortress.fillRatio(fortress.snowflakes, softCap: 8),
                  color: AppTheme.mist,
                ),
              ),
            ],
          ),
          if (fortress.ledgerEntries > 0) ...[
            const SizedBox(height: 12),
            Text(
              'Günlük defter: ${fortress.ledgerEntries} kayıt',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                    color: AppTheme.mist.withValues(alpha: 0.55),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FortressRoom extends StatelessWidget {
  const _FortressRoom({
    required this.icon,
    required this.label,
    required this.value,
    required this.fill,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final double fill;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 0.92 + 0.08 * fill),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08 + 0.12 * fill),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: color.withValues(alpha: 0.25 + 0.35 * fill),
                ),
              ),
              child: Column(
                children: [
                  Icon(icon, color: color, size: 26),
                  const SizedBox(height: 6),
                  Text(
                    '$value',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 22,
                          color: color,
                        ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fill,
                      minHeight: 5,
                      color: color,
                      backgroundColor: AppTheme.mist.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}
