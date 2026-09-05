import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/models/user_model.dart';
import 'package:keychain_shop/services/firestore_service.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/utils/formatters.dart';

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search by name or email…',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: context.read<FirestoreService>().watchCustomers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              var customers = snapshot.data ?? [];
              if (_query.isNotEmpty) {
                customers = customers
                    .where(
                      (u) =>
                          u.name.toLowerCase().contains(_query) ||
                          u.email.toLowerCase().contains(_query) ||
                          (u.phone ?? '').contains(_query),
                    )
                    .toList();
              }

              if (customers.isEmpty) {
                return const Center(child: Text('No customers found.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: customers.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final user = customers[index];
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColors.primaryLight.withValues(alpha: 0.4),
                      child: Text(
                        user.name.isNotEmpty
                            ? user.name.characters.first.toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    title: Text(
                      user.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${user.email}\nJoined ${Formatters.date(user.createdAt)}'
                      '${user.isActive ? '' : ' · Deactivated'}',
                    ),
                    isThreeLine: true,
                    trailing: Switch(
                      value: user.isActive,
                      activeThumbColor: AppColors.primary,
                      onChanged: (active) async {
                        try {
                          await context
                              .read<FirestoreService>()
                              .setUserActive(user.id, active);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Update failed: $e')),
                          );
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
