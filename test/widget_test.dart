import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_pelelangan/main.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('E-Pelelangan app main flows', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const EPelelanganApp(),
      ),
    );

    // Verify main page shows "Menu Utama"
    expect(find.text('Menu Utama'), findsOneWidget);

    // Tap on the "Barang Lelang" carousel item
    await tester.tap(find.text('Barang Lelang'));
    await tester.pumpAndSettle();

    // Verify form page is displayed
    expect(find.text('Form Barang Lelang'), findsOneWidget);

    // Fill form fields
    await tester.enterText(find.byType(TextFormField).at(0), 'Laptop');
    await tester.enterText(find.byType(TextFormField).at(1), '10000000');
    await tester.enterText(find.byType(TextFormField).at(2), '2');
    await tester.enterText(find.byType(TextFormField).at(3), '8000000');

    // Submit the form
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    // Back to home page, tap on Home menu
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    // Verify new item appears in the list
    expect(find.text('Laptop'), findsOneWidget);

    // Tap "Tandai Terjual" button
    await tester.tap(find.text('Tandai Terjual'));
    await tester.pumpAndSettle();

    // Confirm dialog shown
    expect(find.textContaining('Tandai'), findsOneWidget);

    // Confirm marking sold
    await tester.tap(find.text('Ya'));
    await tester.pumpAndSettle();

    // Item should disappear from Home (barang dilelang)
    expect(find.text('Laptop'), findsNothing);

    // Go back to main page
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Tap on Histori Lelang menu
    await tester.tap(find.text('Histori Lelang'));
    await tester.pumpAndSettle();

    // Verify item appears in histori
    expect(find.text('Laptop'), findsOneWidget);

    // Go to Profil User menu and verify name
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil User'));
    await tester.pumpAndSettle();
    expect(find.text('Muhamad Rakha'), findsOneWidget);
  });
}
