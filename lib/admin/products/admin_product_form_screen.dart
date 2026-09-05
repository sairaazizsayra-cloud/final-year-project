import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/models/category_model.dart';
import 'package:keychain_shop/models/product_model.dart';
import 'package:keychain_shop/services/firestore_service.dart';
import 'package:keychain_shop/services/storage_service.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/widgets/app_button.dart';
import 'package:keychain_shop/widgets/app_text_field.dart';

class AdminProductFormScreen extends StatefulWidget {
  const AdminProductFormScreen({super.key, this.existing});

  final ProductModel? existing;

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _discount;
  late final TextEditingController _stock;
  late final TextEditingController _material;
  late final TextEditingController _size;
  late final TextEditingController _colors;

  String? _categoryId;
  String? _categoryName;
  List<String> _images = [];
  List<CategoryModel> _categories = [];

  bool _isFeatured = false;
  bool _isBestSeller = false;
  bool _isNewArrival = false;
  bool _isCustomizable = false;
  bool _isActive = true;
  bool _saving = false;

  Uint8List? _pendingBytes;
  File? _pendingFile;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _price = TextEditingController(text: e?.price.toStringAsFixed(0) ?? '');
    _discount =
        TextEditingController(text: e?.discount.toStringAsFixed(0) ?? '0');
    _stock = TextEditingController(text: e?.stock.toString() ?? '0');
    _material = TextEditingController(text: e?.material ?? '');
    _size = TextEditingController(text: e?.size ?? '');
    _colors = TextEditingController(text: e?.colors.join(', ') ?? '');
    _categoryId = e?.categoryId;
    _categoryName = e?.categoryName;
    _images = List<String>.from(e?.images ?? const []);
    _isFeatured = e?.isFeatured ?? false;
    _isBestSeller = e?.isBestSeller ?? false;
    _isNewArrival = e?.isNewArrival ?? false;
    _isCustomizable = e?.isCustomizable ?? false;
    _isActive = e?.isActive ?? true;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await context.read<FirestoreService>().getAllCategories();
    if (!mounted) return;
    setState(() => _categories = cats);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _discount.dispose();
    _stock.dispose();
    _material.dispose();
    _size.dispose();
    _colors.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    setState(() {
      _pendingBytes = bytes;
      if (!kIsWeb) _pendingFile = File(xfile.path);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null || _categoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a category')),
      );
      return;
    }

    setState(() => _saving = true);
    final firestore = context.read<FirestoreService>();
    final storage = context.read<StorageService>();

    try {
      var images = List<String>.from(_images);
      var productId = widget.existing?.id ?? '';

      // Create doc first if new so we have an id for storage path.
      final draft = ProductModel(
        id: productId,
        name: _name.text.trim(),
        description: _description.text.trim(),
        categoryId: _categoryId!,
        categoryName: _categoryName,
        price: double.tryParse(_price.text.trim()) ?? 0,
        discount: double.tryParse(_discount.text.trim()) ?? 0,
        stock: int.tryParse(_stock.text.trim()) ?? 0,
        images: images,
        material: _material.text.trim().isEmpty ? null : _material.text.trim(),
        size: _size.text.trim().isEmpty ? null : _size.text.trim(),
        colors: _colors.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        isCustomizable: _isCustomizable,
        rating: widget.existing?.rating ?? 0,
        totalReviews: widget.existing?.totalReviews ?? 0,
        isFeatured: _isFeatured,
        isBestSeller: _isBestSeller,
        isNewArrival: _isNewArrival,
        isActive: _isActive,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
      );

      productId = await firestore.saveProduct(draft);

      if (_pendingBytes != null || _pendingFile != null) {
        final url = await storage.uploadProductImage(
          productId: productId,
          file: _pendingFile,
          bytes: _pendingBytes,
        );
        images = [url, ...images];
        await firestore.saveProduct(
          ProductModel(
            id: productId,
            name: draft.name,
            description: draft.description,
            categoryId: draft.categoryId,
            categoryName: draft.categoryName,
            price: draft.price,
            discount: draft.discount,
            stock: draft.stock,
            images: images,
            material: draft.material,
            size: draft.size,
            colors: draft.colors,
            isCustomizable: draft.isCustomizable,
            rating: draft.rating,
            totalReviews: draft.totalReviews,
            isFeatured: draft.isFeatured,
            isBestSeller: draft.isBestSeller,
            isNewArrival: draft.isNewArrival,
            isActive: draft.isActive,
            createdAt: draft.createdAt,
          ),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product saved')),
      );
      context.pop();
    } catch (e) {
      debugPrint('[AdminProductForm] $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit product' : 'Add product'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                  image: _pendingBytes != null
                      ? DecorationImage(
                          image: MemoryImage(_pendingBytes!),
                          fit: BoxFit.cover,
                        )
                      : (_images.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(_images.first),
                              fit: BoxFit.cover,
                            )
                          : null),
                ),
                child: _pendingBytes == null && _images.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined),
                            SizedBox(height: 8),
                            Text('Upload product image'),
                          ],
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _name,
              label: 'Name',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _description,
              label: 'Description',
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _categoryId?.isEmpty == true ? null : _categoryId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                final cat = _categories.where((c) => c.id == v).firstOrNull;
                setState(() {
                  _categoryId = v;
                  _categoryName = cat?.name;
                });
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _price,
                    label: 'Price',
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        double.tryParse(v ?? '') == null ? 'Invalid' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    controller: _discount,
                    label: 'Discount %',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _stock,
              label: 'Stock',
              keyboardType: TextInputType.number,
              validator: (v) =>
                  int.tryParse(v ?? '') == null ? 'Invalid' : null,
            ),
            const SizedBox(height: 12),
            AppTextField(controller: _material, label: 'Material'),
            const SizedBox(height: 12),
            AppTextField(controller: _size, label: 'Size'),
            const SizedBox(height: 12),
            AppTextField(
              controller: _colors,
              label: 'Colors (comma separated)',
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Customizable'),
              value: _isCustomizable,
              onChanged: (v) => setState(() => _isCustomizable = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Featured'),
              value: _isFeatured,
              onChanged: (v) => setState(() => _isFeatured = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Best seller'),
              value: _isBestSeller,
              onChanged: (v) => setState(() => _isBestSeller = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('New arrival'),
              value: _isNewArrival,
              onChanged: (v) => setState(() => _isNewArrival = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: isEdit ? 'Update product' : 'Create product',
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
