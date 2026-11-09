import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../tool/sprite_gen/gen_characters.dart';
import '../tool/sprite_gen/gen_bosses.dart';
import '../tool/sprite_gen/gen_skills_env.dart';
import '../tool/sprite_gen/gen_ui_icons.dart';

void main() {
  test('Generate all 2D Cartoon Sprite Sheets and UI Assets', () async {
    await GenCharacters.generateAll();
    await GenBosses.generateAll();
    await GenSkillsEnv.generateAll();
    await GenUiIcons.generateAll();

    // Copy the 5 AI-generated 2D cartoon illustrations into assets/images/illustrations/
    final illustrationsDir = Directory('assets/images/illustrations');
    await illustrationsDir.create(recursive: true);

    const artifactDir =
        r'C:\Users\Soporte\.gemini\antigravity\brain\00a79a64-d009-4c1d-b935-80b3d9f89958';
    final copies = <String, String>{
      '$artifactDir\\bg_level1_rooftops_1794261822245.jpg':
          'assets/images/illustrations/bg_level1_rooftops.jpg',
      '$artifactDir\\bg_level2_citadel_1794261837745.jpg':
          'assets/images/illustrations/bg_level2_citadel.jpg',
      '$artifactDir\\portrait_kaito_1794261852801.jpg':
          'assets/images/illustrations/portrait_kaito.jpg',
      '$artifactDir\\portrait_kurokage_1794261869195.jpg':
          'assets/images/illustrations/portrait_kurokage.jpg',
      '$artifactDir\\portrait_ryu_kotei_1794261891469.jpg':
          'assets/images/illustrations/portrait_ryu_kotei.jpg',
    };

    for (final entry in copies.entries) {
      final src = File(entry.key);
      if (await src.exists()) {
        await src.copy(entry.value);
      }
    }
  });
}

