import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/models/product_model.dart';
import 'package:keychain_shop/router/app_router.dart';
import 'package:keychain_shop/services/firestore_service.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/utils/product_filters.dart';
import 'package:keychain_shop/widgets/product_grid.dart';

/// Filtered product listing (category / section / sort).
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({
    super.key,
    this.categoryId,
    this.title,
    this.section = ProductSection.all,
  });

  final String? categoryId;
  final String? title;
  final ProductSection section;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<ProductModel> _all = [];
  List<ProductModel> _visible = [];
  late ProductFilters _filters;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _filters = ProductFilters(
      categoryId: widget.categoryId,
      section: widget.section,
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final firestore = context.read<FirestoreService>();
      List<ProductModel> products;

      if (widget.categoryId != null && widget.categoryId!.isNotEmpty) {
        products = await firestore.getProductsByCategory(
          widget.categoryId!,
          limit: 80,
        );
      } else {
        products = await firestore.getActiveProducts(limit: 100);
      }

      if (!mounted) return;
      setState(() {
        _all = products;
        _visible = _filters.apply(_all);
        _loading = false;
      });
    } catch (e) {
      debugPrint('[ProductListScreen] $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load products.';
      });
    }
  }

  List<String> get _materials {
    final set = <String>{};
    for (final p in _all) {
      if (p.material != null && p.material!.trim().isNotEmpty) {
        set.add(p.material!.trim());
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  Future<void> _openFilters() async {
    final result = await showProductFilterSheet(
      context: context,
      current: _filters,
      materials: _materials,
    );
    if (result == null || !mounted) return;
    setState(() {
      _filters = result.copyWith(
        categoryId: widget.categoryId,
        section: widget.section,
      );
      _visible = _filters.apply(_all);
    });
  }

  String get _title {
    if (widget.title != null && widget.title!.isNotEmpty) return widget.title!;
    return ProductFilters.sectionLabel(widget.section);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _filters.activeCount > 0,
              label: Text('${_filters.activeCount}'),
              child: const Icon(Icons.tune),
            ),
            onPressed: _openFilters,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.pushOverlay('/search'),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(_error!, textAlign: TextAlign.center),
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                      child: Text(
                        '${_visible.length} product${_visible.length == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    ProductGrid(
                      products: _visible,
                      emptyMessage:
                          'No products match these filters. Try adjusting filters or check back later.',
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
