import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_platformer/game/components/enemies/enemy_grunt.dart';
import 'package:manga_platformer/game/components/player.dart';
import 'package:manga_platformer/game/manga_game.dart';
import 'package:manga_platformer/main.dart';

void main() {
  testWidgets('Manga platformer smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MangaPlatformerApp());
    expect(find.byType(MangaGameScreen), findsOneWidget);
  });

  test(
      'All 5 distinct progressive levels load, Kunai has 5s cooldown, Slash deals damage + knockback, and Boss spawns at final stage',
      () async {
    final game = MangaGame();
    game.onGameResize(Vector2(960, 540));
    await game.onLoad();
    // ignore: invalid_use_of_internal_member
    game.setLoaded();
    // ignore: invalid_use_of_internal_member
    game.setMounted();
    game.update(0);
    await game.ready();

    double previousLevelWidth = 0;

    for (int lvl = 1; lvl <= 5; lvl++) {
      await game.loadLevel(lvl);
      // Pump world lifecycle so level & children mount inside game.world
      game.update(0);
      await game.ready();
      game.update(0);
      await game.ready();
      game.update(0.05);

      expect(game.currentLevelIndex, lvl);
      // Verify each level is progressively longer than the last
      expect(game.currentLevelWidth, greaterThan(previousLevelWidth));
      previousLevelWidth = game.currentLevelWidth;

      // Boss is NOT active until player reaches the final stage!
      expect(game.activeBoss, isNull);

      // Verify 5-second Kunai Cooldown anti-spam
      game.player.kunaiCooldown = 0;
      game.player.performThrowKunai();
      expect(
        game.player.kunaiCooldown,
        closeTo(MangaPlayer.maxKunaiCooldown, 0.001),
      );
      expect(MangaPlayer.maxKunaiCooldown, equals(5.0));

      final grunts = game.queryWorld<EnemyGrunt>().toList();
      expect(grunts, isNotEmpty);

      // Move player right next to the first grunt and perform Slash
      final firstGrunt = grunts.first;
      final initialHp = firstGrunt.hp;
      final initialX = firstGrunt.position.x;

      game.player.position =
          Vector2(firstGrunt.position.x - 28, firstGrunt.position.y);
      game.player.facingDirection = 1;
      game.player.attackCooldown = 0;
      game.player.performAttack();

      expect(firstGrunt.hp, lessThan(initialHp));
      expect(firstGrunt.position.x, greaterThan(initialX));

      // Now advance player to this level's final stage Boss Arena trigger
      game.player.position = Vector2(game.currentBossGateX + 20, 460);
      game.update(0.05);
      await game.ready();
      game.update(0.05);
      await game.ready();
      game.update(0.05);
      await game.ready();

      expect(game.isBossArenaLocked, isTrue);
      expect(game.activeBoss, isNotNull);
    }
  });
}
