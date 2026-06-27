import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
// latlong2 also exports a `Path` type which collides with dart:ui's `Path`
// used by the pin-tail painter, so hide it here.
import 'package:latlong2/latlong.dart' hide Path;

import '../theme/app_theme.dart';

/// Live order tracking — a real map with the restaurant, your address and a
/// courier that travels the route in real time, paired with an auto-advancing
/// status timeline and an ETA that counts down as the trip progresses.
///
/// The whole journey is driven by a single [AnimationController] (`_trip`) whose
/// value `t` runs 0 → 1. Everything else — the courier's position on the route,
/// the status stage, the ETA and the polyline fill — is derived from `t`, so the
/// screen always stays internally consistent.
class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({
    super.key,
    required this.total,
    this.etaMinutes = 20,
  });

  final double total;
  final int etaMinutes;

  static Route<void> route({required double total, int etaMinutes = 20}) =>
      MaterialPageRoute(
        builder: (_) =>
            OrderTrackingScreen(total: total, etaMinutes: etaMinutes),
      );

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with TickerProviderStateMixin {
  // --- Geography: a believable route from the restaurant to your address. -----
  static const _restaurant = LatLng(-6.9244, 107.6082);
  static const _home = LatLng(-6.9112, 107.6271);

  /// A multi-point path so the courier appears to weave through streets rather
  /// than fly in a straight line.
  static final _RoutePath _path = _RoutePath(const [
    _restaurant,
    LatLng(-6.9230, 107.6120),
    LatLng(-6.9205, 107.6138),
    LatLng(-6.9182, 107.6190),
    LatLng(-6.9156, 107.6212),
    LatLng(-6.9138, 107.6248),
    _home,
  ]);

  final _mapController = MapController();
  bool _mapReady = false;

  /// Drives the entire delivery. Compressed to a watchable length for the demo.
  late final AnimationController _trip = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 50),
  );

  late final DateTime _placedAt = DateTime.now();

  // Status stages, in order. `at` is the trip-progress point where each becomes
  // the active stage.
  static const _stages = <_Stage>[
    _Stage(Icons.receipt_long_rounded, 'Order confirmed',
        'Restaurant accepted your order', 0.0),
    _Stage(Icons.restaurant_rounded, 'Preparing your food',
        'The kitchen is cooking it fresh', 0.16),
    _Stage(Icons.shopping_bag_rounded, 'Picked up',
        'Courier has collected your order', 0.42),
    _Stage(Icons.two_wheeler_rounded, 'On the way',
        'Heading to your address', 0.55),
    _Stage(Icons.my_location_rounded, 'Almost there',
        'Your courier is arriving', 0.86),
    _Stage(Icons.check_circle_rounded, 'Delivered', 'Enjoy your meal!', 1.0),
  ];

  @override
  void initState() {
    super.initState();
    _trip.forward();
  }

  @override
  void dispose() {
    _trip.dispose();
    _mapController.dispose();
    super.dispose();
  }

  double get _t => _trip.value;

  /// How far along the route the courier is. It sits at the restaurant until
  /// the order is picked up, then travels, arriving just before "delivered".
  double get _routeFraction {
    const start = 0.42, end = 0.97;
    if (_t <= start) return 0;
    if (_t >= end) return 1;
    return (_t - start) / (end - start);
  }

  int get _currentStage {
    var idx = 0;
    for (var i = 0; i < _stages.length; i++) {
      if (_t >= _stages[i].at) idx = i;
    }
    return idx;
  }

  bool get _delivered => _t >= 1.0;

  int get _remainingMinutes =>
      math.max(1, ((1 - _t) * widget.etaMinutes).round());

  void _fitRoute() {
    if (!_mapReady) return;
    final media = MediaQuery.of(context);
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: _path.points,
        padding: EdgeInsets.only(
          top: media.padding.top + 90,
          left: 56,
          right: 56,
          bottom: media.size.height * 0.46,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // --- Live map -------------------------------------------------------
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _trip,
              builder: (context, _) {
                final f = _routeFraction;
                final driver = _path.pointAt(f);
                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _restaurant,
                    initialZoom: 14,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onMapReady: () {
                      _mapReady = true;
                      _fitRoute();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.mini_app',
                    ),
                    PolylineLayer(
                      polylines: [
                        // White casing for a raised "road" look.
                        Polyline(
                          points: _path.points,
                          strokeWidth: 11,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        // The remaining route, faded.
                        Polyline(
                          points: _path.points,
                          strokeWidth: 6,
                          color: AppColors.primary.withValues(alpha: 0.28),
                        ),
                        // The travelled portion, solid.
                        Polyline(
                          points: _path.pointsUpTo(f),
                          strokeWidth: 6,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _restaurant,
                          width: 50,
                          height: 60,
                          alignment: Alignment.topCenter,
                          child: const _EndpointPin(
                            icon: Icons.storefront_rounded,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Marker(
                          point: _home,
                          width: 50,
                          height: 60,
                          alignment: Alignment.topCenter,
                          child: const _EndpointPin(
                            icon: Icons.home_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        Marker(
                          point: driver,
                          width: 96,
                          height: 96,
                          child: _DriverMarker(arrived: _delivered),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          // --- Top bar: back + live badge ------------------------------------
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  _CircleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  const _LiveBadge(),
                ],
              ),
            ),
          ),

          // --- Re-centre button, floating just above the sheet ---------------
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.only(
                right: 20,
                bottom: MediaQuery.of(context).size.height * 0.46 + 16,
              ),
              child: _CircleIconButton(
                icon: Icons.center_focus_strong_rounded,
                onTap: _fitRoute,
              ),
            ),
          ),

          // --- Bottom status sheet -------------------------------------------
          DraggableScrollableSheet(
            initialChildSize: 0.46,
            minChildSize: 0.30,
            maxChildSize: 0.90,
            snap: true,
            snapSizes: const [0.46, 0.90],
            builder: (context, scrollController) {
              return AnimatedBuilder(
                animation: _trip,
                builder: (context, _) => _StatusSheet(
                  scrollController: scrollController,
                  stages: _stages,
                  currentStage: _currentStage,
                  remainingMinutes: _remainingMinutes,
                  delivered: _delivered,
                  progress: _t,
                  total: widget.total,
                  placedAt: _placedAt,
                  etaMinutes: widget.etaMinutes,
                  onDone: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Route geometry
// ---------------------------------------------------------------------------

/// A poly-line route that can report a position at any fraction `f` of its total
/// length, and the sub-path travelled up to `f` (for the progressive fill).
class _RoutePath {
  _RoutePath(this.points) {
    var acc = 0.0;
    _cumulative = [0.0];
    for (var i = 1; i < points.length; i++) {
      acc += _dist(points[i - 1], points[i]);
      _cumulative.add(acc);
    }
    _total = acc;
  }

  final List<LatLng> points;
  late final List<double> _cumulative;
  late final double _total;

  static double _dist(LatLng a, LatLng b) {
    final dx = a.longitude - b.longitude;
    final dy = a.latitude - b.latitude;
    return math.sqrt(dx * dx + dy * dy);
  }

  static LatLng _lerp(LatLng a, LatLng b, double t) => LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );

  LatLng pointAt(double f) {
    f = f.clamp(0.0, 1.0);
    if (_total == 0) return points.first;
    final target = f * _total;
    for (var i = 1; i < points.length; i++) {
      if (_cumulative[i] >= target) {
        final segLen = _cumulative[i] - _cumulative[i - 1];
        final segT = segLen == 0 ? 0.0 : (target - _cumulative[i - 1]) / segLen;
        return _lerp(points[i - 1], points[i], segT);
      }
    }
    return points.last;
  }

  List<LatLng> pointsUpTo(double f) {
    f = f.clamp(0.0, 1.0);
    if (_total == 0) return [points.first];
    final target = f * _total;
    final out = <LatLng>[points.first];
    for (var i = 1; i < points.length; i++) {
      if (_cumulative[i] < target) {
        out.add(points[i]);
      } else {
        final segLen = _cumulative[i] - _cumulative[i - 1];
        final segT = segLen == 0 ? 0.0 : (target - _cumulative[i - 1]) / segLen;
        out.add(_lerp(points[i - 1], points[i], segT));
        break;
      }
    }
    return out;
  }
}

// ---------------------------------------------------------------------------
// Map markers
// ---------------------------------------------------------------------------

/// A teardrop endpoint pin (restaurant / home) — its tip sits on the point.
class _EndpointPin extends StatelessWidget {
  const _EndpointPin({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2.5),
            boxShadow: AppShadows.card,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        Transform.translate(
          offset: const Offset(0, -3),
          child: CustomPaint(
            size: const Size(14, 10),
            painter: _PinTail(color),
          ),
        ),
      ],
    );
  }
}

class _PinTail extends CustomPainter {
  _PinTail(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_PinTail old) => old.color != color;
}

/// The courier marker — a pulsing accent ring around a circular badge.
class _DriverMarker extends StatefulWidget {
  const _DriverMarker({required this.arrived});

  final bool arrived;

  @override
  State<_DriverMarker> createState() => _DriverMarkerState();
}

class _DriverMarkerState extends State<_DriverMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = _pulse.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            if (!widget.arrived)
              Container(
                width: 40 + t * 52,
                height: 40 + t * 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: (1 - t) * 0.28),
                ),
              ),
            child!,
          ],
        );
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: AppShadows.accent(AppColors.primary),
        ),
        child: Icon(
          widget.arrived ? Icons.check_rounded : Icons.two_wheeler_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top-bar chrome
// ---------------------------------------------------------------------------

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.hairline),
            boxShadow: AppShadows.card,
            color: Colors.white,
          ),
          child: Icon(icon, size: 19, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.hairline),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Text('LIVE',
              style: AppText.eyebrow.copyWith(
                color: AppColors.textPrimary,
                letterSpacing: 1.6,
              )),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom status sheet
