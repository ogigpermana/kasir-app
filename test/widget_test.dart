import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasir_app/main.dart';

void main() {
  testWidgets('App renders login page', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: KasirApp()));
    expect(find.text('Kasir App'), findsWidgets);
    expect(find.text('Login'), findsWidgets);
  });
}
