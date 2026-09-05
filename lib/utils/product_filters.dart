import 'package:keychain_shop/models/product_model.dart';

enum ProductSort {
  newest,
  priceLowHigh,
  priceHighLow,
  rating,
  discount,
}

enum ProductSection {
  all,
  featured,
  newArrival,
  bestSeller,
  discount,
}

/// Client-side catalog filters (Firestore compound queries stay simple).
class ProductFilters {
  const ProductFilters({
    this.categoryId,
    this.section = ProductSection.all,
    this.minPrice,
    this.maxPrice,
    this.material,
    this.inStockOnly = false,
    this.customizableOnly = false,
    this.sort = ProductSort.newest,
    this.searchQuery,
  });

  final String? categoryId;
  final ProductSection section;
  final double? minPrice;
  final double? maxPrice;
  final String? material;
  final bool inStockOnly;
  final bool customizableOnly;
  final ProductSort sort;
  final String? searchQuery;

  ProductFilters copyWith({
    String? categoryId,
    bool clearCategory = false,
    ProductSection? section,
    double? minPrice,
    bool clearMinPrice = false,
    double? maxPrice,
    bool clearMaxPrice = false,
    String? material,
    bool clearMaterial = false,
    bool? inStockOnly,
    bool? customizableOnly,
    ProductSort? sort,
    String? searchQuery,
    bool clearSearch = false,
  }) {
    return ProductFilters(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      section: section ?? this.section,
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      material: clearMaterial ? null : (material ?? this.material),
      inStockOnly: inStockOnly ?? this.inStockOnly,
      customizableOnly: customizableOnly ?? this.customizableOnly,
      sort: sort ?? this.sort,
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
    );
  }

  int get activeCount {
    var count = 0;
    if (categoryId != null) count++;
    if (section != ProductSection.all) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (material != null && material!.isNotEmpty) count++;
    if (inStockOnly) count++;
    if (customizableOnly) count++;
    if (sort != ProductSort.newest) count++;
    return count;
  }

  List<ProductModel> apply(List<ProductModel> source) {
    var list = List<ProductModel>.from(source);

    if (categoryId != null && categoryId!.isNotEmpty) {
      list = list.where((p) => p.categoryId == categoryId).toList();
    }

    switch (section) {
      case ProductSection.featured:
        list = list.where((p) => p.isFeatured).toList();
      case ProductSection.newArrival:
        list = list.where((p) => p.isNewArrival).toList();
      case ProductSection.bestSeller:
        list = list.where((p) => p.isBestSeller).toList();
      case ProductSection.discount:
        list = list.where((p) => p.hasDiscount).toList();
      case ProductSection.all:
        break;
    }

    if (minPrice != null) {
      list = list.where((p) => p.discountedPrice >= minPrice!).toList();
    }
    if (maxPrice != null) {
      list = list.where((p) => p.discountedPrice <= maxPrice!).toList();
    }

    if (material != null && material!.trim().isNotEmpty) {
      final m = material!.trim().toLowerCase();
      list = list
          .where((p) => (p.material ?? '').toLowerCase().contains(m))
          .toList();
    }

    if (inStockOnly) {
      list = list.where((p) => p.inStock).toList();
    }

    if (customizableOnly) {
      list = list.where((p) => p.isCustomizable).toList();
    }

    final q = searchQuery?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      list = list
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.description.toLowerCase().contains(q) ||
                (p.material ?? '').toLowerCase().contains(q) ||
                (p.categoryName ?? '').toLowerCase().contains(q),
          )
          .toList();
    }

    switch (sort) {
      case ProductSort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ProductSort.priceLowHigh:
        list.sort((a, b) => a.discountedPrice.compareTo(b.discountedPrice));
      case ProductSort.priceHighLow:
        list.sort((a, b) => b.discountedPrice.compareTo(a.discountedPrice));
      case ProductSort.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case ProductSort.discount:
        list.sort((a, b) => b.discount.compareTo(a.discount));
    }

    return list;
  }

  static String sectionLabel(ProductSection section) {
    switch (section) {
      case ProductSection.all:
        return 'All products';
      case ProductSection.featured:
        return 'Featured';
      case ProductSection.newArrival:
        return 'New arrivals';
      case ProductSection.bestSeller:
        return 'Best sellers';
      case ProductSection.discount:
        return 'Discounts';
    }
  }

  static String sortLabel(ProductSort sort) {
    switch (sort) {
      case ProductSort.newest:
        return 'Newest';
      case ProductSort.priceLowHigh:
        return 'Price: Low to High';
      case ProductSort.priceHighLow:
        return 'Price: High to Low';
      case ProductSort.rating:
        return 'Top rated';
      case ProductSort.discount:
        return 'Biggest discount';
    }
  }
}
