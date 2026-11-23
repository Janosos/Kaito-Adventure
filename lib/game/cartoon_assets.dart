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
    'characters/kaito_ougi.png',

    // Enemies
    'enemies/grunt_walk.png',
    'enemies/grunt_aggro.png',
    'enemies/grunt_attack.png',
    'enemies/drone_fly.png',
    'enemies/drone_attack.png',
    'enemies/oni_idle.png',
    'enemies/oni_shoot.png',
    'enemies/samurai_walk.png',
    'enemies/samurai_attack.png',
    'enemies/samurai_guard.png',
    'enemies/kitsune_float.png',
    'enemies/kitsune_cast.png',
    'enemies/karakuri_march.png',
    'enemies/karakuri_spin.png',

    // Bosses (Chapters 1 to 10)
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
    'bosses/genji_idle.png',
    'bosses/genji_charge.png',
    'bosses/genji_cleave.png',
    'bosses/genji_guard.png',
    'bosses/genji_stun.png',
    'bosses/inari_idle.png',
    'bosses/inari_dash.png',
    'bosses/inari_cast.png',
    'bosses/inari_stun.png',
    'bosses/wadatsumi_idle.png',
    'bosses/wadatsumi_charge.png',
    'bosses/wadatsumi_slam.png',
    'bosses/wadatsumi_stun.png',
    'bosses/raijin_idle.png',
    'bosses/raijin_dash.png',
    'bosses/raijin_cast.png',
    'bosses/raijin_guard.png',
    'bosses/raijin_stun.png',
    'bosses/akuma_idle.png',
    'bosses/akuma_slash.png',
    'bosses/akuma_cast.png',
    'bosses/akuma_guard.png',
    'bosses/akuma_stun.png',

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
    'illustrations/bg_level6_karakuri.png',
    'illustrations/bg_level7_kitsune.png',
    'illustrations/bg_level8_abyss.png',
    'illustrations/bg_level9_raijin.png',
    'illustrations/bg_level10_void.png',
    'illustrations/portrait_kaito.jpg',
    'illustrations/portrait_kurokage.jpg',
    'illustrations/portrait_ryu_kotei.jpg',
    'illustrations/portrait_hebi_hime.png',
    'illustrations/portrait_yuki_oni.png',
    'illustrations/portrait_muzan_kai.png',
    'illustrations/portrait_genji_karakuri.png',
    'illustrations/portrait_inari_kyubi.png',
    'illustrations/portrait_wadatsumi.png',
    'illustrations/portrait_raijin_tei.png',
    'illustrations/portrait_akuma_shin.png',
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
  static const String portraitGenjiKarakuri =
      'assets/images/illustrations/portrait_genji_karakuri.png';
  static const String portraitInariKyubi =
      'assets/images/illustrations/portrait_inari_kyubi.png';
  static const String portraitWadatsumi =
      'assets/images/illustrations/portrait_wadatsumi.png';
  static const String portraitRaijinTei =
      'assets/images/illustrations/portrait_raijin_tei.png';
  static const String portraitAkumaShin =
      'assets/images/illustrations/portrait_akuma_shin.png';

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
  static const String bgLevel6 =
      'assets/images/illustrations/bg_level6_karakuri.png';
  static const String bgLevel7 =
      'assets/images/illustrations/bg_level7_kitsune.png';
  static const String bgLevel8 =
      'assets/images/illustrations/bg_level8_abyss.png';
  static const String bgLevel9 =
      'assets/images/illustrations/bg_level9_raijin.png';
  static const String bgLevel10 =
      'assets/images/illustrations/bg_level10_void.png';

  static final Map<String, SpriteAnimation> _animCache = {};

  static Future<void> preloadAll(Images images) async {
    _animCache.clear();
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
    final key =
        '${identityHashCode(img)}|$path|$frames|${textureSize.x}|${textureSize.y}|$stepTime|$loop';
    final cached = _animCache[key];
    if (cached != null) return cached;
    final anim = SpriteAnimation.fromFrameData(
      img,
      SpriteAnimationData.sequenced(
        amount: frames,
        stepTime: stepTime,
        textureSize: textureSize,
        loop: loop,
      ),
    );
    _animCache[key] = anim;
    return anim;
  }

  static Sprite sprite(Images images, String path) {
    return Sprite(images.fromCache(path));
  }
}
