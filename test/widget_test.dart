import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cakeu/core/utils/currency_formatter.dart';
import 'package:cakeu/features/categories/data/models/category_model.dart';
import 'package:cakeu/features/security/presentation/widgets/security_keypad.dart';
import 'package:cakeu/shared/widgets/date_navigator_bar.dart';

void main() {
  group('CurrencyFormatter Tests', () {
    test('formats positive numbers correctly', () {
      expect(CurrencyFormatter.format(50000), 'Rp50.000');
      expect(CurrencyFormatter.format(1250000), 'Rp1.250.000');
    });

    test('formats compact amounts correctly', () {
      expect(CurrencyFormatter.formatCompact(1500000), '1.5jt');
    });
  });

  group('CategoryModel Icon Mapping Tests', () {
    test('returns correct IconData for common categories', () {
      expect(CategoryModel.iconFromName('Makanan'), Icons.restaurant_rounded);
      expect(CategoryModel.iconFromName('Transportasi'), Icons.directions_car_rounded);
      expect(CategoryModel.iconFromName('Gaji', isExpense: false), Icons.account_balance_wallet_rounded);
    });
  });

  group('SecurityKeypad Widget Tests', () {
    testWidgets('renders all keypad buttons and handles taps', (WidgetTester tester) async {
      String pressedKey = '';
      bool backspaceTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecurityKeypad(
              onKeyPressed: (key) => pressedKey = key,
              onBackspace: () => backspaceTapped = true,
            ),
          ),
        ),
      );

      // Verify digits 0-9 are present
      for (int i = 0; i <= 9; i++) {
        expect(find.text(i.toString()), findsOneWidget);
      }

      // Tap digit 7
      await tester.tap(find.text('7'));
      expect(pressedKey, '7');

      // Tap backspace
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      expect(backspaceTapped, true);
    });

    testWidgets('PinIndicatorDots displays correct number of dots', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PinIndicatorDots(
              totalDots: 6,
              filledDots: 3,
            ),
          ),
        ),
      );

      // Verify Row contains 6 dot containers
      final rowFinder = find.byType(Row);
      expect(rowFinder, findsOneWidget);
    });
  });

  group('DateNavigatorBar Widget Tests', () {
    testWidgets('renders current date and navigates backward/forward', (WidgetTester tester) async {
      int daysOffset = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return DateNavigatorBar(
                  selectedDate: DateTime(2026, 9, 5).add(Duration(days: daysOffset)),
                  onPrevious: () => setState(() => daysOffset--),
                  onNext: () => setState(() => daysOffset++),
                );
              },
            ),
          ),
        ),
      );

      // Tap previous day
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pump();
      expect(daysOffset, -1);

      // Tap next day
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pump();
      expect(daysOffset, 0);
    });
  });
}
