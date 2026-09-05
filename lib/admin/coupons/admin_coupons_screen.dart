import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/models/coupon_model.dart';
import 'package:keychain_shop/services/firestore_service.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/utils/formatters.dart';

class AdminCouponsScreen extends StatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen> {
  Future<void> _openForm({CouponModel? existing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CouponFormSheet(existing: existing),
    );
  }

  Future<void> _toggleActive(CouponModel coupon) async {
    try {
      await context
          .read<FirestoreService>()
          .setCouponActive(coupon.id, !coupon.isActive);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  Future<void> _delete(CouponModel coupon) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${coupon.code}?'),
        content: const Text('Customers will no longer be able to use this code.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<FirestoreService>().deleteCoupon(coupon.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add coupon'),
      ),
      body: StreamBuilder<List<CouponModel>>(
        stream: context.read<FirestoreService>().watchAllCoupons(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final coupons = snapshot.data ?? [];
          if (coupons.isEmpty) {
            return const Center(
              child: Text('No coupons yet. Tap Add coupon to create one.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: coupons.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final c = coupons[index];
              final discount = c.isPercentage
                  ? '${c.discountValue.toStringAsFixed(0)}%'
                  : Formatters.currency(c.discountValue);
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                title: Text(
                  c.code,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '$discount off · min ${Formatters.currency(c.minOrderAmount)}\n'
                  '${Formatters.date(c.validFrom)} → ${Formatters.date(c.validUntil)}\n'
                  'Used ${c.usedCount}'
                  '${c.usageLimit == 0 ? '' : ' / ${c.usageLimit}'}'
                  '${c.isActive ? '' : ' · Inactive'}'
                  '${c.isValidNow ? '' : ' · Not valid now'}',
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _openForm(existing: c);
                      case 'toggle':
                        _toggleActive(c);
                      case 'delete':
                        _delete(c);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(c.isActive ? 'Deactivate' : 'Activate'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CouponFormSheet extends StatefulWidget {
  const _CouponFormSheet({this.existing});

  final CouponModel? existing;

  @override
  State<_CouponFormSheet> createState() => _CouponFormSheetState();
}

class _CouponFormSheetState extends State<_CouponFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _description;
  late final TextEditingController _discountValue;
  late final TextEditingController _minOrder;
  late final TextEditingController _maxDiscount;
  late final TextEditingController _usageLimit;
  late String _discountType;
  late DateTime _validFrom;
  late DateTime _validUntil;
  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _code = TextEditingController(text: e?.code ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _discountValue = TextEditingController(
      text: e != null ? e.discountValue.toStringAsFixed(0) : '',
    );
    _minOrder = TextEditingController(
      text: e != null ? e.minOrderAmount.toStringAsFixed(0) : '0',
    );
    _maxDiscount = TextEditingController(
      text: e?.maxDiscount?.toStringAsFixed(0) ?? '',
    );
    _usageLimit = TextEditingController(
      text: e != null ? '${e.usageLimit}' : '0',
    );
    _discountType = e?.discountType ?? 'percentage';
    _validFrom = e?.validFrom ?? DateTime.now();
    _validUntil =
        e?.validUntil ?? DateTime.now().add(const Duration(days: 30));
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _code.dispose();
    _description.dispose();
    _discountValue.dispose();
    _minOrder.dispose();
    _maxDiscount.dispose();
    _usageLimit.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool from}) async {
    final initial = from ? _validFrom : _validUntil;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() {
      if (from) {
        _validFrom = picked;
      } else {
        _validUntil = DateTime(picked.year, picked.month, picked.day, 23, 59);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final maxText = _maxDiscount.text.trim();
      final coupon = CouponModel(
        id: widget.existing?.id ?? '',
        code: _code.text.trim().toUpperCase(),
        description: _description.text.trim(),
        discountType: _discountType,
        discountValue: double.parse(_discountValue.text.trim()),
        minOrderAmount: double.tryParse(_minOrder.text.trim()) ?? 0,
        maxDiscount: maxText.isEmpty ? null : double.tryParse(maxText),
        usageLimit: int.tryParse(_usageLimit.text.trim()) ?? 0,
        usedCount: widget.existing?.usedCount ?? 0,
        validFrom: _validFrom,
        validUntil: _validUntil,
        isActive: _isActive,
      );
      await context.read<FirestoreService>().saveCoupon(coupon);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing == null ? 'New coupon' : 'Edit coupon',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Code'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _discountType,
                decoration: const InputDecoration(labelText: 'Discount type'),
                items: const [
                  DropdownMenuItem(
                    value: 'percentage',
                    child: Text('Percentage'),
                  ),
                  DropdownMenuItem(value: 'fixed', child: Text('Fixed amount')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _discountType = v);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _discountValue,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: _discountType == 'percentage'
                      ? 'Discount %'
                      : 'Discount amount (Rs)',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Invalid';
                  if (_discountType == 'percentage' && n > 100) {
                    return 'Max 100%';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _minOrder,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Minimum order (Rs)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxDiscount,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Max discount (Rs, optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usageLimit,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Usage limit (0 = unlimited)',
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Valid from'),
                subtitle: Text(Formatters.date(_validFrom)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () => _pickDate(from: true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Valid until'),
                subtitle: Text(Formatters.date(_validUntil)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () => _pickDate(from: false),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _isActive,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save coupon'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
