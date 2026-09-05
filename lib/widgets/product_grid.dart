import 'package:flutter/material.dart';
import 'package:keychain_shop/models/product_model.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/utils/product_filters.dart';
import 'package:keychain_shop/widgets/product_card.dart';
import 'package:keychain_shop/widgets/section_header.dart';

/// Responsive product grid used by browse, list, search, and favorites.
class ProductGrid extends StatelessWidget {
  const ProductGrid({
    super.key,
    required this.products,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 24),
    this.emptyMessage = 'No products found.',
  });

  final List<ProductModel> products;
  final EdgeInsets padding;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Padding(
        padding: padding,
        child: EmptyHint(message: emptyMessage),
      );
    }

    return GridView.builder(
      padding: padding,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, index) {
        return ProductCard(
          product: products[index],
          width: double.infinity,
        );
      },
    );
  }
}

/// Bottom sheet for catalog filters.
Future<ProductFilters?> showProductFilterSheet({
  required BuildContext context,
  required ProductFilters current,
  required List<String> materials,
}) {
  return showModalBottomSheet<ProductFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return _FilterSheet(current: current, materials: materials);
    },
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.current, required this.materials});

  final ProductFilters current;
  final List<String> materials;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late ProductFilters _filters;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _filters = widget.current;
    _minController = TextEditingController(
      text: _filters.minPrice?.toStringAsFixed(0) ?? '',
    );
    _maxController = TextEditingController(
      text: _filters.maxPrice?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Filters',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            Text('Sort by', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ProductSort.values.map((sort) {
                final selected = _filters.sort == sort;
                return ChoiceChip(
                  label: Text(ProductFilters.sortLabel(sort)),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _filters = _filters.copyWith(sort: sort)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Price range (Rs)',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Min'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Max'),
                  ),
                ),
              ],
            ),
            if (widget.materials.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Material', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Any'),
                    selected: _filters.material == null,
                    onSelected: (_) => setState(
                      () => _filters = _filters.copyWith(clearMaterial: true),
                    ),
                  ),
                  ...widget.materials.map((m) {
                    return ChoiceChip(
                      label: Text(m),
                      selected: _filters.material == m,
                      onSelected: (_) => setState(
                        () => _filters = _filters.copyWith(material: m),
                      ),
                    );
                  }),
                ],
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('In stock only'),
              value: _filters.inStockOnly,
              activeThumbColor: AppColors.primary,
              onChanged: (v) => setState(
                () => _filters = _filters.copyWith(inStockOnly: v),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Customizable only'),
              value: _filters.customizableOnly,
              activeThumbColor: AppColors.primary,
              onChanged: (v) => setState(
                () => _filters = _filters.copyWith(customizableOnly: v),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _filters = const ProductFilters();
                        _minController.clear();
                        _maxController.clear();
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final min = double.tryParse(_minController.text.trim());
                      final max = double.tryParse(_maxController.text.trim());
                      Navigator.of(context).pop(
                        _filters.copyWith(
                          minPrice: min,
                          clearMinPrice: min == null,
                          maxPrice: max,
                          clearMaxPrice: max == null,
                        ),
                      );
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
