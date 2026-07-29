import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../game_controller.dart';

/// Vuruş / kritik / zafer overlay — zaferde confetti tarzı parçacıklar.
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
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(widget.result.stamp);
    _particles = List.generate(
      widget.result.defeated ? 28 : (widget.result.crit ? 12 : 0),
      (i) => _Particle(
        angle: rng.nextDouble() * math.pi * 2,
        speed: 40 + rng.nextDouble() * 120,
        size: 3 + rng.nextDouble() * 5,
        hue: rng.nextBool(),
      ),
    );

    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.result.defeated
            ? 2400
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
              if (_particles.isNotEmpty)
                CustomPaint(
                  painter: _ConfettiPainter(
                    particles: _particles,
                    progress: _ctrl.value,
                    gold: AppTheme.gold,
                    moss: AppTheme.moss,
                    ember: AppTheme.ember,
                  ),
                ),
              if (result.defeated)
                Center(
                  child: Opacity(
                    opacity: (0.35 * fade).clamp(0.0, 1.0),
                    child: Container(
                      width: 220 + 80 * t,
                      height: 220 + 80 * t,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.gold.withValues(alpha: 0.45),
                            Colors.transparent,
                          ],
                        ),
                      ),
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
                                  : 'EJDERHA DÜŞTÜ',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: AppTheme.moss,
                                    fontSize: 28,
                                  ),
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
                                result.narrative.isNotEmpty
                                    ? result.narrative
                                    : 'Kale mezarlığına bir zafer eklendi.',
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

class _Particle {
  const _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.hue,
  });

  final double angle;
  final double speed;
  final double size;
  final bool hue;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.particles,
    required this.progress,
    required this.gold,
    required this.moss,
    required this.ember,
  });

  final List<_Particle> particles;
  final double progress;
  final Color gold;
  final Color moss;
  final Color ember;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final t = Curves.easeOut.transform(progress.clamp(0, 1));
    final fade = (1 - progress).clamp(0.0, 1.0);

    for (final p in particles) {
      final dist = p.speed * t;
      final x = cx + math.cos(p.angle) * dist;
      final y = cy + math.sin(p.angle) * dist + 40 * t * t;
      final color = p.hue ? gold : (progress > 0.5 ? moss : ember);
      canvas.drawCircle(
        Offset(x, y),
        p.size * (1 - 0.4 * t),
        Paint()..color = color.withValues(alpha: 0.85 * fade),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
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
