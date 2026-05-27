import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:recipe_cost/main.dart';

void main() {
  testWidgets('shows the cake ingredient setup screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RecipeCostApp());

    expect(find.text('Bảng nguyên liệu bánh gato'), findsOneWidget);
    expect(find.text('Nguyên liệu'), findsOneWidget);
    expect(find.text('Đơn vị'), findsOneWidget);
    expect(find.text('Đơn giá'), findsWidgets);
    expect(find.text('Thành tiền'), findsOneWidget);
    expect(find.text('Định lượng'), findsOneWidget);
    expect(find.text('Trứng gà'), findsOneWidget);
    expect(find.text('Đã nhập chuẩn 16cm / 350g.'), findsOneWidget);
    expect(find.text('14.768 đ'), findsOneWidget);
    expect(find.text('45.45'), findsWidgets);
    expect(find.byKey(const Key('mold-size-field')), findsOneWidget);
    expect(find.text('16'), findsOneWidget);
  });

  testWidgets('changes the selected cake count', (WidgetTester tester) async {
    await tester.pumpWidget(const RecipeCostApp());

    expect(find.text('1 cái'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Tăng số lượng'));
    await tester.tap(find.byTooltip('Tăng số lượng'));
    await tester.pump();

    expect(find.text('2 cái'), findsOneWidget);
  });

  testWidgets('calculates ingredient line totals from unit prices', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RecipeCostApp());

    await tester.ensureVisible(find.byKey(const Key('unit-price-0')));
    await tester.enterText(find.byKey(const Key('unit-price-0')), '10');
    await tester.pump();

    expect(find.text('150 đ'), findsWidgets);

    await tester.ensureVisible(find.byTooltip('Tăng số lượng'));
    await tester.tap(find.byTooltip('Tăng số lượng'));
    await tester.pump();

    expect(find.text('300 đ'), findsWidgets);
  });

  testWidgets('scales the recipe by mold volume formula', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RecipeCostApp());

    await tester.enterText(find.byKey(const Key('mold-size-field')), '30');
    await tester.pump();

    expect(find.text('53.0'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('unit-price-0')));
    await tester.enterText(find.byKey(const Key('unit-price-0')), '10');
    await tester.pump();

    expect(find.text('530 đ'), findsWidgets);
  });
}
