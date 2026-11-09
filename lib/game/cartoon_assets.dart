import 'package:flame/cache.dart';
import 'package:flame/components.dart';

class CartoonAssets {
  // Flame Images relative paths (under assets/images/)
  static const List<String> allFlameImages = [
    // Characters (Kaito)
    'characters/kaito_idle.png',
    'characters/kaito_run.png',
    'characters/kaito_jump.png',
    'characters/kaito_fall.png',
    'characters/kaito_dash.png',
    'characters/kaito_attack1.png',
    'characters/kaito_attack2.png',
    'characters/kaito_attack3.png',
    'characters/kaito_hurt.png',

    // Enemies
    'enemies/grunt_walk.png',
    'enemies/grunt_aggro.png',
    'enemies/grunt_attack.png',
    'enemies/drone_fly.png',
    'enemies/drone_attack.png',

    // Bosses
    'bosses/kurokage_idle.png',
    'bosses/kurokage_charge.png',
    'bosses/kurokage_cleave.png',
    'bosses/kurokage_guard.png',
    'bosses/kurokage_stun.png',
    'bosses/ryu_idle.png',
    'bosses/ryu_dash.png',
    'bosses/ryu_stomp.png',
    'bosses/ryu_cast.png',
    'bosses/ryu_stun.png',

    // Skills, Projectiles & VFX
    'skills/slash_arc_yellow.png',
    'skills/slash_arc_cyan.png',
    'skills/slash_arc_red.png',
    'skills/slash_arc_purple.png',
    'skills/proj_kunai.png',
    'skills/proj_dark_wave.png',
    'skills/proj_flame_pillar.png',
    'skills/proj_energy_orb.png',
    'skills/proj_drone_needle.png',
    'skills/vfx_dust_puff.png',

    // Environment, Collectibles, Traps & Platforms
    'environment/item_scroll.png',
    'environment/item_ramen.png',
    'environment/prop_torii.png',
    'environment/trap_spring.png',
    'environment/trap_saw.png',
    'environment/trap_spikes.png',
    'environment/platform_rooftop.png',
    'environment/platform_citadel.png',
    'environment/platform_moving.png',
    'environment/platform_crumbling.png',

    // Illustrations / Backgrounds
    'illustrations/bg_level1_rooftops.jpg',
    'illustrations/bg_level2_citadel.jpg',
    'illustrations/portrait_kaito.jpg',
    'illustrations/portrait_kurokage.jpg',
    'illustrations/portrait_ryu_kotei.jpg',
  ];

  // Flutter Widget Asset Paths
  static const String uiHeartFull = 'assets/images/ui/icon_heart_full.png';
  static const String uiHeartEmpty = 'assets/images/ui/icon_heart_empty.png';
  static const String uiSpiritOrb = 'assets/images/ui/icon_spirit_orb.png';
  static const String uiScoreScroll = 'assets/images/ui/icon_score_scroll.png';
  static const String uiPause = 'assets/images/ui/icon_pause.png';
  static const String uiDpadLeft = 'assets/images/ui/icon_dpad_left.png';
  static const String uiDpadRight = 'assets/images/ui/icon_dpad_right.png';
  static const String uiSkillSlash = 'assets/images/ui/icon_skill_slash.png';
  static const String uiSkillJump = 'assets/images/ui/icon_skill_jump.png';
  static const String uiSkillDash = 'assets/images/ui/icon_skill_dash.png';
  static const String uiSkillKunai = 'assets/images/ui/icon_skill_kunai.png';
  static const String uiSkillOugi = 'assets/images/ui/icon_skill_ougi.png';
  static const String uiBadgeSRank = 'assets/images/ui/badge_s_rank.png';

  static const String portraitKaito =
      'assets/images/illustrations/portrait_kaito.jpg';
  static const String portraitKurokage =
      'assets/images/illustrations/portrait_kurokage.jpg';
  static const String portraitRyuKotei =
      'assets/images/illustrations/portrait_ryu_kotei.jpg';
  static const String bgLevel1 =
      'assets/images/illustrations/bg_level1_rooftops.jpg';
  static const String bgLevel2 =
      'assets/images/illustrations/bg_level2_citadel.jpg';

  static Future<void> preloadAll(Images images) async {
    await images.loadAll(allFlameImages);
  }

  static SpriteAnimation animation(
    Images images,
    String path, {
    required int frames,
    required Vector2 textureSize,
    double stepTime = 0.09,
    bool loop = true,
  }) {
    final img = images.fromCache(path);
    return SpriteAnimation.fromFrameData(
      img,
      SpriteAnimationData.sequenced(
        amount: frames,
        stepTime: stepTime,
        textureSize: textureSize,
        loop: loop,
      ),
    );
  }

  static Sprite sprite(Images images, String path) {
    return Sprite(images.fromCache(path));
  }
}

