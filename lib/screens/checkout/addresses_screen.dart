import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/models/address_model.dart';
import 'package:keychain_shop/providers/address_provider.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/widgets/app_button.dart';

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key, this.selectMode = false});

  /// When true, tapping an address pops it back for checkout.
  final bool selectMode;

  @override
  Widget build(BuildContext context) {
    final addresses = context.watch<AddressProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(selectMode ? 'Select address' : 'Addresses'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/addresses/form'),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: addresses.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : addresses.addresses.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 64,
                          color: AppColors.primaryLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No delivery addresses',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add a home address for home-to-home delivery.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          label: 'Add address',
                          onPressed: () => context.push('/addresses/form'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                  itemCount: addresses.addresses.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final address = addresses.addresses[index];
                    return _AddressCard(
                      address: address,
                      selectMode: selectMode,
                      onTap: () {
                        if (selectMode) {
                          context.pop(address);
                        }
                      },
                      onEdit: () => context.push(
                        '/addresses/form',
                        extra: address,
                      ),
                      onDelete: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete address?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await addresses.delete(address.id);
                        }
                      },
                      onSetDefault: () => addresses.setDefault(address.id),
                    );
                  },
                ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.selectMode,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  final AddressModel address;
  final bool selectMode;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: selectMode ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: address.isDefault ? AppColors.primary : AppColors.border,
            width: address.isDefault ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    address.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Default',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(address.phone),
            const SizedBox(height: 4),
            Text(
              address.formattedAddress,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (!selectMode) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(onPressed: onEdit, child: const Text('Edit')),
                  TextButton(
                    onPressed: onDelete,
                    child: const Text('Delete'),
                  ),
                  if (!address.isDefault)
                    TextButton(
                      onPressed: onSetDefault,
                      child: const Text('Set default'),
                    ),
                ],
              ),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Tap to select',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
