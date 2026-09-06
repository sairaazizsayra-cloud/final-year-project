import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/models/category_model.dart';
import 'package:keychain_shop/models/product_model.dart';
import 'package:keychain_shop/providers/auth_provider.dart';
import 'package:keychain_shop/providers/notifications_provider.dart';
import 'package:keychain_shop/services/firestore_service.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/utils/product_filters.dart';
import 'package:keychain_shop/widgets/product_card.dart';
import 'package:keychain_shop/widgets/section_header.dart';

/// Customer home — search, categories, featured / new / bestseller / discounts.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CategoryModel> _categories = [];
  List<ProductModel> _featured = [];
  List<ProductModel> _newArrivals = [];
  List<ProductModel> _bestSellers = [];
  List<ProductModel> _discounted = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final firestore = context.read<FirestoreService>();

    try {
      // Load independently so one missing index doesn't blank the whole home.
      final categories = await firestore.getActiveCategories().catchError((e) {
        debugPrint('[HomeScreen] categories: $e');
        return <CategoryModel>[];
      });
      final featured = await firestore.getFeaturedProducts().catchError((e) {
        debugPrint('[HomeScreen] featured: $e');
        return <ProductModel>[];
      });
      final newArrivals = await firestore.getNewArrivals().catchError((e) {
        debugPrint('[HomeScreen] newArrivals: $e');
        return <ProductModel>[];
      });
      final bestSellers = await firestore.getBestSellers().catchError((e) {
        debugPrint('[HomeScreen] bestSellers: $e');
        return <ProductModel>[];
      });
      final allProducts =
          await firestore.getActiveProducts(limit: 40).catchError((e) {
        debugPrint('[HomeScreen] products: $e');
        return <ProductModel>[];
      });

      final discounted = allProducts.where((p) => p.hasDiscount).toList()
        ..sort((a, b) => b.discount.compareTo(a.discount));

      if (!mounted) return;
      final hasAny = categories.isNotEmpty ||
          featured.isNotEmpty ||
          newArrivals.isNotEmpty ||
          bestSellers.isNotEmpty ||
          allProducts.isNotEmpty;
      setState(() {
        _categories = categories;
        _featured = featured;
        _newArrivals = newArrivals;
        _bestSellers = bestSellers;
        _discounted = discounted.take(10).toList();
        _loading = false;
        _error = hasAny
            ? null
            : 'Could not load catalog yet. Add products in Admin or wait for Firestore indexes to finish building.';
      });
    } catch (e) {
      debugPrint('[HomeScreen] load error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'Could not load catalog yet. Add products in Admin (Phase 6) or check Firebase.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = (user?.name ?? 'there').split(' ').first;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadHomeData,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _Header(firstName: firstName)),
          const SliverToBoxAdapter(child: _SearchBar()),
          SliverToBoxAdapter(child: _PromoBanner()),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else ...[
            if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: EmptyHint(message: _error!),
                ),
              ),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Categories',
                subtitle: 'Shop by collection',
                onSeeAll: () => context.go('/browse'),
              ),
            ),
            SliverToBoxAdapter(child: _CategoryRow(categories: _categories)),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Featured',
                onSeeAll: () => context.push(
                  '/products?section=${ProductSection.featured.name}',
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _ProductRow(
                products: _featured,
                emptyMessage: 'Featured keychains will appear here.',
              ),
            ),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'New Arrivals',
                onSeeAll: () => context.push(
                  '/products?section=${ProductSection.newArrival.name}',
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _ProductRow(
                products: _newArrivals,
                emptyMessage: 'New arrivals will appear here.',
              ),
            ),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Best Sellers',
                onSeeAll: () => context.push(
                  '/products?section=${ProductSection.bestSeller.name}',
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _ProductRow(
                products: _bestSellers,
                emptyMessage: 'Best sellers will appear here.',
              ),
            ),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Discounts',
                onSeeAll: () => context.push(
                  '/products?section=${ProductSection.discount.name}',
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _ProductRow(
                products: _discounted,
                emptyMessage: 'Discounted keychains will appear here.',
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    final initial =
        firstName.isNotEmpty ? firstName.characters.first.toUpperCase() : 'K';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $firstName',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Find your next favorite keychain',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            _RoundIconButton(
              icon: Icons.favorite_border,
              onPressed: () => context.push('/favorites'),
            ),
            Consumer<NotificationsProvider>(
              builder: (context, notifications, _) {
                return _RoundIconButton(
                  icon: Icons.notifications_none_rounded,
                  badgeCount: notifications.unreadCount,
                  onPressed: () => context.push('/notifications'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onPressed,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: badgeCount > 0,
        label: Text('$badgeCount'),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        elevation: 0,
        child: InkWell(
          onTap: () => context.push('/search'),
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.soft,
            ),
            child: const Row(
              children: [
                Icon(Icons.search, color: AppColors.textHint),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search keychains, materials, styles…',
                    style: TextStyle(color: AppColors.textHint, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/browse'),
      child: Container(
        height: 156,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2C3E50),
              Color(0xFF8B5A2B),
              Color(0xFFB87333),
            ],
          ),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Home-to-Home Delivery',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Custom keychains delivered to your doorstep.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Shop collections →',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.key_rounded, color: Colors.white24, size: 72),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.categories});

  final List<CategoryModel> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const EmptyHint(
        message: 'Categories will appear here once added by admin.',
      );
    }

    return SizedBox(
      height: 112,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final hasImage = cat.imageUrl != null && cat.imageUrl!.isNotEmpty;
          return InkWell(
            onTap: () => context.push(
              '/products?categoryId=${cat.id}&title=${Uri.encodeComponent(cat.name)}',
            ),
            borderRadius: BorderRadius.circular(18),
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.soft,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: cat.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => const Icon(
                            Icons.category_outlined,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(
                          Icons.category_outlined,
                          color: AppColors.primary,
                        ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 76,
                  child: Text(
                    cat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.products,
    required this.emptyMessage,
  });

  final List<ProductModel> products;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return EmptyHint(message: emptyMessage);
    }

    return SizedBox(
      height: 258,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return ProductCard(product: products[index]);
        },
      ),
    );
  }
}
