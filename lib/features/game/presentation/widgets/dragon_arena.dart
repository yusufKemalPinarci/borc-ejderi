import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../game_controller.dart';

/// Boş durum / onboarding için mini ejderha silüeti.
class DragonPreviewBanner extends StatelessWidget {
  const DragonPreviewBanner({
    super.key,
    this.victorious = false,
    this.height = 148,
  });

  final bool victorious;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            victorious ? const Color(0xFF12241E) : const Color(0xFF1A0E0C),
            const Color(0xFF0B1016),
          ],
        ),
        border: Border.all(
          color: (victorious ? AppTheme.moss : AppTheme.ember)
              .withValues(alpha: 0.35),
        ),
      ),
      child: CustomPaint(
        painter: _DragonSilhouettePainter(
          hpRatio: victorious ? 0.05 : 1,
          breath: 0.55,
          hit: victorious ? 0.2 : 0,
          crit: victorious,
        ),
      ),
    );
  }
}

/// Savaş sahnesi: CustomPaint ejderha / kumbara + HP + vuruş feedback.
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
  late final AnimationController _breath;
  late double _hpFrom;
  late double _hpTo;
  AttackResult? _floatingHit;
  int? _lastHitStamp;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
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
    if (dragon.isSavings) {
      return (dragon.currentHp / dragon.totalHp).clamp(0, 1);
    }
    return (dragon.currentHp / dragon.totalHp).clamp(0, 1);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _breath.dispose();
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
      animation: Listenable.merge([_shake, _hit, _hp, _pulse, _breath]),
      builder: (context, child) {
        final shakeT = Curves.easeOut.transform(_shake.value);
        final dx = (1 - shakeT) *
            10 *
            ((_shake.value * 8).floor().isEven ? 1 : -1);
        final borderBoost =
            hitFlash.value * (widget.hit?.crit == true ? 0.85 : 0.45);
        final hpValue =
            _hpFrom + (_hpTo - _hpFrom) * Curves.easeOutCubic.transform(_hp.value);
        final pulse = 0.96 + 0.04 * _pulse.value;
        final breath = 0.98 + 0.02 * _breath.value;

        return Transform.translate(
          offset: Offset(dx, 0),
          child: Container(
            width: double.infinity,
            height: 320,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(
                        const Color(0xFF1A0E0C),
                        AppTheme.ember,
                        hitFlash.value * 0.35,
                      ) ??
                      const Color(0xFF1A0E0C),
                  const Color(0xFF0B1016),
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
                    blurRadius: 28 * hitFlash.value,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Zemin / atmosfer
                CustomPaint(
                  painter: _ArenaBackdropPainter(
                    pulse: _pulse.value,
                    isSavings: dragon.isSavings,
                  ),
                ),
                // Ejderha / kumbara silüeti
                Positioned(
                  left: 0,
                  right: 0,
                  top: 28,
                  height: 168,
                  child: Transform.scale(
                    scale: pulse * breath,
                    child: CustomPaint(
                      painter: dragon.isSavings
                          ? _VaultPainter(
                              fill: hpValue,
                              hit: hitFlash.value,
                            )
                          : _DragonSilhouettePainter(
                              hpRatio: hpValue,
                              breath: _breath.value,
                              hit: hitFlash.value,
                              crit: widget.hit?.crit == true,
                            ),
                    ),
                  ),
                ),
                // Bilgi katmanı
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    children: [
                      Text(
                        dragon.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        dragon.kind.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: dragon.isSavings
                                  ? AppTheme.moss
                                  : AppTheme.ember,
                              fontSize: 12,
                            ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: hpValue.clamp(0, 1),
                          minHeight: 16,
                          color: dragon.isSavings
                              ? AppTheme.moss
                              : AppTheme.ember,
                          backgroundColor:
                              AppTheme.mist.withValues(alpha: 0.12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dragon.isSavings
                            ? '${currency.format(dragon.currentHp)} / ${currency.format(dragon.totalHp)}'
                            : '${currency.format(dragon.currentHp)} HP · %${(dragon.progress * 100).toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 14,
                            ),
                      ),
                    ],
                  ),
                ),
                if (_floatingHit != null)
                  Positioned(
                    top: 24,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: (1 - Curves.easeOut.transform(_hit.value))
                            .clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            -8 - 48 * Curves.easeOut.transform(_hit.value),
                          ),
                          child: Text(
                            _floatingHit!.crit
                                ? 'KRİTİK ${_floatingHit!.targetKind == TargetKind.savings ? '+' : '-'}${currency.format(_floatingHit!.damage)}'
                                : '${_floatingHit!.targetKind == TargetKind.savings ? '+' : '-'}${currency.format(_floatingHit!.damage)}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: _floatingHit!.crit
                                      ? AppTheme.gold
                                      : (_floatingHit!.targetKind ==
                                              TargetKind.savings
                                          ? AppTheme.moss
                                          : AppTheme.ember),
                                  fontSize: _floatingHit!.crit ? 26 : 22,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      blurRadius: 8,
                                    ),
                                  ],
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

class _ArenaBackdropPainter extends CustomPainter {
  _ArenaBackdropPainter({required this.pulse, required this.isSavings});

  final double pulse;
  final bool isSavings;

  @override
  void paint(Canvas canvas, Size size) {
    final accent = isSavings ? AppTheme.moss : AppTheme.ember;
    // Zemin ovali
    final ground = Paint()
      ..shader = RadialGradient(
        colors: [
          accent.withValues(alpha: 0.18 + 0.06 * pulse),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height * 0.55),
          width: size.width * 0.9,
          height: size.height * 0.5,
        ),
      );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.58),
        width: size.width * 0.75,
        height: 48,
      ),
      ground,
    );

    // Üst duman / sis
    final mist = Paint()
      ..color = AppTheme.mist.withValues(alpha: 0.04 + 0.02 * pulse);
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.15),
      40 + 8 * pulse,
      mist,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      32 + 6 * pulse,
      mist,
    );
  }

  @override
  bool shouldRepaint(covariant _ArenaBackdropPainter old) =>
      old.pulse != pulse || old.isSavings != isSavings;
}

