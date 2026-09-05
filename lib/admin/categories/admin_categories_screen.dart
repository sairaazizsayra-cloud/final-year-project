import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/models/category_model.dart';
import 'package:keychain_shop/services/firestore_service.dart';
import 'package:keychain_shop/services/storage_service.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/widgets/app_button.dart';
import 'package:keychain_shop/widgets/app_text_field.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add category'),
      ),
      body: StreamBuilder<List<CategoryModel>>(
        stream: context.read<FirestoreService>().watchAllCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final categories = snapshot.data ?? [];
          if (categories.isEmpty) {
            return const Center(child: Text('No categories yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final c = categories[index];
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: c.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: c.imageUrl!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: AppColors.surfaceMuted,
                            child: const Icon(Icons.category_outlined),
                          ),
                  ),
                ),
                title: Text(
                  c.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Sort ${c.sortOrder}${c.isActive ? '' : ' · Inactive'}',
                ),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => _openForm(existing: c),
                onLongPress: () => _delete(c),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openForm({CategoryModel? existing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _CategoryForm(existing: existing),
        );
      },
    );
  }

  Future<void> _delete(CategoryModel category) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(category.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<FirestoreService>().deleteCategory(category.id);
  }
}

class _CategoryForm extends StatefulWidget {
  const _CategoryForm({this.existing});

  final CategoryModel? existing;

  @override
  State<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<_CategoryForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _sort;
  late bool _isActive;
  String? _imageUrl;
  Uint8List? _pendingBytes;
  File? _pendingFile;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _sort = TextEditingController(text: '${e?.sortOrder ?? 0}');
    _isActive = e?.isActive ?? true;
    _imageUrl = e?.imageUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _sort.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final xfile = await ImagePicker().pickImage(
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
    setState(() => _saving = true);

    final firestore = context.read<FirestoreService>();
    final storage = context.read<StorageService>();

    try {
      var imageUrl = _imageUrl;
      var id = widget.existing?.id ?? '';

      final draft = CategoryModel(
        id: id,
        name: _name.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        imageUrl: imageUrl,
        sortOrder: int.tryParse(_sort.text.trim()) ?? 0,
        isActive: _isActive,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
      );

      id = await firestore.saveCategory(draft);

      if (_pendingBytes != null || _pendingFile != null) {
        imageUrl = await storage.uploadCategoryImage(
          categoryId: id,
          file: _pendingFile,
          bytes: _pendingBytes,
        );
        await firestore.saveCategory(
          CategoryModel(
            id: id,
            name: draft.name,
            description: draft.description,
            imageUrl: imageUrl,
            sortOrder: draft.sortOrder,
            isActive: draft.isActive,
            createdAt: draft.createdAt,
          ),
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null ? 'Add category' : 'Edit category',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  image: _pendingBytes != null
                      ? DecorationImage(
                          image: MemoryImage(_pendingBytes!),
                          fit: BoxFit.cover,
                        )
                      : (_imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null),
                ),
                child: _pendingBytes == null && _imageUrl == null
                    ? const Center(child: Text('Tap to upload image'))
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _name,
              label: 'Name',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            AppTextField(controller: _description, label: 'Description'),
            const SizedBox(height: 12),
            AppTextField(
              controller: _sort,
              label: 'Sort order',
              keyboardType: TextInputType.number,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            AppButton(
              label: 'Save',
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
