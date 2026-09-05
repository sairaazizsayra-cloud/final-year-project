import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/models/address_model.dart';
import 'package:keychain_shop/providers/address_provider.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/utils/validators.dart';
import 'package:keychain_shop/widgets/app_button.dart';
import 'package:keychain_shop/widgets/app_text_field.dart';

class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key, this.existing});

  final AddressModel? existing;

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _house;
  late final TextEditingController _area;
  late final TextEditingController _city;
  late final TextEditingController _postal;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.fullName ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _house = TextEditingController(text: e?.houseStreet ?? '');
    _area = TextEditingController(text: e?.area ?? '');
    _city = TextEditingController(text: e?.city ?? '');
    _postal = TextEditingController(text: e?.postalCode ?? '');
    _isDefault = e?.isDefault ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _house.dispose();
    _area.dispose();
    _city.dispose();
    _postal.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AddressProvider>();
    final existing = widget.existing;

    final address = AddressModel(
      id: existing?.id ?? '',
      userId: existing?.userId ?? '',
      fullName: _name.text.trim(),
      phone: _phone.text.trim(),
      houseStreet: _house.text.trim(),
      area: _area.text.trim(),
      city: _city.text.trim(),
      postalCode: _postal.text.trim(),
      isDefault: _isDefault,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    final ok = await provider.save(address);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address saved')),
      );
      context.pop();
    } else if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.watch<AddressProvider>().isSaving;
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit address' : 'Add address'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Home-to-home delivery details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'We deliver to your door using the address below.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _name,
                label: 'Full name',
                prefixIcon: Icons.person_outline,
                validator: Validators.name,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _phone,
                label: 'Phone',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _house,
                label: 'House / Street',
                prefixIcon: Icons.home_outlined,
                validator: (v) => Validators.requiredField(v, 'House / Street'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _area,
                label: 'Area',
                prefixIcon: Icons.map_outlined,
                validator: (v) => Validators.requiredField(v, 'Area'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _city,
                label: 'City',
                prefixIcon: Icons.location_city_outlined,
                validator: (v) => Validators.requiredField(v, 'City'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _postal,
                label: 'Postal code',
                prefixIcon: Icons.markunread_mailbox_outlined,
                keyboardType: TextInputType.number,
                validator: (v) => Validators.requiredField(v, 'Postal code'),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Set as default address'),
                value: _isDefault,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _isDefault = v),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: isEdit ? 'Update address' : 'Save address',
                isLoading: saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
