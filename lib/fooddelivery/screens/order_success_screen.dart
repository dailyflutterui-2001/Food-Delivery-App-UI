import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/cart.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import 'order_tracking_screen.dart';

/// Order-confirmed screen with a springy check-mark and a soft confetti burst.
class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({
    super.key,
    required this.total,
    this.etaMinutes = 20,
  });

  final double total;
  final int etaMinutes;

  static Route<void> route(double total, {int etaMinutes = 20}) =>
      MaterialPageRoute(
        builder: (_) => OrderSuccessScreen(total: total, etaMinutes: etaMinutes),
      );

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    // Emptying the cart is the natural consequence of a placed order.
    Cart.instance.clear();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Column(
            children: [
              const Spacer(),
              SizedBox(
                width: 200,
                height: 200,
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(200, 200),
                          painter: _ConfettiPainter(_c.value),
                        ),
                        Transform.scale(
                          scale: Curves.elasticOut.transform(
                            _c.value.clamp(0.0, 1.0),
                          ),
                          child: child,
                        ),
                      ],
                    );
                  },
                  child: Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.accent(AppColors.primary),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 60),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text('Order confirmed!', style: AppText.display),
              const SizedBox(height: 12),
              Text(
                'Your order is on its way. We\'ll notify you\nwhen the driver is nearby.',
                textAlign: TextAlign.center,
                style: AppText.body,
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        size: 18, color: AppColors.primaryDark),
                    const SizedBox(width: 8),
                    Text('Total paid  ',
                        style: AppText.label
                            .copyWith(color: AppColors.textPrimary)),
                    Text('\$${widget.total.toStringAsFixed(2)}',
                        style: AppText.price.copyWith(
                          fontSize: 16,
                          color: AppColors.primaryDark,
                        )),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Track your order',
                icon: Icons.location_on_rounded,
                onPressed: () => Navigator.of(context).push(
                  OrderTrackingScreen.route(
                    total: widget.total,
                    etaMinutes: widget.etaMinutes,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: AppColors.textSecondary,
                ),
                child: Text(
                  'Back to home',
                  style: AppText.title.copyWith(
                    fontSize: 14.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A one-shot radial confetti burst behind the check-mark.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t);

  final double t;

  static List<Color> get _colors => [
        AppColors.primary,
        AppColors.amber,
        AppColors.primaryDark,
        AppColors.pink,
      ];

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final center = size.center(Offset.zero);
    final eased = Curves.easeOut.transform(t.clamp(0.0, 1.0));
    final paint = Paint();
    const count = 14;
    for (var i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi;
      final dist = eased * 96;
      final pos = center + Offset(math.cos(angle), math.sin(angle)) * dist;
      paint.color = _colors[i % _colors.length]
          .withValues(alpha: (1 - eased).clamp(0.0, 1.0));
      canvas.drawCircle(pos, 4.5 * (1 - eased * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
