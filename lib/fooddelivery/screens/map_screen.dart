import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/foods.dart';
import '../models/food.dart';
import '../theme/app_theme.dart';
import '../theme/food_theme.dart';
import '../widgets/food_cutout.dart';
import '../widgets/info_pill.dart';

/// "Nearby" tab — a live map with dish pins and a swipeable card strip. Tapping
/// a card recentres the map on that dish's restaurant.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _center = LatLng(-6.9175, 107.6191); // Bandung-ish
  final _mapController = MapController();
  // Held as a field (not created inline in build) so rebuilds — including the
  // theme morph — never reset the card strip's scroll position.
  final _pageController = PageController(viewportFraction: 0.86);
  int _active = 0;

  /// Scatter the dishes around the centre so each gets a distinct pin.
  late final List<LatLng> _points = List.generate(kFoods.length, (i) {
    final angle = i * 0.9;
    final r = 0.008 + (i % 3) * 0.004;
    return LatLng(
      _center.latitude + r * _cos(angle),
      _center.longitude + r * _sin(angle),
    );
  });

  // Tiny local trig to avoid importing dart:math just for the scatter.
  double _cos(double x) => _series(x, true);
  double _sin(double x) => _series(x, false);
  double _series(double x, bool cosine) {
    // Normalise to [-pi, pi].
    const twoPi = 6.283185307179586;
    x = x % twoPi;
    if (cosine) x += 1.5707963267948966;
    if (x > 3.141592653589793) x -= twoPi;
    final x2 = x * x;
    return x * (1 - x2 / 6 + x2 * x2 / 120 - x2 * x2 * x2 / 5040);
  }

  void _select(int i) {
    setState(() => _active = i);
    _mapController.move(_points[i], 15);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Recolour the floating chip and cards live when the app morphs between
    // Daylight and Midnight (the shell holds this tab as a `const` child).
    return ListenableBuilder(
      listenable: FoodTheme.instance,
      builder: (context, _) => Stack(
        children: [
          FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: _center,
            initialZoom: 14.5,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.mini_app',
            ),
            MarkerLayer(
              markers: [
                for (var i = 0; i < kFoods.length; i++)
                  Marker(
                    point: _points[i],
                    width: 54,
                    height: 54,
                    child: GestureDetector(
                      onTap: () => _select(i),
                      child: _MapPin(
                        food: kFoods[i],
                        selected: i == _active,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Row(
              children: [
                _GlassChip(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.near_me_rounded,
                          size: 16, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text('Nearby restaurants', style: AppText.title),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 148,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _select,
                itemCount: kFoods.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(6, 8, 6, 16),
                  child: _NearbyCard(food: kFoods[i]),
                ),
              ),
            ),
          ),
        ),
      ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.food, required this.selected});

  final Food food;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 200),
      scale: selected ? 1.15 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.hairline,
            width: 2,
          ),
          boxShadow: AppShadows.card,
        ),
        child: FoodCutout(food: food, size: 34),
      ),
    );
  }
}

class _NearbyCard extends StatelessWidget {
  const _NearbyCard({required this.food});

  final Food food;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.hairline),
          boxShadow: AppShadows.floating,
        ),
        child: Row(
          children: [
            CutoutThumb(food: food, size: 80),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(food.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      InfoPill(
                        icon: Icons.star_rounded,
                        iconColor: AppColors.amber,
                        label: '${food.rating}',
                        background: AppColors.surfaceAlt,
                      ),
                      const SizedBox(width: 8),
                      InfoPill(
                        icon: Icons.directions_bike_rounded,
                        label: '${food.distanceKm} km',
                        background: AppColors.surfaceAlt,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(food.priceLabel,
                      style: AppText.price.copyWith(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.hairline),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}