// ---------------------------------------------------------------------------

class _StatusSheet extends StatelessWidget {
  const _StatusSheet({
    required this.scrollController,
    required this.stages,
    required this.currentStage,
    required this.remainingMinutes,
    required this.delivered,
    required this.progress,
    required this.total,
    required this.placedAt,
    required this.etaMinutes,
    required this.onDone,
  });

  final ScrollController scrollController;
  final List<_Stage> stages;
  final int currentStage;
  final int remainingMinutes;
  final bool delivered;
  final double progress;
  final double total;
  final DateTime placedAt;
  final int etaMinutes;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final stage = stages[currentStage];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        boxShadow: AppShadows.floating,
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.hairline,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // ETA headline.
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(stage.icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      delivered ? 'Order delivered' : 'Arriving in',
                      style: AppText.label,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      delivered ? 'Enjoy your meal!' : '$remainingMinutes min',
                      style: AppText.display.copyWith(fontSize: 24),
                    ),
                  ],
                ),
              ),
              if (!delivered)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    stage.title,
                    style: AppText.label.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Slim progress bar.
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.02, 1.0),
              minHeight: 7,
              backgroundColor: AppColors.surfaceAlt,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 22),

          // Courier card.
          _CourierCard(delivered: delivered),
          const SizedBox(height: 24),

          Text('ORDER STATUS', style: AppText.eyebrow),
          const SizedBox(height: 14),

          // Timeline.
          for (var i = 0; i < stages.length; i++)
            _TimelineRow(
              stage: stages[i],
              state: i < currentStage
                  ? _StepState.done
                  : i == currentStage
                      ? (delivered ? _StepState.done : _StepState.active)
                      : _StepState.pending,
              isLast: i == stages.length - 1,
              time: placedAt.add(
                Duration(minutes: (stages[i].at * etaMinutes).round()),
              ),
            ),

          if (delivered) ...[
            const SizedBox(height: 8),
            _DoneButton(onTap: onDone),
          ],
        ],
      ),
    );
  }
}

