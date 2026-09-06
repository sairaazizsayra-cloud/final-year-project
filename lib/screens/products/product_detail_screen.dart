import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/models/product_model.dart';
import 'package:keychain_shop/models/review_model.dart';
import 'package:keychain_shop/providers/cart_provider.dart';
import 'package:keychain_shop/providers/favorites_provider.dart';
import 'package:keychain_shop/router/app_router.dart';
import 'package:keychain_shop/services/firestore_service.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/utils/formatters.dart';
import 'package:keychain_shop/widgets/app_button.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductModel? _product;
  List<ReviewModel> _reviews = [];
  bool _loading = true;
  String? _error;

  int _imageIndex = 0;
  String? _selectedColor;
  final _customTextController = TextEditingController();
  final _pageController = PageController();

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
      final firestore = context.read<FirestoreService>();
      final product = await firestore.getProduct(widget.productId);
      if (product == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Product not found.';
        });
        return;
      }

      List<ReviewModel> reviews = [];
      try {
        reviews = await firestore.getProductReviews(product.id);
      } catch (e) {
        debugPrint('[ProductDetail] reviews: $e');
      }

      if (!mounted) return;
      setState(() {
        _product = product;
        _reviews = reviews;
        _selectedColor =
            product.colors.isNotEmpty ? product.colors.first : null;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[ProductDetail] $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load product.';
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _customTextController.dispose();
    super.dispose();
  }

  Future<bool> _addToCart({bool showFeedback = true}) async {
    final product = _product;
    if (product == null || !product.inStock) return false;

    final cart = context.read<CartProvider>();
    final ok = await cart.addProduct(
      product: product,
      selectedColor: _selectedColor,
      selectedSize: product.size,
      customText: _customTextController.text.trim().isEmpty
          ? null
          : _customTextController.text.trim(),
    );

    if (!mounted) return false;

    if (ok) {
      if (showFeedback) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Added to cart'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                messenger.hideCurrentSnackBar();
                context.go(AppRouter.cart);
              },
            ),
          ),
        );
      }
      return true;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(cart.error ?? 'Could not add to cart.')),
      );
    return false;
  }

  Future<void> _buyNow() async {
    final ok = await _addToCart(showFeedback: false);
    if (ok && mounted) context.pushOverlay('/checkout');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_error != null || _product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error ?? 'Product not found.')),
      );
    }

    final product = _product!;
    final favorites = context.watch<FavoritesProvider>();
    final isFav = favorites.isFavorite(product.id);
    final images = product.images.where((url) => url.trim().isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () => favorites.toggle(product.id),
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? AppColors.error : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        children: [
          _ProductImageGallery(
            images: images,
            index: _imageIndex,
            controller: _pageController,
            onIndexChanged: (i) => setState(() => _imageIndex = i),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.categoryName != null)
                  Text(
                    product.categoryName!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                const SizedBox(height: 6),
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      Formatters.currency(product.discountedPrice),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (product.hasDiscount) ...[
                      const SizedBox(width: 10),
                      Text(
                        Formatters.currency(product.price),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.textHint,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${product.discount.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (product.rating > 0) ...[
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${product.rating.toStringAsFixed(1)} (${product.totalReviews})',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 16),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: product.inStock
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.inStock
                            ? 'In stock (${product.stock})'
                            : 'Out of stock',
                        style: TextStyle(
                          color: product.inStock
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.description.isEmpty
                      ? 'No description available.'
                      : product.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                ),
                if (product.material != null ||
                    product.size != null ||
                    product.isCustomizable) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (product.material != null)
                        Chip(label: Text('Material: ${product.material}')),
                      if (product.size != null)
                        Chip(label: Text('Size: ${product.size}')),
                      if (product.isCustomizable)
                        const Chip(
                          avatar: Icon(Icons.palette_outlined, size: 16),
                          label: Text('Customizable'),
                        ),
                    ],
                  ),
                ],
                if (product.colors.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Color',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: product.colors.map((color) {
                      final selected = _selectedColor == color;
                      return ChoiceChip(
                        label: Text(color),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _selectedColor = color),
                      );
                    }).toList(),
                  ),
                ],
                if (product.isCustomizable) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Customization',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _customTextController,
                    maxLength: 40,
                    decoration: const InputDecoration(
                      labelText: 'Custom text / name',
                      hintText: 'e.g. Ali, Best Friends…',
                    ),
                  ),
                ],
                if (_reviews.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Reviews',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ..._reviews.map((r) => _ReviewTile(review: r)),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: AppShadows.soft,
            border: const Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Consumer<CartProvider>(
            builder: (context, cart, _) {
              return Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Add to Cart',
                      isOutlined: true,
                      isLoading: cart.isMutating,
                      onPressed: product.inStock ? _addToCart : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      label: 'Buy Now',
                      isLoading: cart.isMutating,
                      onPressed: product.inStock ? _buyNow : null,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProductImageGallery extends StatelessWidget {
  const _ProductImageGallery({
    required this.images,
    required this.index,
    required this.controller,
    required this.onIndexChanged,
  });

  final List<String> images;
  final int index;
  final PageController controller;
  final ValueChanged<int> onIndexChanged;

  static const double _height = 360;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: AppColors.surfaceMuted,
            child: images.isEmpty
                ? const _GalleryFallback()
                : PageView.builder(
                    controller: controller,
                    itemCount: images.length,
                    onPageChanged: onIndexChanged,
                    itemBuilder: (context, i) {
                      return CachedNetworkImage(
                        imageUrl: images[i],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) =>
                            const ColoredBox(color: AppColors.surfaceMuted),
                        errorWidget: (context, url, error) =>
                            const _GalleryFallback(),
                      );
                    },
                  ),
          ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black26,
                    Colors.transparent,
                    Colors.black45,
                  ],
                ),
              ),
            ),
          ),
          if (images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (i) {
                  final selected = i == index;
                  return GestureDetector(
                    onTap: () {
                      controller.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: selected ? 22 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: selected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _GalleryFallback extends StatelessWidget {
  const _GalleryFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surfaceMuted,
      child: Center(
        child: Icon(
          Icons.key_rounded,
          size: 72,
          color: AppColors.primaryLight,
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                review.userName ?? 'Customer',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              const Icon(
                Icons.star_rounded,
                size: 16,
                color: AppColors.warning,
              ),
              Text(review.rating.toStringAsFixed(1)),
            ],
          ),
          const SizedBox(height: 6),
          Text(review.comment),
          const SizedBox(height: 4),
          Text(
            Formatters.date(review.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
