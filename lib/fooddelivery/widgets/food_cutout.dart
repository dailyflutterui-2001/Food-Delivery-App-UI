import 'package:flutter/material.dart';

import '../models/food.dart';
import '../theme/app_theme.dart';
import 'food_image.dart';

/// Renders a dish as its transparent Fluent-3D cutout (contained, never
/// cropped). Falls back to the framed photo when a food has no cutout.
class FoodCutout extends StatelessWidget {
  const FoodCutout({super.key, required this.food, this.size});

  final Food food;
  final double? size;

  @override
  Widget build(BuildContext context) {
    if (food.cutoutUrl.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: FoodImage(url: food.imageUrl),
        ),
      );
    }
    return Image.asset(
      food.cutoutUrl,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

/// A tinted, rounded tile with a soft accent halo and the dish cutout floating
/// at its centre — the consistent "thumbnail" treatment across list rows.
class CutoutThumb extends StatelessWidget {
  const CutoutThumb({
    super.key,
    required this.food,
    this.size = 84,
    this.radius = AppRadius.md,
  });

  final Food food;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.card, AppColors.surfaceAlt],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Quiet single-accent halo behind the food.
          Container(
            width: size * 0.82,
            height: size * 0.82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(size * 0.13),
            child: FoodCutout(food: food),
          ),
        ],
      ),
    );
  }
}
