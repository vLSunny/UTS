import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../lib/pages.dart';
import '../lib/main.dart';

void main() {
  group('MapPage Tests', () {
    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState()),
          ChangeNotifierProvider(create: (_) => RoleProvider()),
          ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ],
        child: const MaterialApp(
          home: MapPage(),
        ),
      );
    }

    testWidgets('MapPage renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Verify basic UI elements
      expect(find.text('Peta'), findsOneWidget);
      expect(find.byIcon(Icons.church), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('MapPage shows church icon button',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find church icon button
      final churchButton = find.byIcon(Icons.church);
      expect(churchButton, findsOneWidget);

      // Verify tooltip
      expect(find.byTooltip('Cari Tempat Ibadah Terdekat'), findsOneWidget);
    });

    testWidgets('MapPage shows location coordinates widget',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Verify location widget exists
      expect(find.text('Lokasi Anda:'), findsOneWidget);
      expect(find.textContaining('Lat:'), findsOneWidget);
      expect(find.textContaining('Lng:'), findsOneWidget);
    });

    testWidgets('MapPage has radius slider', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find slider
      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);

      // Verify slider properties
      final sliderWidget = tester.widget<Slider>(slider);
      expect(sliderWidget.min, equals(1000));
      expect(sliderWidget.max, equals(20000));
      expect(sliderWidget.divisions, equals(19));
    });

    testWidgets('MapPage shows map style menu', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find map style button
      final mapButton = find.byIcon(Icons.map);
      expect(mapButton, findsOneWidget);

      // Tap to open menu
      await tester.tap(mapButton);
      await tester.pumpAndSettle();

      // Verify menu items
      expect(find.text('OpenStreetMap'), findsOneWidget);
      expect(find.text('OpenTopoMap'), findsOneWidget);
      expect(find.text('Stamen Toner'), findsOneWidget);
    });

    testWidgets('MapPage shows device info dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find info button
      final infoButton = find.byIcon(Icons.info_outline);
      expect(infoButton, findsOneWidget);

      // Tap to open dialog
      await tester.tap(infoButton);
      await tester.pumpAndSettle();

      // Verify dialog content
      expect(find.text('Device Info'), findsOneWidget);
      expect(find.textContaining('Markers:'), findsOneWidget);
      expect(find.textContaining('Current Position:'), findsOneWidget);
      expect(find.textContaining('Radius:'), findsOneWidget);
    });

    testWidgets('MapPage has navigation FAB', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find floating action button
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      // Verify FAB icon
      expect(find.byIcon(Icons.navigation), findsOneWidget);
    });

    testWidgets('MapPage shows error when searching without location',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Tap search button without location
      await tester.tap(find.byIcon(Icons.church));
      await tester.pump();

      // Wait for snackbar
      await tester.pump(const Duration(milliseconds: 100));

      // Verify snackbar appears
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Lokasi saat ini tidak tersedia'), findsOneWidget);
    });

    testWidgets('MapPage slider updates value', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find slider
      final slider = find.byType(Slider);

      // Get initial value
      final initialSlider = tester.widget<Slider>(slider);
      final initialValue = initialSlider.value;

      // Drag slider to change value
      await tester.drag(slider, const Offset(50.0, 0.0));
      await tester.pumpAndSettle();

      // Verify value changed
      final updatedSlider = tester.widget<Slider>(slider);
      expect(updatedSlider.value, isNot(equals(initialValue)));
    });
  });
}
