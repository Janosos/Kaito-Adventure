import 'package:flutter_test/flutter_test.dart';
import 'package:manga_platformer/main.dart';

void main() {
  testWidgets('Manga platformer smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MangaPlatformerApp());
    expect(find.byType(MangaGameScreen), findsOneWidget);
  });
}
