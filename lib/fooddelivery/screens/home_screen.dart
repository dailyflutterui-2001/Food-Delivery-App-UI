import 'package:flutter/material.dart';

import '../data/foods.dart';
import '../models/food.dart';
import '../theme/app_theme.dart';
import '../theme/food_theme.dart';
import '../widgets/food_cutout.dart';
import 'detail_screen.dart';
import 'discover_screen.dart';

/// Pushes the food detail screen — shared by every card on the home feed.
void _openDetail(BuildContext context, Food food) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => DetailScreen(food: food)),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FoodCategory _selected = FoodCategory.all;

  static const _categories = [
    FoodCategory.all,
    FoodCategory.burger,
    FoodCategory.sushi,
    FoodCategory.hotdog,
    FoodCategory.salad,
    FoodCategory.sides,
  ];

  List<Food> get _visibleFoods {
    if (_selected == FoodCategory.all) return kFoods;
    return kFoods.where((f) => f.category == _selected).toList();
  }

  @override
  Widget build(BuildContext context) {
    // The shell holds this tab as a `const` child, so it won't rebuild on its
    // own when the Daylight⇄Midnight morph fires. Subscribe to the theme here
    // so the whole feed recolours live along with the rest of the app.
    return ListenableBuilder(
      listenable: FoodTheme.instance,
      builder: (context, _) => SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          children: [
          const _Header(),
          const SizedBox(height: 26),
          Text('What would you like\nto eat today?',
              style: AppText.display),
          const SizedBox(height: 22),
          const _SearchField(),
          const SizedBox(height: 24),
          const _FeaturedCard(),
          const SizedBox(height: 30),
          _CategoryRow(
            categories: _categories,
            selected: _selected,
            onSelect: (c) => setState(() => _selected = c),
          ),
          const SizedBox(height: 26),
          _SectionHeader(
            title: _selected == FoodCategory.all
                ? 'Popular now'
                : _selected.label,
            onSeeMore: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DiscoverScreen()),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 268,
            child: _visibleFoods.isEmpty
                ? Center(
                    child:
                        Text('No items in this category', style: AppText.body),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: _visibleFoods.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 16),
                    itemBuilder: (context, i) =>
                        _PhotoCard(food: _visibleFoods[i]),
                  ),
          ),
          const SizedBox(height: 28),
          const _SectionHeader(title: 'Recommended for you'),
          const SizedBox(height: 16),
          for (final food in kFoods.take(4)) ...[
            _ListCard(food: food),
            const SizedBox(height: 14),
          ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on,
                    size: 15, color: AppColors.primary),
                const SizedBox(width: 4),
                Text('DELIVER TO', style: AppText.eyebrow),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Sukabumi, Indonesia',
                    style: AppText.title.copyWith(fontSize: 16)),
                const SizedBox(width: 2),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 20, color: AppColors.textPrimary),
              ],
            ),
          ],
        ),
        const Spacer(),
        _NotificationButton(),
      ],
    );
  }
}

class _NotificationButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {},
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.hairline),
              ),
              child: Icon(Icons.notifications_none_rounded,
                  size: 22, color: AppColors.textPrimary),
            ),
            Positioned(
              right: 11,
              top: 11,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.card, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded,
              color: AppColors.textMuted, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              style: AppText.label.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Search for food, drinks...',
                hintStyle: AppText.label.copyWith(color: AppColors.textMuted),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}

/// Large hero card — an accent promo with the dish floating out of a warm glow.
class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard();

  @override
  Widget build(BuildContext context) {
    final food = foodById('deluxe_burger');
    return GestureDetector(
      onTap: () => _openDetail(context, food),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryDeep, Color(0xFF1F1206)],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.floating,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Warm accent glow bleeding from behind the dish.
            Positioned(
              right: -40,
              top: -30,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.55),
                      AppColors.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Floating dish cutout on the right.
            Positioned(
              right: 6,
              top: 0,
              bottom: 0,
              child: Center(
                child: FoodCutout(food: food, size: 150),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('30% OFF TODAY',
                        style: AppText.eyebrow.copyWith(
                            color: Colors.white, fontSize: 9.5)),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(
                    width: 170,
                    child: Text(
                      'Double Deluxe Burger',
                      style: TextStyle(
                        fontFamily: AppTheme.displayFont,
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Order now',
                            // Pill is always white on the dark promo, so keep a
                            // fixed dark ink rather than the reactive token.
                            style: AppText.label.copyWith(
                              color: const Color(0xFF17151F),
                              fontWeight: FontWeight.w700,
                            )),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 15, color: AppColors.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onSeeMore});

  final String title;
  final VoidCallback? onSeeMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppText.h2),
        if (onSeeMore != null)
          GestureDetector(
            onTap: onSeeMore,
            behavior: HitTestBehavior.opaque,
            child: Text('See all',
                style: AppText.label.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                )),
          ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<FoodCategory> categories;
  final FoodCategory selected;
  final ValueChanged<FoodCategory> onSelect;

  IconData _iconFor(FoodCategory c) {
    switch (c) {
      case FoodCategory.all:
        return Icons.restaurant_rounded;
      case FoodCategory.burger:
        return Icons.lunch_dining_rounded;
      case FoodCategory.hotdog:
        return Icons.kebab_dining_rounded;
      case FoodCategory.sushi:
        return Icons.set_meal_rounded;
      case FoodCategory.salad:
        return Icons.local_florist_rounded;
      case FoodCategory.sides:
        return Icons.fastfood_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final c = categories[i];
          final isSelected = c == selected;
          return GestureDetector(
            onTap: () => onSelect(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.hairline,
                ),
              ),
              child: Row(
                children: [
                  Icon(_iconFor(c),
                      size: 18,
                      color: isSelected ? Colors.white : AppColors.primary),
                  const SizedBox(width: 8),
                  Text(c.label,
                      style: AppText.label.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Photo-forward card: the dish cutout floats over a haloed tile, details below.
class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.food});

  final Food food;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetail(context, food),
      child: Container(
        width: 196,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.hairline),
          boxShadow: AppShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.card, AppColors.surfaceAlt],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 150,
                        height: 150,
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
                        padding: const EdgeInsets.all(16),
                        child: FoodCutout(food: food),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: _FrostedPill(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: AppColors.amber),
                        const SizedBox(width: 3),
                        Text('${food.rating}',
                            style: AppText.label.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            )),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _FrostedPill(
                    circle: true,
                    child: Icon(Icons.favorite_border_rounded,
                        size: 16, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(food.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title),
                  const SizedBox(height: 3),
                  Text(food.tagline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label.copyWith(fontSize: 11.5)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(food.priceLabel, style: AppText.price),
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.add_rounded,
                            size: 18, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrostedPill extends StatelessWidget {
  const _FrostedPill({required this.child, this.circle = false});

  final Widget child;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: circle
          ? const EdgeInsets.all(7)
          : const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.92),
        borderRadius:
            circle ? null : BorderRadius.circular(20),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: child,
    );
  }
}

/// Horizontal list row used in "Recommended for you".
class _ListCard extends StatelessWidget {
  const _ListCard({required this.food});

  final Food food;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetail(context, food),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.hairline),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            CutoutThumb(food: food, size: 84),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(food.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: AppColors.amber),
                      const SizedBox(width: 3),
                      Text('${food.rating}',
                          style: AppText.label.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          )),
                      Text('  ·  ${food.deliveryMinutes} min',
                          style: AppText.label),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(food.priceLabel,
                          style: AppText.price.copyWith(fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add_rounded,
                            size: 16, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
