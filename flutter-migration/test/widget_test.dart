import 'package:flutter_test/flutter_test.dart';

import 'package:verdemeta/main.dart';

void main() {
  testWidgets('Renderiza la app principal', (WidgetTester tester) async {
    await tester.pumpWidget(VerdeMeta());
    await tester.pump();

    expect(find.byType(VerdeMeta), findsOneWidget);
  });
}
