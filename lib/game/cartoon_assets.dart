import 'package:flame/cache.dart';
import 'package:flame/components.dart';

class CartoonAssets {
  // Flame Images relative paths (under assets/images/)
  static const String kaitoVictory = 'assets/images/characters/kaito_victory.png';
  static const String kaitoDeath = 'assets/images/characters/kaito_death.png';

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
    'characters/kaito_death.png',
    'characters/kaito_victory.png',

    // Enemies
    'enemies/grunt_walk.png',
    'enemies/grunt_aggro.png',
    'enemies/grunt_attack.png',
    'enemies/drone_fly.png',
    'enemies/drone_attack.png',
    'enemies/oni_idle.png',
    'enemies/oni_shoot.png',

    // Bosses (Chapters 1 to 5)
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
    'bosses/hebi_idle.png',
    'bosses/hebi_dash.png',
    'bosses/hebi_cast.png',
    'bosses/hebi_stun.png',
    'bosses/yuki_idle.png',
    'bosses/yuki_charge.png',
    'bosses/yuki_slam.png',
    'bosses/yuki_stun.png',
    'bosses/muzan_idle.png',
    'bosses/muzan_slash.png',
    'bosses/muzan_cast.png',
    'bosses/muzan_guard.png',
    'bosses/muzan_stun.png',

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

    // Environment, Collectibles, Interactive Props, Traps & Platforms
    'environment/item_scroll.png',
    'environment/item_ramen.png',
    'environment/prop_torii.png',
    'environment/prop_checkpoint.png',
    'environment/prop_crate.png',
    'environment/prop_bounce_drum.png',
    'environment/prop_wind_vent.png',
    'environment/prop_switch_orb.png',
    'environment/prop_gate_barrier.png',
    'environment/trap_spring.png',
    'environment/trap_saw.png',
    'environment/trap_spikes.png',
    'environment/platform_rooftop.png',
    'environment/platform_citadel.png',
    'environment/platform_bamboo.png',
    'environment/platform_ice.png',
    'environment/platform_sanctum.png',
    'environment/platform_moving.png',
    'environment/platform_crumbling.png',

    // Illustrations / Backgrounds
    'illustrations/bg_level1_rooftops.jpg',
    'illustrations/bg_level2_citadel.jpg',
    'illustrations/bg_level3_bamboo.png',
    'illustrations/bg_level4_peaks.png',
    'illustrations/bg_level5_sanctum.png',
    'illustrations/portrait_kaito.jpg',
    'illustrations/portrait_kurokage.jpg',
    'illustrations/portrait_ryu_kotei.jpg',
    'illustrations/portrait_hebi_hime.png',
    'illustrations/portrait_yuki_oni.png',
    'illustrations/portrait_muzan_kai.png',
  ];

  // Flutter Widget Asset Paths
  static const String uiAppIcon = 'assets/images/ui/app_icon.png';
  static const String uiLogo = 'assets/images/ui/logo_kaito_adventure.png';
  static const String uiBtnPlay = 'assets/images/ui/btn_play.png';
  static const String uiBtnChapters = 'assets/images/ui/btn_chapters.png';
  static const String uiBtnIntro = 'assets/images/ui/btn_intro.png';
  static const String uiBtnControls = 'assets/images/ui/btn_controls.png';
  static const String uiBtnSkip = 'assets/images/ui/btn_skip.png';
  static const String uiBtnHome = 'assets/images/ui/btn_home.png';
  static const String uiBtnSettings = 'assets/images/ui/btn_settings.png';
  static const String uiJanososAvatar = 'assets/images/ui/janosos_avatar.jpg';
  static const String uiKaitoHead = 'assets/images/ui/icon_kaito_head.png';
  static const String uiBossSkull = 'assets/images/ui/icon_boss_skull.png';

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

  static const String bgMainMenu =
      'assets/images/illustrations/bg_main_menu.png';
  static const String introPanel1 =
      'assets/images/illustrations/intro_panel1_shrine.png';
  static const String introPanel2 =
      'assets/images/illustrations/intro_panel2_warlords.png';
  static const String introPanel3 =
      'assets/images/illustrations/intro_panel3_oath.png';

  static const String epiloguePanel1 =
      'assets/images/illustrations/epilogue_panel1_shatter.png';
  static const String epiloguePanel2 =
      'assets/images/illustrations/epilogue_panel2_rebirth.png';
  static const String epiloguePanel3 =
      'assets/images/illustrations/epilogue_panel3_legend.png';

  static const String portraitKaito =
      'assets/images/illustrations/portrait_kaito.jpg';
  static const String portraitKurokage =
      'assets/images/illustrations/portrait_kurokage.jpg';
  static const String portraitRyuKotei =
      'assets/images/illustrations/portrait_ryu_kotei.jpg';
  static const String portraitHebiHime =
      'assets/images/illustrations/portrait_hebi_hime.png';
  static const String portraitYukiOni =
      'assets/images/illustrations/portrait_yuki_oni.png';
  static const String portraitMuzanKai =
      'assets/images/illustrations/portrait_muzan_kai.png';

  static const String bgLevel1 =
      'assets/images/illustrations/bg_level1_rooftops.jpg';
  static const String bgLevel2 =
      'assets/images/illustrations/bg_level2_citadel.jpg';
  static const String bgLevel3 =
      'assets/images/illustrations/bg_level3_bamboo.png';
  static const String bgLevel4 =
      'assets/images/illustrations/bg_level4_peaks.png';
  static const String bgLevel5 =
      'assets/images/illustrations/bg_level5_sanctum.png';

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
