import 'package:flutter_test/flutter_test.dart';
import 'package:yosep_077_utp/main.dart';

void main() {
  testWidgets('SiagaBumiApp smoke test', (WidgetTester tester) async {
    // Memastikan widget tree SiagaBumiApp terinisialisasi
    await tester.pumpWidget(const SiagaBumiApp());
    expect(find.byType(SiagaBumiApp), findsOneWidget);
  });
}
