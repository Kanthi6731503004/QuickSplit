import 'package:flutter_test/flutter_test.dart';
import 'package:quicksplit/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const QuickSplitApp());
    expect(find.text('QuickSplit'), findsOneWidget);
  });
}
