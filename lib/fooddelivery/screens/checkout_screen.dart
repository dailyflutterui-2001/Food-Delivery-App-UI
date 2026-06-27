import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import 'order_success_screen.dart';

/// Checkout — delivery address, a couple of payment options, and the order
/// summary. "Place order" routes to the success screen.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.subtotal});

  final double subtotal;

  /// Express delivery fee. Standard is free — see [_CheckoutScreenState].
  static const double deliveryFee = 2.50;

  static Route<void> route(double subtotal) => MaterialPageRoute(
        builder: (_) => CheckoutScreen(subtotal: subtotal),
      );

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _payment = 0;
  int _delivery = 0;

  // Delivery option drives both the fee and the estimated arrival time, so the
  // summary and the tracking ETA stay consistent with what was chosen.
  double get _deliveryFee => _delivery == 0 ? CheckoutScreen.deliveryFee : 0.0;
  int get _etaMinutes => _delivery == 0 ? 20 : 38;

  static const _payments = [
    (icon: Icons.account_balance_wallet_rounded, label: 'Wallet', sub: 'Balance \$84.20'),
    (icon: Icons.credit_card_rounded, label: 'Card', sub: '•••• 4821'),
    (icon: Icons.payments_rounded, label: 'Cash', sub: 'On delivery'),
  ];

  @override
  Widget build(BuildContext context) {
    final total = widget.subtotal + _deliveryFee;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                children: [
                  _BackButton(onTap: () => Navigator.of(context).maybePop()),
                  const SizedBox(width: 16),
                  Text('Checkout', style: AppText.h1),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
                children: [
                  Text('DELIVER TO', style: AppText.eyebrow),
                  const SizedBox(height: 12),
                  _AddressCard(),
                  const SizedBox(height: 26),
                  Text('DELIVERY OPTION', style: AppText.eyebrow),
                  const SizedBox(height: 12),
                  _OptionTile(
                    icon: Icons.electric_bolt_rounded,
                    title: 'Express',
                    subtitle: '15–25 min · \$2.50',
                    selected: _delivery == 0,
                    onTap: () => setState(() => _delivery = 0),
                  ),
                  const SizedBox(height: 10),
                  _OptionTile(
                    icon: Icons.pedal_bike_rounded,
                    title: 'Standard',
                    subtitle: '30–45 min · Free',
                    selected: _delivery == 1,
                    onTap: () => setState(() => _delivery = 1),
                  ),
                  const SizedBox(height: 26),
                  Text('PAYMENT METHOD', style: AppText.eyebrow),
                  const SizedBox(height: 12),
                  for (var i = 0; i < _payments.length; i++) ...[
                    _OptionTile(
                      icon: _payments[i].icon,
                      title: _payments[i].label,
                      subtitle: _payments[i].sub,
                      selected: _payment == i,
                      onTap: () => setState(() => _payment = i),
                    ),
                    if (i != _payments.length - 1) const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            _SummaryBar(
              subtotal: widget.subtotal,
              deliveryFee: _deliveryFee,
              total: total,
              onPlace: () => Navigator.of(context).push(
                OrderSuccessScreen.route(total, etaMinutes: _etaMinutes),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairline),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.home_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Home', style: AppText.title),
                const SizedBox(height: 3),
                Text('Jl. Merdeka 12, Sukabumi',
                    style: AppText.label, maxLines: 1),
              ],
            ),
          ),
          Text('Change',
              style: AppText.label.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.hairline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 22,
                color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.title.copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppText.label.copyWith(fontSize: 11.5)),
                ],
              ),
            ),
            _Radio(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.textMuted,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.onPlace,
  });

  final double subtotal;
  final double deliveryFee;
  final double total;
  final VoidCallback onPlace;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        boxShadow: AppShadows.floating,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: AppText.title.copyWith(fontSize: 16)),
                Text('\$${total.toStringAsFixed(2)}',
                    style: AppText.price.copyWith(fontSize: 22)),
              ],
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Place order',
              icon: Icons.check_rounded,
              onPressed: onPlace,
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.hairline),
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
