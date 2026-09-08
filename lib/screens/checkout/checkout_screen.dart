import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/constants/app_constants.dart';
import 'package:keychain_shop/models/address_model.dart';
import 'package:keychain_shop/models/order_model.dart';
import 'package:keychain_shop/providers/address_provider.dart';
import 'package:keychain_shop/providers/auth_provider.dart';
import 'package:keychain_shop/providers/cart_provider.dart';
import 'package:keychain_shop/router/app_router.dart';
import 'package:keychain_shop/services/coupon_service.dart';
import 'package:keychain_shop/services/firestore_service.dart';
import 'package:keychain_shop/services/payment_service.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/utils/formatters.dart';
import 'package:keychain_shop/widgets/app_button.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  AddressModel? _selectedAddress;
  String _paymentMethod = AppConstants.paymentCod;
  final _notesController = TextEditingController();
  final _couponController = TextEditingController();
  bool _placing = false;
  bool _applyingCoupon = false;
  AddressProvider? _addressProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _addressProvider = context.read<AddressProvider>();
      _addressProvider!.addListener(_syncSelectedAddress);
      _syncSelectedAddress();
    });
  }

  @override
  void dispose() {
    _addressProvider?.removeListener(_syncSelectedAddress);
    _notesController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  void _syncSelectedAddress() {
    if (!mounted) return;
    final provider = _addressProvider ?? context.read<AddressProvider>();
    final def = provider.defaultAddress;
    if (_selectedAddress == null && def != null) {
      setState(() => _selectedAddress = def);
      return;
    }
    // Keep selection if still in the list; otherwise fall back to default.
    if (_selectedAddress != null &&
        provider.addresses.isNotEmpty &&
        !provider.addresses.any((a) => a.id == _selectedAddress!.id)) {
      setState(() => _selectedAddress = def);
    }
  }

  Future<void> _applyCoupon() async {
    final cart = context.read<CartProvider>();
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a coupon code.')),
      );
      return;
    }

    setState(() => _applyingCoupon = true);
    try {
      final result = await context.read<CouponService>().validateCoupon(
            code: code,
            subtotal: cart.subtotal,
          );
      if (!mounted) return;
      if (!result.valid || result.couponId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
        return;
      }
      cart.applyCoupon(
        code: result.code ?? code,
        couponId: result.couponId!,
        discountAmount: result.discountAmount,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Coupon applied (−${Formatters.currency(result.discountAmount)})',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _applyingCoupon = false);
    }
  }

  Future<AddressModel?> _pickAddress() async {
    final result = await context.pushOverlay<AddressModel>(
      '/addresses?select=1',
    );
    if (result != null && mounted) {
      setState(() => _selectedAddress = result);
    }
    return result;
  }

  Future<AddressModel?> _resolveDeliveryAddress() async {
    final addressProvider = context.read<AddressProvider>();

    var delivery =
        _selectedAddress ?? addressProvider.defaultAddress;
    if (delivery != null) return delivery;

    if (addressProvider.isLoading) {
      await addressProvider.refresh();
      if (!mounted) return null;
      delivery = _selectedAddress ?? addressProvider.defaultAddress;
      if (delivery != null) {
        setState(() => _selectedAddress = delivery);
        return delivery;
      }
    } else if (addressProvider.addresses.isEmpty) {
      await addressProvider.refresh();
      if (!mounted) return null;
      delivery = addressProvider.defaultAddress;
      if (delivery != null) {
        setState(() => _selectedAddress = delivery);
        return delivery;
      }
    }

    // Open picker / add flow instead of only showing a snackbar.
    final picked = await _pickAddress();
    if (!mounted) return null;
    return picked ?? _selectedAddress ?? addressProvider.defaultAddress;
  }

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to place an order.')),
      );
      return;
    }

    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty.')),
      );
      return;
    }

    final deliveryAddress = await _resolveDeliveryAddress();
    if (!mounted) return;

    if (deliveryAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a delivery address to continue.'),
        ),
      );
      return;
    }

    setState(() => _placing = true);

    try {
      final firestore = context.read<FirestoreService>();
      final paymentService = context.read<PaymentService>();

      final subtotal = cart.subtotal;
      final delivery = cart.deliveryCharges;
      final discount = cart.discount;
      final total = cart.total;
      final estimated = DateTime.now().add(const Duration(days: 3));

      final isOnline = _paymentMethod == AppConstants.paymentOnline;

      final draft = OrderModel(
        id: '',
        userId: user.id,
        userName: user.name,
        userEmail: user.email,
        userPhone: user.phone ?? deliveryAddress.phone,
        items: cart.items.map((i) => i.toOrderItemMap()).toList(),
        subtotal: subtotal,
        deliveryCharges: delivery,
        discount: discount,
        totalAmount: total,
        couponCode: cart.couponCode,
        paymentMethod: _paymentMethod,
        paymentStatus: AppConstants.paymentPending,
        orderStatus: AppConstants.orderPending,
        deliveryAddress: deliveryAddress.toOrderSnapshot(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: DateTime.now(),
        estimatedDeliveryDate: estimated,
      );

      final orderId = await firestore.createOrder(draft);

      if (isOnline) {
        final pay = await paymentService.initiateOnlinePayment(
          orderId: orderId,
          amount: total,
          userId: user.id,
        );
        if (!pay.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(pay.message)),
            );
          }
          setState(() => _placing = false);
          return;
        }
      } else {
        await paymentService.processCashOnDelivery(
          orderId: orderId,
          amount: total,
        );
      }

      await cart.clear();

      if (!mounted) return;
      context.goOverlay('/order-success/$orderId');
    } catch (e) {
      debugPrint('[Checkout] place order failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not place order. Please try again.'),
        ),
      );
      setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final addressProvider = context.watch<AddressProvider>();
    final selectedAddress = _selectedAddress ?? addressProvider.defaultAddress;

    if (cart.isEmpty && !_placing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(child: Text('Your cart is empty.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          Text(
            'Delivery address',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickAddress,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selectedAddress == null
                      ? AppColors.primary
                      : AppColors.border,
                ),
                color: AppColors.surface,
              ),
              child: addressProvider.isLoading && selectedAddress == null
                  ? const Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text('Loading addresses…'),
                      ],
                    )
                  : selectedAddress == null
                      ? const Row(
                          children: [
                            Icon(Icons.add_location_alt_outlined,
                                color: AppColors.primary),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Tap to add / select delivery address',
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedAddress.fullName,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(selectedAddress.phone),
                            const SizedBox(height: 4),
                            Text(selectedAddress.formattedAddress),
                            const SizedBox(height: 8),
                            const Text(
                              'Change',
                              style: TextStyle(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Payment method',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          _PaymentTile(
            title: 'Cash on Delivery',
            subtitle: 'Pay when your keychain is delivered home.',
            value: AppConstants.paymentCod,
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v),
          ),
          const SizedBox(height: 8),
          _PaymentTile(
            title: 'Online Payment',
            subtitle:
                'Secure checkout. Uses demo mode until the payment gateway is configured.',
            value: AppConstants.paymentOnline,
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v),
          ),
          const SizedBox(height: 24),
          Text(
            'Coupon',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          if (cart.couponCode != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                cart.couponCode!,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '− ${Formatters.currency(cart.discount)} applied',
              ),
              trailing: TextButton(
                onPressed: () {
                  cart.clearCoupon();
                  _couponController.clear();
                },
                child: const Text('Remove'),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'Enter code',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _applyingCoupon ? null : _applyCoupon,
                  child: _applyingCoupon
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Apply'),
                ),
              ],
            ),
          const SizedBox(height: 24),
          Text(
            'Order notes (optional)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Delivery instructions, landmark…',
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Order summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          ...cart.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.productName} × ${item.quantity}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(Formatters.currency(item.lineTotal)),
                ],
              ),
            ),
          ),
          const Divider(height: 24),
          _summaryRow('Subtotal', Formatters.currency(cart.subtotal)),
          _summaryRow(
            'Delivery',
            cart.deliveryCharges == 0
                ? 'Free'
                : Formatters.currency(cart.deliveryCharges),
          ),
          if (cart.discount > 0)
            _summaryRow(
              'Discount',
              '− ${Formatters.currency(cart.discount)}',
            ),
          const SizedBox(height: 6),
          _summaryRow(
            'Total',
            Formatters.currency(cart.total),
            bold: true,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: AppButton(
            label: _paymentMethod == AppConstants.paymentCod
                ? 'Place order (COD)'
                : 'Continue to online payment',
            isLoading: _placing,
            onPressed: _placing ? null : _placeOrder,
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    final style = bold
        ? const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.textHint,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
