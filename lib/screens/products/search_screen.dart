import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/models/product_model.dart';
import 'package:keychain_shop/services/firestore_service.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/utils/product_filters.dart';
import 'package:keychain_shop/widgets/product_grid.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  List<ProductModel> _catalog = [];
  List<ProductModel> _results = [];
  ProductFilters _filters = const ProductFilters();
  bool _loadingCatalog = true;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  Future<void> _loadCatalog() async {
    try {
      final products =
          await context.read<FirestoreService>().getActiveProducts(limit: 100);
      if (!mounted) return;
      setState(() {
        _catalog = products;
        _loadingCatalog = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCatalog = false);
    }
  }

  Future<void> _runSearch(String query) async {
    final q = query.trim();
    setState(() {
      _filters = _filters.copyWith(
        searchQuery: q,
        clearSearch: q.isEmpty,
      );
      _searching = true;
    });

    if (q.isEmpty) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }

    // Instant client filter; also try Firestore prefix when possible.
    var local = _filters.apply(_catalog);

    try {
      final remote =
          await context.read<FirestoreService>().searchProducts(q);
      if (remote.isNotEmpty) {
        final ids = remote.map((p) => p.id).toSet();
        final merged = [
          ...remote,
          ...local.where((p) => !ids.contains(p.id)),
        ];
        local = _filters.copyWith(clearSearch: true).apply(merged);
        // Re-apply text filter for consistency when remote returns prefix-only
        local = local
            .where(
              (p) =>
                  p.name.toLowerCase().contains(q.toLowerCase()) ||
                  p.description.toLowerCase().contains(q.toLowerCase()) ||
                  (p.material ?? '').toLowerCase().contains(q.toLowerCase()),
            )
            .toList();
      }
    } catch (_) {
      // Keep local results
    }

    if (!mounted) return;
    setState(() {
      _results = local;
      _searching = false;
    });
  }

  List<String> get _materials {
    final set = <String>{};
    for (final p in _catalog) {
      if (p.material != null && p.material!.trim().isNotEmpty) {
        set.add(p.material!.trim());
      }
    }
    return (set.toList()..sort());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search keychains…',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
          onChanged: _runSearch,
          onSubmitted: _runSearch,
        ),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                _runSearch('');
              },
            ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () async {
              final result = await showProductFilterSheet(
                context: context,
                current: _filters,
                materials: _materials,
              );
              if (result == null || !mounted) return;
              setState(() => _filters = result);
              _runSearch(_controller.text);
            },
          ),
        ],
      ),
      body: _loadingCatalog
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : query.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search,
                            size: 56, color: AppColors.primaryLight),
                        const SizedBox(height: 12),
                        Text(
                          'Search by name, material, or style',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                )
              : _searching
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    )
                  : ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                          child: Text(
                            '${_results.length} result${_results.length == 1 ? '' : 's'} for "$query"',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        ProductGrid(
                          products: _results,
                          emptyMessage: 'No keychains matched your search.',
                        ),
                      ],
                    ),
    );
  }
}
