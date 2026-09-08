import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/models/product_model.dart';
import 'package:keychain_shop/router/app_router.dart';
import 'package:keychain_shop/services/firestore_service.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/utils/product_filters.dart';
import 'package:keychain_shop/widgets/product_card.dart';
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
  static const _catalogLimit = 200;

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

  @override
  void didUpdateWidget(covariant ProductListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section ||
        oldWidget.categoryId != widget.categoryId) {
      _filters = ProductFilters(
        categoryId: widget.categoryId,
        section: widget.section,
      );
      _load();
    }
  }

  Future<List<ProductModel>> _fetchForSection(
    FirestoreService firestore,
  ) async {
    if (widget.categoryId != null && widget.categoryId!.isNotEmpty) {
      return firestore.getProductsByCategory(
        widget.categoryId!,
        limit: _catalogLimit,
      );
    }

    switch (widget.section) {
      case ProductSection.featured:
        return firestore.getFeaturedProducts(limit: _catalogLimit);
      case ProductSection.newArrival:
        return firestore.getNewArrivals(limit: _catalogLimit);
      case ProductSection.bestSeller:
        return firestore.getBestSellers(limit: _catalogLimit);
      case ProductSection.discount:
        return firestore.getDiscountedProducts(limit: _catalogLimit);
      case ProductSection.all:
        return firestore.getActiveProducts(limit: _catalogLimit);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final firestore = context.read<FirestoreService>();
      // Always pull the full active catalog as a base, then apply the section
      // client-side so every chip shows the correct subset (not a tiny shared list).
      final catalog = await firestore.getActiveProducts(limit: _catalogLimit);
      var products = await _fetchForSection(firestore);

      // If a section query fails / returns empty while catalog has matches, use
      // client-side filter so Featured/New/Best/Discount still work.
      if (products.isEmpty && catalog.isNotEmpty) {
        products = ProductFilters(section: widget.section).apply(catalog);
      }

      // Keep full catalog for material filter chips; visible list is sectioned.
      final baseForFilters = catalog.isNotEmpty ? catalog : products;

      if (!mounted) return;
      setState(() {
        _all = baseForFilters;
        _filters = ProductFilters(
          categoryId: widget.categoryId,
          section: widget.section,
        );
        _visible = _filters.apply(
          widget.categoryId != null && widget.categoryId!.isNotEmpty
              ? products
              : baseForFilters,
        );
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
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (_error != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(_error!, textAlign: TextAlign.center),
                        ),
                      ),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                        child: Text(
                          '${_visible.length} product${_visible.length == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    if (_visible.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No products in ${ProductFilters.sectionLabel(widget.section).toLowerCase()} yet.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.60,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return ProductCard(
                                product: _visible[index],
                                width: double.infinity,
                              );
                            },
                            childCount: _visible.length,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}