class _CourierCard extends StatelessWidget {
  const _CourierCard({required this.delivered});

  final bool delivered;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.hairline),
            ),
            child: const Text('🧑🏻‍🦱', style: TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Rizky Pratama', style: AppText.title),
                    const SizedBox(width: 8),
                    const Icon(Icons.star_rounded,
                        size: 15, color: AppColors.amber),
                    Text(' 4.9',
                        style: AppText.label.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        )),
                  ],
                ),
                const SizedBox(height: 3),
                Text('Honda Vario · D 2451 KMA', style: AppText.label),
              ],
            ),
          ),
          _ContactButton(
            icon: Icons.chat_bubble_rounded,
            onTap: () => _toast(context, 'Opening chat with Rizky…'),
          ),
          const SizedBox(width: 10),
          _ContactButton(
            icon: Icons.call_rounded,
            filled: true,
            onTap: () => _toast(context, 'Calling Rizky…'),
          ),
        ],
      ),
    );
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.textPrimary,
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.primary : Colors.white,
      shape: CircleBorder(
        side: filled
            ? BorderSide.none
            : BorderSide(color: AppColors.hairline),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            size: 19,
            color: filled ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

enum _StepState { done, active, pending }

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.stage,
    required this.state,
    required this.isLast,
    required this.time,
  });

  final _Stage stage;
  final _StepState state;
  final bool isLast;
  final DateTime time;

  @override
  Widget build(BuildContext context) {
    final done = state == _StepState.done;
    final active = state == _StepState.active;
    final accent = done || active;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicator + connector column.
          Column(
            children: [
              _StepDot(state: state, icon: stage.icon),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.5,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: done ? AppColors.primary : AppColors.hairline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Title + subtitle.
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.title,
                    style: AppText.title.copyWith(
                      fontSize: 14.5,
                      color: accent
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    active ? stage.subtitle : _shortSubtitle,
                    style: AppText.label.copyWith(
                      fontSize: 12,
                      color: active
                          ? AppColors.primaryDark
                          : AppColors.textMuted,
                      fontWeight:
                          active ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              _fmtTime(time),
              style: AppText.label.copyWith(
                fontSize: 11.5,
                color: accent ? AppColors.textSecondary : AppColors.textMuted,
                fontWeight: accent ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _shortSubtitle =>
      state == _StepState.done ? 'Completed' : stage.subtitle;

  static String _fmtTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final ap = t.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ap';
  }
}

class _StepDot extends StatefulWidget {
  const _StepDot({required this.state, required this.icon});

  final _StepState state;
  final IconData icon;

  @override
  State<_StepDot> createState() => _StepDotState();
}

class _StepDotState extends State<_StepDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void initState() {
    super.initState();
    if (widget.state == _StepState.active) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _StepDot old) {
    super.didUpdateWidget(old);
    if (widget.state == _StepState.active && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (widget.state != _StepState.active && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.state == _StepState.done;
    final active = widget.state == _StepState.active;

    final core = Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done || active ? AppColors.primary : Colors.white,
        border: Border.all(
          color: done || active ? AppColors.primary : AppColors.hairline,
          width: 2,
        ),
      ),
      child: Icon(
        done ? Icons.check_rounded : widget.icon,
        size: 15,
        color: done || active ? Colors.white : AppColors.textMuted,
      ),
    );

    if (!active) return core;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 30 + _c.value * 14,
              height: 30 + _c.value * 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary
                    .withValues(alpha: (1 - _c.value) * 0.30),
              ),
            ),
            child!,
          ],
        );
      },
      child: core,
    );
  }
}

class _DoneButton extends StatelessWidget {
  const _DoneButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.accent(AppColors.primary),
      ),
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Back to home', style: AppText.button),
                const SizedBox(width: 8),
                const Icon(Icons.home_rounded, size: 19, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _Stage {
  const _Stage(this.icon, this.title, this.subtitle, this.at);

  final IconData icon;
  final String title;
  final String subtitle;

  /// Trip-progress point (0–1) at which this stage becomes active.
  final double at;
}
