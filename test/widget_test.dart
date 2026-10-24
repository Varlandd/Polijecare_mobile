import 'package:flutter_test/flutter_test.dart';
import 'package:polijecare_mobile/main.dart';

void main() {
  testWidgets('Landing page renders hero title', (WidgetTester tester) async {
    await tester.pumpWidget(const PolijeCareApp());
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('Aman Bicara, Aman Melapor'), findsOneWidget);
    expect(find.text('Satgas PPKPT Politeknik Negeri Jember'), findsOneWidget);
  });
}
