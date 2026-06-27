import 'package:flutter/material.dart';

import '../models/food.dart';
import '../state/cart.dart';
import '../theme/app_theme.dart';
import '../theme/food_theme.dart';
import '../widgets/food_cutout.dart';
import '../widgets/primary_button.dart';
import '../widgets/quantity_stepper.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  static const double _deliveryFee = 2.50;

  @override
  Widget build(BuildContext context) {
    final cart = Cart.instance;
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        // Rebuild on cart changes *and* on the Daylight⇄Midnight theme morph,
        // since the shell holds this tab as a `const` child that won't otherwise
        // recolour.
        listenable: Listenable.merge([cart, FoodTheme.instance]),
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('My Cart', style: AppText.h1),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text('${cart.count} items', style: AppText.label),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (cart.items.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: _VoucherBanner(),
                ),
              Expanded(
                child: cart.items.isEmpty
                    ? const _EmptyCart()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                        itemCount: cart.items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, i) =>
                            _CartTile(item: cart.items[i]),
                      ),
              ),
              if (cart.items.isNotEmpty)
                _CheckoutBar(
                  subtotal: cart.subtotal,
                  deliveryFee: _deliveryFee,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _VoucherBanner extends StatelessWidget {
  const _VoucherBanner();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_offer_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You have 3 vouchers',
                style: AppText.title.copyWith(fontSize: 13.5),
              ),
              Text('Tap to apply a discount', style: AppText.label),
            ],
          ),
        ),
        const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.primary,
          size: 22,
        ),
      ],
    );
  }
}

class _CartTile extends StatelessWidget {
  const _CartTile({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final cart = Cart.instance;
    final food = item.food;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairline),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          CutoutThumb(food: food, size: 68),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title,
                ),
                const SizedBox(height: 4),
                Text(
                  food.tagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label,
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${item.total.toStringAsFixed(2)}',
                  style: AppText.price.copyWith(fontSize: 16),
                ),
              ],
            ),
          ),
          QuantityStepper(
            quantity: item.quantity,
            onIncrement: () => cart.increment(food.id),
            onDecrement: () => cart.decrement(food.id),
          ),
        ],
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.subtotal, required this.deliveryFee});

  final double subtotal;
  final double deliveryFee;

  @override
  Widget build(BuildContext context) {
    final total = subtotal + deliveryFee;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        boxShadow: AppShadows.floating,
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Subtotal', value: subtotal),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Delivery fee', value: deliveryFee),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppText.title.copyWith(fontSize: 16)),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: AppText.price.copyWith(fontSize: 22),
              ),
            ],
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Checkout',
            icon: Icons.arrow_forward_rounded,
            onPressed: () {
              Navigator.of(context).push(CheckoutScreen.route(subtotal));
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.body),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: AppText.label.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          Text('Your cart is empty', style: AppText.h2),
          const SizedBox(height: 6),
          Text(
            'Add something delicious to get started',
            style: AppText.body,
          ),
        ],
      ),
    );
  }
}
