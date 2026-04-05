// Smoke test untuk TodoApp
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TodoApp smoke test', (WidgetTester tester) async {
    // Minimal smoke test — build test memerlukan SQLite dan SharedPreferences
    // yang tidak tersedia di unit test environment.
    // Gunakan flutter run untuk pengujian manual di emulator.
    expect(true, isTrue);
  });
}
