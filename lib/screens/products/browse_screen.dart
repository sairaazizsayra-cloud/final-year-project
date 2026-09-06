import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/models/category_model.dart';
import 'package:keychain_shop/router/app_router.dart';
import 'package:keychain_shop/services/firestore_service.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/utils/product_filters.dart';
import 'package:keychain_shop/widgets/section_header.dart';

/// Browse tab — categories + quick catalog entry points.
class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  List<CategoryModel> _categories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cats =
          await context.read<FirestoreService>().getActiveCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load categories.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.pushOverlay('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () => context.pushOverlay('/favorites'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: InkWell(
                onTap: () => context.pushOverlay('/search'),
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.soft,
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: AppColors.textHint),
                      SizedBox(width: 12),
                      Text(
                        'Search keychains…',
                        style: TextStyle(color: AppColors.textHint, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SectionHeader(
              title: 'Shop by collection',
              subtitle: 'Jump into a curated shelf',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickChip(
                    label: 'All products',
                    icon: Icons.apps_outlined,
                    onTap: () => context.pushOverlay('/products'),
                  ),
                  _QuickChip(
                    label: 'Featured',
                    icon: Icons.star_outline,
                    onTap: () => context.pushOverlay(
                      '/products?section=${ProductSection.featured.name}',
                    ),
                  ),
                  _QuickChip(
                    label: 'New arrivals',
                    icon: Icons.auto_awesome_outlined,
                    onTap: () => context.pushOverlay(
                      '/products?section=${ProductSection.newArrival.name}',
                    ),
                  ),
                  _QuickChip(
                    label: 'Best sellers',
                    icon: Icons.local_fire_department_outlined,
                    onTap: () => context.pushOverlay(
                      '/products?section=${ProductSection.bestSeller.name}',
                    ),
                  ),
                  _QuickChip(
                    label: 'Discounts',
                    icon: Icons.local_offer_outlined,
                    onTap: () => context.pushOverlay(
                      '/products?section=${ProductSection.discount.name}',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const SectionHeader(title: 'Categories'),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_error != null)
              EmptyHint(message: _error!)
            else if (_categories.isEmpty)
              const EmptyHint(
                message: 'No categories yet. Admin can add them in Phase 6.',
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.15,
                  ),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    return _CategoryTile(
                      category: cat,
                      onTap: () => context.pushOverlay(
                        '/products?categoryId=${cat.id}&title=${Uri.encodeComponent(cat.name)}',
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: icon != null ? Icon(icon, size: 16) : null,
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.border),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final CategoryModel category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.border),
          color: AppColors.surface,
          boxShadow: AppShadows.soft,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (category.imageUrl != null && category.imageUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: category.imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) =>
                    Container(color: AppColors.surfaceMuted),
              )
            else
              Container(
                color: AppColors.surfaceMuted,
                child: const Icon(
                  Icons.category_outlined,
                  size: 36,
                  color: AppColors.primaryLight,
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
