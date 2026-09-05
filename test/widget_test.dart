import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychain_shop/constants/app_constants.dart';
import 'package:keychain_shop/theme/app_theme.dart';

void main() {
  testWidgets('app theme renders brand name', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Center(child: Text(AppConstants.appName)),
        ),
      ),
    );

    expect(find.text('Keychain Shop'), findsOneWidget);
  });
}