class _DragonSilhouettePainter extends CustomPainter {
  _DragonSilhouettePainter({
    required this.hpRatio,
    required this.breath,
    required this.hit,
    required this.crit,
  });

  final double hpRatio;
  final double breath;
  final double hit;
  final bool crit;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.55;
    final wounded = 1 - hpRatio.clamp(0, 1);

    final bodyColor = Color.lerp(
          const Color(0xFF8B2E1A),
          const Color(0xFF3A1510),
          wounded * 0.55,
        ) ??
        const Color(0xFF8B2E1A);
    final glow = crit ? AppTheme.gold : AppTheme.ember;

    // Gölge
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + 52),
        width: 110,
        height: 18,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );

    final body = Path();
    // Gövde
    body.addOval(
      Rect.fromCenter(
        center: Offset(cx, cy + 8),
        width: 100 + 4 * breath,
        height: 72 + 3 * breath,
      ),
    );
    // Kafa
    body.addOval(
      Rect.fromCenter(
        center: Offset(cx + 48, cy - 28),
        width: 56,
        height: 44,
      ),
    );
    // Boyun
    body.moveTo(cx + 20, cy - 10);
    body.quadraticBezierTo(cx + 36, cy - 30, cx + 44, cy - 22);

    canvas.drawPath(
      body,
      Paint()
        ..color = bodyColor
        ..style = PaintingStyle.fill,
    );

    // Kanatlar
    final wingPaint = Paint()
      ..color = bodyColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final wingLift = 6 * breath;
    final leftWing = Path()
      ..moveTo(cx - 10, cy)
      ..quadraticBezierTo(
        cx - 70,
        cy - 50 - wingLift,
        cx - 30,
        cy + 20,
      )
      ..close();
    final rightWing = Path()
      ..moveTo(cx + 10, cy - 5)
      ..quadraticBezierTo(
        cx + 90,
        cy - 40 - wingLift,
        cx + 40,
        cy + 15,
      )
      ..close();
    canvas.drawPath(leftWing, wingPaint);
    canvas.drawPath(rightWing, wingPaint);

    // Boynuzlar
    final horn = Paint()..color = const Color(0xFFC4A574);
    canvas.drawPath(
      Path()
        ..moveTo(cx + 40, cy - 42)
        ..lineTo(cx + 36, cy - 62)
        ..lineTo(cx + 48, cy - 44)
        ..close(),
      horn,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx + 55, cy - 40)
        ..lineTo(cx + 58, cy - 58)
        ..lineTo(cx + 64, cy - 38)
        ..close(),
      horn,
    );

    // Gözler
    final eyeGlow = 0.55 + 0.45 * math.sin(breath * math.pi);
    final eyePaint = Paint()
      ..color = Color.lerp(
            AppTheme.gold,
            AppTheme.ember,
            hit,
          )!
          .withValues(alpha: eyeGlow);
    canvas.drawCircle(Offset(cx + 58, cy - 30), 4.5, eyePaint);
    canvas.drawCircle(Offset(cx + 48, cy - 28), 3.5, eyePaint);
    canvas.drawCircle(
      Offset(cx + 58, cy - 30),
      1.5,
      Paint()..color = Colors.black,
    );

    // Nefes / alev
    if (hit > 0.05 || breath > 0.3) {
      final flame = Paint()
        ..shader = RadialGradient(
          colors: [
            glow.withValues(alpha: 0.55 * (0.3 + hit)),
            glow.withValues(alpha: 0),
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(cx + 78, cy - 22),
            radius: 28 + 20 * hit,
          ),
        );
      canvas.drawCircle(
        Offset(cx + 78, cy - 22),
        18 + 16 * hit,
        flame,
      );
    }

    // Vuruş halkası
    if (hit > 0.02) {
      canvas.drawCircle(
        Offset(cx, cy),
        40 + 50 * hit,
        Paint()
          ..color = glow.withValues(alpha: 0.35 * (1 - hit))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DragonSilhouettePainter old) =>
      old.hpRatio != hpRatio ||
      old.breath != breath ||
      old.hit != hit ||
      old.crit != crit;
}

class _VaultPainter extends CustomPainter {
  _VaultPainter({required this.fill, required this.hit});

  final double fill;
  final double hit;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.5;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 48), width: 90, height: 16),
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: 100, height: 88),
      const Radius.circular(18),
    );
    canvas.drawRRect(
      body,
      Paint()..color = const Color(0xFF1E3A2F),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..color = AppTheme.moss.withValues(alpha: 0.5 + 0.3 * hit)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Dolan kısım
    final fillH = 70.0 * fill.clamp(0.0, 1.0);
    if (fillH > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - 42, cy + 35 - fillH, 84, fillH),
          const Radius.circular(10),
        ),
        Paint()..color = AppTheme.moss.withValues(alpha: 0.45),
      );
    }

    // Kilit
    canvas.drawCircle(
      Offset(cx, cy + 4),
      12,
      Paint()..color = AppTheme.gold.withValues(alpha: 0.85),
    );
    canvas.drawCircle(
      Offset(cx, cy + 4),
      5,
      Paint()..color = const Color(0xFF1A1210),
    );
  }

  @override
  bool shouldRepaint(covariant _VaultPainter old) =>
      old.fill != fill || old.hit != hit;
}
