import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../game_controller.dart';

/// Product+Design kararı: vuruş feedback overlay (hit / crit / defeat).
class AttackFeedbackOverlay extends StatefulWidget {
  const AttackFeedbackOverlay({
    super.key,
    required this.result,
    required this.onDismiss,
  });

  final AttackResult result;
  final VoidCallback onDismiss;

  @override
  State<AttackFeedbackOverlay> createState() => _AttackFeedbackOverlayState();
}

class _AttackFeedbackOverlayState extends State<AttackFeedbackOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.result.defeated
            ? 2200
            : widget.result.crit
                ? 1400
                : 1100,
      ),
    )..forward();

    if (widget.result.defeated || widget.result.crit) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && !widget.result.defeated) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final result = widget.result;
    final flashColor = result.defeated
        ? AppTheme.moss
        : result.crit
            ? AppTheme.gold
            : AppTheme.ember;

    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = Curves.easeOut.transform(_ctrl.value.clamp(0, 1));
          final fade = result.defeated
              ? Curves.easeInOut.transform((_ctrl.value * 1.2).clamp(0, 1))
              : (1 - ((_ctrl.value - 0.65) / 0.35).clamp(0, 1));

          return Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                ignoring: !result.defeated,
                child: ColoredBox(
                  color: flashColor.withValues(
                    alpha: result.defeated
                        ? 0.55 * fade
                        : 0.28 * (1 - t) * (result.crit ? 1.2 : 0.8),
                  ),
                ),
              ),
              Center(
                child: Opacity(
                  opacity: fade.clamp(0.0, 1.0).toDouble(),
                  child: Transform.translate(
                    offset: Offset(0, result.defeated ? 0 : -40 * t),
                    child: Transform.scale(
                      scale: result.defeated
                          ? 0.85 + 0.15 * t
                          : 0.7 + 0.35 * Curves.elasticOut.transform(t),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (result.crit && !result.defeated)
                            Text(
                              result.snowflake ? 'KAR TANESİ' : 'KRİTİK',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: AppTheme.gold,
                                    letterSpacing: 3,
                                  ),
                            ),
                          if (result.defeated)
                            Text(
                              result.targetKind == TargetKind.savings
                                  ? 'BİRİKİM TAMAM'
                                  : 'EJDERHA YENİLDİ',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(color: AppTheme.moss),
                              textAlign: TextAlign.center,
                            )
                          else
                            Text(
                              result.targetKind == TargetKind.savings
                                  ? '+${currency.format(result.damage)}'
                                  : '-${currency.format(result.damage)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(
                                    color: flashColor,
                                    fontSize: result.crit ? 48 : 40,
                                  ),
                            ),
                          const SizedBox(height: 8),
                          if (result.targetKind == TargetKind.savings) ...[
                            Text(
                              '+${result.xp} XP  (= ${currency.format(result.damage)})',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(color: AppTheme.moss),
                            ),
                            if (result.leveledUp) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Seviye ${result.newLevel}!',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(color: AppTheme.gold),
                              ),
                            ],
                          ] else ...[
                            Text(
                              result.defeated
                                  ? 'Borç kapandı! +${result.xp} XP'
                                  : 'Borca iş verildi',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(color: AppTheme.ember),
                            ),
                            if (result.leveledUp) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Seviye ${result.newLevel}!',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(color: AppTheme.gold),
                              ),
                            ],
                          ],
                          if (result.defeated) ...[
                            const SizedBox(height: 16),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                result.narrative,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: widget.onDismiss,
                              child: const Text('Devam'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> showAttackFeedback(
  BuildContext context,
  AttackResult result,
) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: result.defeated,
    barrierLabel: 'attack-feedback',
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (context, anim, secondaryAnim) {
      return AttackFeedbackOverlay(
        result: result,
        onDismiss: () => Navigator.of(context).pop(),
      );
    },
  );
}
