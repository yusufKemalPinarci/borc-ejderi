import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../game_controller.dart';

class DragonArena extends StatefulWidget {
  const DragonArena({
    super.key,
    required this.dragon,
    this.hit,
  });

  final DebtDragon dragon;
  final AttackResult? hit;

  @override
  State<DragonArena> createState() => _DragonArenaState();
}

class _DragonArenaState extends State<DragonArena>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _hit;
  late final AnimationController _shake;
  late final AnimationController _hp;
  late double _hpFrom;
  late double _hpTo;
  AttackResult? _floatingHit;
  int? _lastHitStamp;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _hit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _hp = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _hpFrom = _hpRatio(widget.dragon);
    _hpTo = _hpFrom;
    _hp.value = 1;
  }

  @override
  void didUpdateWidget(covariant DragonArena oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextRatio = _hpRatio(widget.dragon);
    if ((nextRatio - _hpTo).abs() > 0.0001) {
      _hpFrom = _hpTo;
      _hpTo = nextRatio;
      _hp.forward(from: 0);
    }
    final stamp = widget.hit?.stamp;
    if (stamp != null && stamp != _lastHitStamp) {
      _lastHitStamp = stamp;
      _playHit(widget.hit!);
    }
  }

  void _playHit(AttackResult hit) {
    setState(() => _floatingHit = hit);
    _hit.forward(from: 0);
    _shake.forward(from: 0);
  }

  double _hpRatio(DebtDragon dragon) {
    if (dragon.totalHp <= 0) return 0;
    return (dragon.currentHp / dragon.totalHp).clamp(0, 1);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _hit.dispose();
    _shake.dispose();
    _hp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final dragon = widget.dragon;
    final hitFlash = CurvedAnimation(parent: _hit, curve: Curves.easeOut);

    return AnimatedBuilder(
      animation: Listenable.merge([_shake, _hit, _hp]),
      builder: (context, child) {
        final shakeT = Curves.easeOut.transform(_shake.value);
        final dx = (1 - shakeT) *
            10 *
            ((_shake.value * 8).floor().isEven ? 1 : -1);
        final borderBoost =
            hitFlash.value * (widget.hit?.crit == true ? 0.85 : 0.45);
        final hpValue =
            _hpFrom + (_hpTo - _hpFrom) * Curves.easeOutCubic.transform(_hp.value);

        return Transform.translate(
          offset: Offset(dx, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                        const Color(0xFF2B1810),
                        AppTheme.ember,
                        hitFlash.value * 0.45,
                      ) ??
                      const Color(0xFF2B1810),
                  const Color(0xFF151A22),
                ],
              ),
              border: Border.all(
                color: Color.lerp(
                      AppTheme.ember.withValues(alpha: 0.35),
                      widget.hit?.crit == true
                          ? AppTheme.gold
                          : AppTheme.ember,
                      borderBoost,
                    ) ??
                    AppTheme.ember,
                width: 1.2 + borderBoost * 2,
              ),
              boxShadow: [
                if (hitFlash.value > 0.05)
                  BoxShadow(
                    color: (widget.hit?.crit == true
                            ? AppTheme.gold
                            : AppTheme.ember)
                        .withValues(alpha: 0.35 * hitFlash.value),
                    blurRadius: 24 * hitFlash.value,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    ScaleTransition(
                      scale: Tween(begin: 0.94, end: 1.06).animate(
                        CurvedAnimation(
                          parent: _pulse,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: const Text('🐉', style: TextStyle(fontSize: 72)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dragon.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: hpValue.clamp(0, 1),
                        minHeight: 14,
                        color: AppTheme.ember,
                        backgroundColor:
                            AppTheme.mist.withValues(alpha: 0.12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${currency.format(dragon.currentHp)} / ${currency.format(dragon.totalHp)} HP',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      'İlerleme %${(dragon.progress * 100).toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.gold,
                          ),
                    ),
                  ],
                ),
                if (_floatingHit != null)
                  Positioned(
                    top: 8,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: (1 -
                                Curves.easeOut.transform(_hit.value))
                            .clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            -10 - 56 * Curves.easeOut.transform(_hit.value),
                          ),
                          child: Text(
                            _floatingHit!.crit
                                ? 'KRİTİK -${currency.format(_floatingHit!.damage)}'
                                : '-${currency.format(_floatingHit!.damage)}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: _floatingHit!.crit
                                      ? AppTheme.gold
                                      : AppTheme.ember,
                                  fontSize: _floatingHit!.crit ? 26 : 22,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
