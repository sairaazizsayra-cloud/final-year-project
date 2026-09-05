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
      final results = await Future.wait([
        firestore.getActiveCategories(),
        firestore.getFeaturedProducts(),
        firestore.getNewArrivals(),
        firestore.getBestSellers(),
        firestore.getActiveProducts(limit: 40),
      ]);

      final allProducts = results[4] as List<ProductModel>;
      final discounted = allProducts.where((p) => p.hasDiscount).toList()
        ..sort((a, b) => b.discount.compareTo(a.discount));

      if (!mounted) return;
      setState(() {
        _categories = results[0] as List<CategoryModel>;
        _featured = results[1] as List<ProductModel>;
        _newArrivals = results[2] as List<ProductModel>;
        _bestSellers = results[3] as List<ProductModel>;
        _discounted = discounted.take(10).toList();
        _loading = false;
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
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
                const SizedBox(height: 4),
                Text(
                  'Find your next favorite keychain',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/favorites'),
            icon: const Icon(Icons.favorite_border),
          ),
          Consumer<NotificationsProvider>(
            builder: (context, notifications, _) {
              return IconButton(
                onPressed: () => context.push('/notifications'),
                icon: Badge(
                  isLabelVisible: notifications.unreadCount > 0,
                  label: Text('${notifications.unreadCount}'),
                  child: const Icon(Icons.notifications_none_rounded),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: TextField(
        readOnly: true,
        onTap: () => context.push('/search'),
        decoration: const InputDecoration(
          hintText: 'Search keychains, materials, styles…',
          prefixIcon: Icon(Icons.search, color: AppColors.textHint),
          filled: true,
          fillColor: AppColors.surface,
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2C3E50),
            Color(0xFF8B5A2B),
            Color(0xFFB87333),
          ],
        ),
      ),
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
        ],
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
      height: 104,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return InkWell(
            onTap: () => context.push(
              '/products?categoryId=${cat.id}&title=${Uri.encodeComponent(cat.name)}',
            ),
            borderRadius: BorderRadius.circular(18),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.category_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 72,
                  child: Text(
                    cat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
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
      height: 250,
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
