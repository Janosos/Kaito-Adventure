import 'dart:convert';
import 'package:flutter/material.dart';
import 'local_storage.dart';

enum AppLanguage {
  en, // English (Default)
  es, // Español
  ja, // 日本語 (Japanese)
}

class HudControlsConfig {
  final double buttonScale;
  final double buttonOpacity;
  final Map<String, Offset> buttonPositions;

  static const Map<String, Offset> defaultPositions = {
    'slash': Offset(0.91, 0.58),
    'jump': Offset(0.91, 0.83),
    'kunai': Offset(0.79, 0.58),
    'dash': Offset(0.79, 0.83),
    'ougi': Offset(0.67, 0.83),
  };

  const HudControlsConfig({
    this.buttonScale = 1.40,
    this.buttonOpacity = 0.85,
    this.buttonPositions = defaultPositions,
  });

  Offset posFor(String id) {
    return buttonPositions[id] ??
        defaultPositions[id] ??
        const Offset(0.85, 0.75);
  }

  HudControlsConfig copyWith({
    double? buttonScale,
    double? buttonOpacity,
    Map<String, Offset>? buttonPositions,
  }) {
    return HudControlsConfig(
      buttonScale: (buttonScale ?? this.buttonScale).clamp(0.60, 1.80),
      buttonOpacity: (buttonOpacity ?? this.buttonOpacity).clamp(0.25, 1.00),
      buttonPositions: buttonPositions ?? Map<String, Offset>.from(this.buttonPositions),
    );
  }

  Map<String, dynamic> toJson() {
    final posMap = <String, dynamic>{};
    for (final entry in buttonPositions.entries) {
      posMap[entry.key] = {'x': entry.value.dx, 'y': entry.value.dy};
    }
    return {
      'buttonScale': buttonScale,
      'buttonOpacity': buttonOpacity,
      'buttonPositions': posMap,
    };
  }

  factory HudControlsConfig.fromJson(Map<String, dynamic> json) {
    final rawScale = (json['buttonScale'] as num?)?.toDouble() ?? 1.40;
    final rawOpacity = (json['buttonOpacity'] as num?)?.toDouble() ?? 0.85;
    final positions = Map<String, Offset>.from(defaultPositions);
    final rawPos = json['buttonPositions'];
    if (rawPos is Map) {
      for (final key in defaultPositions.keys) {
        final item = rawPos[key];
        if (item is Map) {
          final x = (item['x'] as num?)?.toDouble();
          final y = (item['y'] as num?)?.toDouble();
          if (x != null && y != null) {
            positions[key] = Offset(
              x.clamp(0.06, 0.94),
              y.clamp(0.12, 0.92),
            );
          }
        }
      }
    }
    return HudControlsConfig(
      buttonScale: rawScale.clamp(0.60, 1.80),
      buttonOpacity: rawOpacity.clamp(0.25, 1.00),
      buttonPositions: positions,
    );
  }
}

class AppLocalizations {
  /// Global reactive language notifier — always defaults to English (`AppLanguage.en`)
  static final ValueNotifier<AppLanguage> languageNotifier =
      ValueNotifier<AppLanguage>(AppLanguage.en);

  /// Global reactive setting for virtual on-screen controls
  static final ValueNotifier<bool> showVirtualControls =
      ValueNotifier<bool>(true);

  /// Global reactive setting for button vibration / haptic feedback
  static final ValueNotifier<bool> hapticsEnabled =
      ValueNotifier<bool>(true);

  /// Global reactive setting for music (BGM)
  static final ValueNotifier<bool> bgmEnabled =
      ValueNotifier<bool>(true);

  /// Global reactive setting for sound effects (SFX)
  static final ValueNotifier<bool> sfxEnabled =
      ValueNotifier<bool>(true);

  /// Global reactive setting for BGM volume
  static final ValueNotifier<double> bgmVolume =
      ValueNotifier<double>(0.75);

  /// Global reactive setting for SFX volume
  static final ValueNotifier<double> sfxVolume =
      ValueNotifier<double>(0.85);

  /// Global reactive HUD button customization (position, size, transparency)
  static final ValueNotifier<HudControlsConfig> hudConfig =
      ValueNotifier<HudControlsConfig>(const HudControlsConfig());

  /// Whether the interactive HUD button position drag editor is currently active
  static final ValueNotifier<bool> isEditingHudLayout =
      ValueNotifier<bool>(false);

  static AppLanguage get current => languageNotifier.value;

  static void loadSettings() {
    try {
      final raw = LocalStorage.readSettingsJson();
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;

      final langStr = decoded['language'] as String?;
      if (langStr == 'es') {
        languageNotifier.value = AppLanguage.es;
      } else if (langStr == 'ja') {
        languageNotifier.value = AppLanguage.ja;
      } else {
        languageNotifier.value = AppLanguage.en;
      }

      final showTouch = decoded['showVirtualControls'] as bool?;
      if (showTouch != null) {
        showVirtualControls.value = showTouch;
      }

      final haptics = decoded['hapticsEnabled'] as bool?;
      if (haptics != null) {
        hapticsEnabled.value = haptics;
      }

      final bgm = decoded['bgmEnabled'] as bool?;
      if (bgm != null) {
        bgmEnabled.value = bgm;
      }

      final sfx = decoded['sfxEnabled'] as bool?;
      if (sfx != null) {
        sfxEnabled.value = sfx;
      }

      final bVol = (decoded['bgmVolume'] as num?)?.toDouble();
      if (bVol != null) {
        bgmVolume.value = bVol.clamp(0.0, 1.0);
      }

      final sVol = (decoded['sfxVolume'] as num?)?.toDouble();
      if (sVol != null) {
        sfxVolume.value = sVol.clamp(0.0, 1.0);
      }

      final version = (decoded['settingsVersion'] as num?)?.toInt() ?? 1;
      final hudMap = decoded['hudConfig'];
      if (hudMap is Map<String, dynamic>) {
        var loaded = HudControlsConfig.fromJson(hudMap);
        if (version < 2) {
          // Upgrade older v1 default scale (1.0) to new 1.40 (140%) Android default
          loaded = loaded.copyWith(
            buttonScale: loaded.buttonScale < 1.40 ? 1.40 : loaded.buttonScale,
            buttonPositions: HudControlsConfig.defaultPositions,
          );
          hudConfig.value = loaded;
          saveSettings();
        } else {
          hudConfig.value = loaded;
        }
      }
    } catch (_) {}
  }

  static void saveSettings() {
    try {
      final payload = jsonEncode({
        'settingsVersion': 2,
        'language': languageNotifier.value.name,
        'showVirtualControls': showVirtualControls.value,
        'hapticsEnabled': hapticsEnabled.value,
        'bgmEnabled': bgmEnabled.value,
        'sfxEnabled': sfxEnabled.value,
        'bgmVolume': bgmVolume.value,
        'sfxVolume': sfxVolume.value,
        'hudConfig': hudConfig.value.toJson(),
      });
      LocalStorage.writeSettingsJson(payload);
    } catch (_) {}
  }

  static void setHapticsEnabled(bool enabled) {
    hapticsEnabled.value = enabled;
    saveSettings();
  }

  static void setBgmEnabled(bool enabled) {
    bgmEnabled.value = enabled;
    saveSettings();
  }

  static void setSfxEnabled(bool enabled) {
    sfxEnabled.value = enabled;
    saveSettings();
  }

  static void updateBgmVolume(double vol) {
    bgmVolume.value = vol.clamp(0.0, 1.0);
    saveSettings();
  }

  static void updateSfxVolume(double vol) {
    sfxVolume.value = vol.clamp(0.0, 1.0);
    saveSettings();
  }

  static void setLanguage(AppLanguage lang) {
    languageNotifier.value = lang;
    saveSettings();
  }

  static void updateButtonScale(double scale) {
    hudConfig.value = hudConfig.value.copyWith(buttonScale: scale);
    saveSettings();
  }

  static void updateButtonOpacity(double opacity) {
    hudConfig.value = hudConfig.value.copyWith(buttonOpacity: opacity);
    saveSettings();
  }

  static void updateButtonPosition(String id, Offset normalizedPos) {
    final nextMap =
        Map<String, Offset>.from(hudConfig.value.buttonPositions);
    nextMap[id] = Offset(
      normalizedPos.dx.clamp(0.06, 0.94),
      normalizedPos.dy.clamp(0.14, 0.92),
    );
    hudConfig.value = hudConfig.value.copyWith(buttonPositions: nextMap);
    saveSettings();
  }

  static void resetHudLayout() {
    hudConfig.value = const HudControlsConfig();
    saveSettings();
  }

  static String tr(String key) {
    final lang = languageNotifier.value;
    final map = _translations[lang] ?? _translations[AppLanguage.en]!;
    return map[key] ?? _translations[AppLanguage.en]![key] ?? key;
  }

  static String chapterTitle(int chapter) => tr('ch${chapter}_title');
  static String chapterSubtitle(int chapter) => tr('ch${chapter}_sub');
  static String chapterBoss(int chapter) => tr('ch${chapter}_boss');
  static String chapterTip(int chapter) => tr('ch${chapter}_tip');

  static const Map<AppLanguage, Map<String, String>> _translations = {
    AppLanguage.en: {
      // Splash & Title
      'game_title_top': 'KAITO',
      'game_title_bottom': 'ADVENTURE',
      'game_subtitle': '★ SHINOBI OF THE CELESTIAL INK ★',
      'developed_by': 'DEVELOPED BY JANOSOS',
      'tap_to_continue': 'TAP ANYWHERE TO CONTINUE',

      // Main Menu
      'edition_badge': '2D CARTOON EDITION • 5 CHAPTERS',
      'hero_card_sub': '5 PROGRESSIVE STAGES • 5 WARLORD BOSSES',
      'btn_start_adventure': 'START ADVENTURE',
      'btn_multiplayer': 'MULTIPLAYER (LOCAL WIFI)',
      'btn_select_chapter': 'SELECT CHAPTER (1 - 5)',
      'btn_story_intro': 'STORY INTRO',
      'btn_how_to_play': 'HOW TO PLAY',
      'btn_settings': 'SETTINGS',
      'btn_install_app': 'INSTALL APP',

      // PWA / App Installation Modal
      'install_title': 'INSTALL KAITO ADVENTURE',
      'install_sub': 'PLAY IN FULLSCREEN LANDSCAPE & OFFLINE LIKE A NATIVE APP!',
      'install_android_tab': 'ANDROID / CHROME',
      'install_ios_tab': 'IPHONE / IPAD (iOS)',
      'install_btn_now': 'INSTALL NOW',
      'install_already_installed': '✓ App is already installed and ready to play!',
      'install_android_guide':
          'Tap "INSTALL NOW", or open browser menu (⋮) and tap "Install app" / "Add to Home screen" to play with zero browser bars in full landscape.',
      'install_ios_step1':
          '1. In Safari, tap the Share button [ ⎋ ] on the bottom navigation bar.',
      'install_ios_step2':
          '2. Scroll down and tap "Add to Home Screen" [ ⊞ ].',
      'install_ios_step3':
          '3. Tap "Add". Open from Home Screen to play in forced landscape fullscreen without URL bars!',
      'btn_fullscreen_landscape': 'FULLSCREEN & ROTATE',

      // Settings Modal / Screen
      'settings_title': 'GAME SETTINGS',
      'settings_subtitle': 'LANGUAGE & CONTROLS CONFIGURATION',
      'language_label': 'LANGUAGE / IDIOMA / 言語',
      'lang_en': 'ENGLISH (DEFAULT)',
      'lang_es': 'ESPAÑOL (SPANISH)',
      'lang_ja': '日本語 (JAPANESE)',
      'virtual_controls_label': 'ON-SCREEN TOUCH CONTROLS',
      'audio_settings_title': 'AUDIO & HAPTICS',
      'vibration_label': 'BUTTON VIBRATION',
      'vibration_sub': 'Haptic feedback when pressing action buttons',
      'music_label': 'BACKGROUND MUSIC (BGM)',
      'sfx_label': 'SOUND EFFECTS (SFX)',
      'hud_custom_title': 'BUTTONS SIZE, OPACITY & POSITION',
      'btn_size_label': 'BUTTON SIZE',
      'btn_opacity_label': 'OPACITY / TRANSPARENCY',
      'btn_edit_positions': 'EDIT BUTTON POSITIONS',
      'btn_reset_layout': 'RESET DEFAULT',
      'editor_banner_title': 'DRAG ANY BUTTON TO MOVE IT!',
      'btn_save_layout': 'SAVE & DONE',
      'enabled': 'ENABLED',
      'disabled': 'DISABLED',
      'btn_close': 'CLOSE',
      'btn_back': 'BACK',

      // Controls Guide
      'controls_title': 'SHINOBI CONTROLS & MECHANICS',
      'ctrl_move': 'Move Left / Right',
      'ctrl_jump': 'Jump / Wall Jump',
      'ctrl_slash': '3-Hit Katana Slash (Damages & Pushes Back!)',
      'ctrl_dash': 'Shadow Dash (Invulnerable Dodge)',
      'ctrl_kunai': 'Throw Ink Kunai (5s Cooldown • Hits Switches & Crates)',
      'ctrl_ougi': 'OUGI Ultimate (Requires 100% Spirit)',
      'ctrl_pause': 'Pause Game',
      'ctrl_tip':
          'TIP: Break crates, hit Switch Orbs to unlock gates, bounce on Taiko Drums, ride Wind Vents, and reach the final Torii Gate to confront each Chapter Boss!',
      'btn_got_it': 'GOT IT!',

      // Story Intro (Optional from Menu)
      'story_skip': 'SKIP',
      'story_next': 'NEXT PANEL',
      'story_begin': 'BACK TO MENU',
      'story_p1_chapter': 'PROLOGUE • PANEL I',
      'story_p1_title': 'THE SACRED CELESTIAL SCROLL',
      'story_p1_caption':
          'For centuries, the Young Shinobi Kaito guarded the Sacred Ink Scroll atop Neo-Tokyo Shrine—keeping the ancient cartoon realms in harmony.',
      'story_p2_chapter': 'PROLOGUE • PANEL II',
      'story_p2_title': 'RISE OF THE FIVE SHADOW WARLORDS',
      'story_p2_caption':
          'Under the Blood Eclipse, Emperor Muzan-Kai and his four warlords—Kurokage, Ryu-Kotei, Hebi-Hime, and Yuki-Oni—stole the scroll and corrupted five realms!',
      'story_p3_chapter': 'PROLOGUE • PANEL III',
      'story_p3_title': 'KAITO\'S SHINOBI OATH',
      'story_p3_caption':
          'Drawing his Celestial Katana, Kaito leaps across five perilous stages to push back the darkness and defeat every Warlord at the end of their domain!',

      // Story Epilogue (Outro after defeating Final Boss Emperor Muzan-Kai)
      'epilogue_finish': 'CLAIM VICTORY',
      'epilogue_p1_chapter': 'EPILOGUE • PANEL I',
      'epilogue_p1_title': 'FALL OF THE BLOOD ECLIPSE',
      'epilogue_p1_caption':
          'With a blinding celestial slash, Emperor Muzan-Kai falls! The dark seal shatters into millions of glowing ink sparks, dissolving the corrupt shadow throne forever.',
      'epilogue_p2_chapter': 'EPILOGUE • PANEL II',
      'epilogue_p2_title': 'REBIRTH OF THE FIVE REALMS',
      'epilogue_p2_caption':
          'As golden celestial ink rains over Neo-Tokyo, the corrupted lands heal: cherry blossoms bloom once more, holy torii gates shine, and peace returns to every temple.',
      'epilogue_p3_chapter': 'EPILOGUE • PANEL III',
      'epilogue_p3_title': 'THE LEGEND OF KAITO',
      'epilogue_p3_caption':
          'His sacred oath fulfilled and the Celestial Scroll restored to the shrine, Kaito stands tall as the ultimate Manga Shinobi. A new legend begins under the morning sun.',

      // Chapter Select
      'select_chapter_title': 'SELECT CHAPTER',
      'select_chapter_sub':
          'ADVANCE THROUGH 5 PROGRESSIVE STAGES & DEFEAT THE 5 WARLORDS!',
      'boss_prefix': 'BOSS: ',
      'btn_play_chapter': 'PLAY',
      'tip_label': 'TIP',
      'arena_gate_badge': 'WARLORD ARENA GATE',
      'arena_gate_desc':
          'Defeat this warlord at the end of the stage to claim the sacred ink seal and unlock the next trial!',

      // Chapter Names & Bosses
      'ch1_title': 'CHAPTER 1: NEO-TOKYO ROOFTOPS',
      'ch1_sub': 'Neon Zipline Rails, Wall-Jump Chimneys & Taiko Sky-Chains',
      'ch1_boss': 'KUROKAGE (Shadow Executioner)',
      'ch1_tip':
          'Dash behind Kurokage during his Shadow Parry for a Backstab Pierce!',
      'ch2_title': 'CHAPTER 2: CRIMSON CITADEL',
      'ch2_sub': 'Erupting Magma Geysers, Vertical Forge Lifts & Twin-Orb Gates',
      'ch2_boss': 'RYU-KOTEI (Dragon Shogun)',
      'ch2_tip':
          'Ryu Kotei deflects frontal hits with Dragon Aegis. Dash behind him to pierce his defense!',
      'ch3_title': 'CHAPTER 3: MYSTIC BAMBOO SHRINE',
      'ch3_sub': 'High-Altitude Wind Canopy, Poison Spore Vents & Swinging Rafts',
      'ch3_boss': 'HEBI-HIME (The Venom Empress)',
      'ch3_tip':
          'Jump to high platforms to evade poison pools and strike Hebi Hime from behind during Viper Coil!',
      'ch4_title': 'CHAPTER 4: FROSTFANG PEAKS',
      'ch4_sub': 'Slippery Ice Physics, Falling Ceiling Icicles & Blizzard Gusts',
      'ch4_boss': 'YUKI-ONI (The Glacial Titan)',
      'ch4_tip':
          "Yuki Oni's Frost Armor absorbs frontal hits. Dash behind him before his ice slam!",
      'ch5_title': 'CHAPTER 5: ECLIPSE BLOOD SANCTUM',
      'ch5_sub': 'Dimensional Warp Portals, Blood Pillars & Grand Emperor Trial',
      'ch5_boss': 'MUZAN-KAI (Lord of the Eclipse)',
      'ch5_tip':
          "Muzan's Void Barrier counters frontal hits. Backstab him and unleash Ougi when Stunned!",

      // HUD
      'hud_ougi_ready': 'READY! [U]',
      'hud_kunai_ready': 'READY [L]',
      'hud_kunai': 'KUNAI: ',
      'hud_spirit': 'SPIRIT ',
      'hud_boss_arena': '⚔ BOSS ARENA ⚔',
      'hud_stage_progress': 'STAGE ',
      'hud_controls_hint':
          '[A/D] Move  [SPACE] Jump  [J] Slash  [K] Dash  [L] Kunai  [U] Ougi  [P] Pause',

      // Pause Overlay
      'pause_tag': 'GAME PAUSED',
      'pause_title': 'TIME FREEZE!!',
      'btn_resume': 'RESUME BATTLE',
      'btn_restart_stage': 'RESTART STAGE',
      'btn_main_menu': 'MAIN MENU',

      // Game Over Overlay
      'gameover_title': 'DEFEATED...',
      'gameover_sub': 'THE INK FADES TO BLACK',
      'score_label': 'SCORE: ',
      'btn_retry': 'RISE AGAIN (RETRY)',

      // Victory Overlay
      'victory_chapter': 'CHAPTER CLEARED!!',
      'victory_all': 'ALL 5 CHAPTERS CONQUERED!!',
      'victory_sub_next':
          'THE SHADOW WARLORD HAS FALLEN! PREPARE FOR THE NEXT STAGE!',
      'victory_sub_all':
          'YOU DEFEATED MUZAN-KAI AND RESTORED THE SACRED INK SCROLL!',
      'final_score_label': 'FINAL SCORE: ',
      'btn_next_chapter': 'NEXT CHAPTER',
      'btn_play_again': 'PLAY AGAIN (CH. 1)',
      'btn_replay_stage': 'REPLAY STAGE',
    },
    AppLanguage.es: {
      // Splash & Title
      'game_title_top': 'KAITO',
      'game_title_bottom': 'ADVENTURE',
      'game_subtitle': '★ EL SHINOBI DE LA TINTA CELESTIAL ★',
      'developed_by': 'DESARROLLADO POR JANOSOS',
      'tap_to_continue': 'TOCA PARA CONTINUAR',

      // Main Menu
      'edition_badge': 'EDICIÓN CARTOON 2D • 5 CAPÍTULOS',
      'hero_card_sub': '5 NIVELES PROGRESIVOS • 5 JEFES SEÑORES DE LA GUERRA',
      'btn_start_adventure': 'INICIAR AVENTURA',
      'btn_multiplayer': 'MODO MULTIJUGADOR (WIFI LOCAL)',
      'btn_select_chapter': 'SELECCIONAR CAPÍTULO (1 - 5)',
      'btn_story_intro': 'HISTORIA (INTRO)',
      'btn_how_to_play': 'CÓMO JUGAR',
      'btn_settings': 'AJUSTES / IDIOMA',
      'btn_install_app': 'INSTALAR APP',

      // PWA / App Installation Modal
      'install_title': 'INSTALAR KAITO ADVENTURE',
      'install_sub': '¡JUEGA EN PANTALLA COMPLETA HORIZONTAL Y COMO APP NATIVA!',
      'install_android_tab': 'ANDROID / CHROME',
      'install_ios_tab': 'IPHONE / IPAD (iOS)',
      'install_btn_now': 'INSTALAR AHORA',
      'install_already_installed': '✓ ¡La aplicación ya está instalada en tu dispositivo!',
      'install_android_guide':
          'Pulsa "INSTALAR AHORA", o abre el menú de tu navegador (⋮) y selecciona "Instalar aplicación" o "Agregar a pantalla principal" para jugar sin marcos.',
      'install_ios_step1':
          '1. En Safari, toca el botón de Compartir [ ⎋ ] en la barra inferior.',
      'install_ios_step2':
          '2. Desplázate hacia abajo y selecciona "Agregar a pantalla de inicio" [ ⊞ ].',
      'install_ios_step3':
          '3. Pulsa "Agregar". ¡Ábrela desde tu inicio para jugar en pantalla completa horizontal sin barras de navegador!',
      'btn_fullscreen_landscape': 'PANTALLA COMPLETA & GIRAR',

      // Settings Modal / Screen
      'settings_title': 'AJUSTES DEL JUEGO',
      'settings_subtitle': 'CONFIGURACIÓN DE IDIOMA Y CONTROLES',
      'language_label': 'IDIOMA / LANGUAGE / 言語',
      'lang_en': 'ENGLISH (INGLÉS)',
      'lang_es': 'ESPAÑOL (ACTIVO)',
      'lang_ja': '日本語 (JAPONÉS)',
      'virtual_controls_label': 'CONTROLES TÁCTILES EN PANTALLA',
      'audio_settings_title': 'AUDIO Y VIBRACIÓN',
      'vibration_label': 'VIBRACIÓN AL TOCAR',
      'vibration_sub': 'Retroalimentación háptica al pulsar botones',
      'music_label': 'MÚSICA DE FONDO (BGM)',
      'sfx_label': 'EFECTOS DE SONIDO (SFX)',
      'hud_custom_title': 'TAMAÑO, TRANSPARENCIA Y POSICIÓN DE BOTONES',
      'btn_size_label': 'TAMAÑO DE BOTONES',
      'btn_opacity_label': 'TRANSPARENCIA / OPACIDAD',
      'btn_edit_positions': 'EDITAR POSICIÓN DE BOTONES',
      'btn_reset_layout': 'RESTABLECER',
      'editor_banner_title': '¡ARRASTRA CUALQUIER BOTÓN PARA MOVERLO!',
      'btn_save_layout': 'GUARDAR Y SALIR',
      'enabled': 'ACTIVADO',
      'disabled': 'DESACTIVADO',
      'btn_close': 'CERRAR',
      'btn_back': 'VOLVER',

      // Controls Guide
      'controls_title': 'CONTROLES Y MECÁNICAS SHINOBI',
      'ctrl_move': 'Moverse Izquierda / Derecha',
      'ctrl_jump': 'Saltar / Salto en Pared',
      'ctrl_slash': 'Combo Katana 3 Golpes (¡Daña y Empuja!)',
      'ctrl_dash': 'Impulso Sombra (Esquiva Invulnerable)',
      'ctrl_kunai': 'Lanzar Kunai de Tinta (5s Enfriamiento • Activa Orbes)',
      'ctrl_ougi': 'OUGI Definitivo (Requiere 100% Espíritu)',
      'ctrl_pause': 'Pausar Juego',
      'ctrl_tip':
          'CONSEJO: ¡Rompe cajas, golpea Orbes Interruptores para abrir barreras, rebota en Tambores Taiko, usa Corrientes de Viento y llega al Portal Torii final para enfrentar al Jefe!',
      'btn_got_it': '¡ENTENDIDO!',

      // Story Intro (Optional from Menu)
      'story_skip': 'SALTAR',
      'story_next': 'SIGUIENTE VIÑETA',
      'story_begin': 'VOLVER AL MENÚ',
      'story_p1_chapter': 'PRÓLOGO • VIÑETA I',
      'story_p1_title': 'EL PERGAMINO CELESTIAL SAGRADO',
      'story_p1_caption':
          'Durante siglos, el joven shinobi Kaito custodió el Pergamino de Tinta Sagrada en el Santuario de Neo-Tokio, manteniendo los reinos en armonía.',
      'story_p2_chapter': 'PRÓLOGO • VIÑETA II',
      'story_p2_title': 'EL ASCENSO DE LOS CINCO SEÑORES OSCUROS',
      'story_p2_caption':
          '¡Bajo el Eclipse Sangriento, el Emperador Muzan-Kai y sus cuatro señores de la guerra—Kurokage, Ryu-Kotei, Hebi-Hime y Yuki-Oni—robaron el pergamino!',
      'story_p3_chapter': 'PRÓLOGO • VIÑETA III',
      'story_p3_title': 'EL JURAMENTO SHINOBI DE KAITO',
      'story_p3_caption':
          '¡Desenvainando su Katana Celestial, Kaito avanza a través de cinco peligrosos niveles para hacer retroceder la oscuridad y derrotar a cada Jefe en su dominio!',

      // Story Epilogue (Outro after defeating Final Boss Emperor Muzan-Kai)
      'epilogue_finish': 'RECLAMAR VICTORIA',
      'epilogue_p1_chapter': 'EPÍLOGO • VIÑETA I',
      'epilogue_p1_title': 'LA CAÍDA DEL ECLIPSE ROJO',
      'epilogue_p1_caption':
          '¡Con un corte celestial deslumbrante, el Emperador Muzan-Kai cae derrotado! El sello oscuro se hace añicos en millones de chispas de tinta luminosa, disolviendo el trono de las sombras.',
      'epilogue_p2_chapter': 'EPÍLOGO • VIÑETA II',
      'epilogue_p2_title': 'RENACER DE LOS CINCO REINOS',
      'epilogue_p2_caption':
          'Mientras una lluvia de tinta dorada celestial baña Neo-Tokio, las tierras se restauran: los cerezos florecen de nuevo, los torii brillan con luz sagrada y la paz regresa a cada rincón.',
      'epilogue_p3_chapter': 'EPÍLOGO • VIÑETA III',
      'epilogue_p3_title': 'LA LEYENDA DE KAITO',
      'epilogue_p3_caption':
          'Cumplido su juramento sagrado y devuelto el Pergamino Celestial al santuario, Kaito se erige como el Shinobi definitivo del Manga. ¡Una nueva leyenda nace bajo el sol del amanecer!',

      // Chapter Select
      'select_chapter_title': 'SELECCIONAR CAPÍTULO',
      'select_chapter_sub':
          '¡AVANZA POR 5 ETAPAS PROGRESIVAS Y DERROTA A LOS 5 JEFES!',
      'boss_prefix': 'JEFE: ',
      'btn_play_chapter': 'JUGAR',
      'tip_label': 'CONSEJO',
      'arena_gate_badge': 'PUERTA DE ARENA DEL JEFE',
      'arena_gate_desc':
          '¡Derrota a este señor de la guerra al final de la etapa para reclamar el sello sagrado y avanzar al siguiente desafío!',

      // Chapter Names & Bosses
      'ch1_title': 'CAPÍTULO 1: TEJADOS DE NEO-TOKIO',
      'ch1_sub': 'Tirolesas Neón, Chimeneas de Salto en Pared y Tambores Taiko',
      'ch1_boss': 'KUROKAGE (Ejecutor de las Sombras)',
      'ch1_tip':
          '¡Haz Dash detrás de Kurokage durante su Shadow Parry para un Backstab Pierce!',
      'ch2_title': 'CAPÍTULO 2: CIUDADELA CARMESÍ',
      'ch2_sub': 'Géiseres de Magma, Elevadores Verticales y Puertas Dobles',
      'ch2_boss': 'RYU-KOTEI (Shogun Dragón)',
      'ch2_tip':
          '¡Ryu Kotei desvía golpes frontales con Dragon Aegis. Haz Dash detrás de él para atravesar su guardia!',
      'ch3_title': 'CAPÍTULO 3: SANTUARIO DE BAMBÚ MÍSTICO',
      'ch3_sub': 'Corrientes en las Copas, Esporas Venenosas y Balsas Móviles',
      'ch3_boss': 'HEBI-HIME (La Emperatriz del Veneno)',
      'ch3_tip':
          '¡Salta a plataformas altas para evadir charcos de veneno y golpea a Hebi Hime por la espalda en Viper Coil!',
      'ch4_title': 'CAPÍTULO 4: CUMBRES COLMILLO HELADO',
      'ch4_sub': 'Física de Hielo Resbaladizo, Estalactitas y Ventiscas',
      'ch4_boss': 'YUKI-ONI (El Titán Glacial)',
      'ch4_tip':
          '¡La Frost Armor de Yuki Oni absorbe daño frontal. Haz Dash detrás de él antes de su golpe congelante!',
      'ch5_title': 'CAPÍTULO 5: SANTUARIO DEL ECLIPSE SANGRIENTO',
      'ch5_sub': 'Portales Dimensionales, Pilares Sangrientos y Gran Prueba Final',
      'ch5_boss': 'MUZAN-KAI (Señor del Eclipse)',
      'ch5_tip':
          '¡La Void Barrier de Muzan contraataca de frente. Haz Backstab y desata tu Ougi cuando esté aturdido!',

      // HUD
      'hud_ougi_ready': '¡LISTO! [U]',
      'hud_kunai_ready': 'LISTO [L]',
      'hud_kunai': 'KUNAI: ',
      'hud_spirit': 'ESPÍRITU ',
      'hud_boss_arena': '⚔ ARENA DEL JEFE ⚔',
      'hud_stage_progress': 'ETAPA ',
      'hud_controls_hint':
          '[A/D] Mover  [ESPACIO] Saltar  [J] Slash  [K] Dash  [L] Kunai  [U] Ougi  [P] Pausa',

      // Pause Overlay
      'pause_tag': 'JUEGO EN PAUSA',
      'pause_title': '¡¡TIEMPO DETENIDO!!',
      'btn_resume': 'REANUDAR BATALLA',
      'btn_restart_stage': 'REINICIAR NIVEL',
      'btn_main_menu': 'MENÚ PRINCIPAL',

      // Game Over Overlay
      'gameover_title': 'DERROTADO...',
      'gameover_sub': 'LA TINTA SE DESVANECE EN LA OSCURIDAD',
      'score_label': 'PUNTUACIÓN: ',
      'btn_retry': 'LEVANTARSE DE NUEVO (REINTENTAR)',

      // Victory Overlay
      'victory_chapter': '¡¡CAPÍTULO SUPERADO!!',
      'victory_all': '¡¡LOS 5 CAPÍTULOS CONQUISTADOS!!',
      'victory_sub_next':
          '¡EL SEÑOR DE LA GUERRA HA CAÍDO! ¡PREPÁRATE PARA LA SIGUIENTE ETAPA!',
      'victory_sub_all':
          '¡DERROTASTE A MUZAN-KAI Y RECUPERASTE EL PERGAMINO SAGRADO!',
      'final_score_label': 'PUNTUACIÓN FINAL: ',
      'btn_next_chapter': 'SIGUIENTE CAPÍTULO',
      'btn_play_again': 'JUGAR DE NUEVO (CAP. 1)',
      'btn_replay_stage': 'REPETIR NIVEL',
    },
    AppLanguage.ja: {
      // Splash & Title
      'game_title_top': 'KAITO',
      'game_title_bottom': 'ADVENTURE',
      'game_subtitle': '★ 天翔ける墨の忍 ★',
      'developed_by': '開発：JANOSOS',
      'tap_to_continue': 'タップしてスタート',

      // Main Menu
      'edition_badge': '2Dカートゥーン版 • 全5章',
      'hero_card_sub': '全5ステージ • 5大武将ボス',
      'btn_start_adventure': '冒険を始める',
      'btn_multiplayer': 'マルチプレイ (ローカルWIFI)',
      'btn_select_chapter': '章を選択 (1 - 5)',
      'btn_story_intro': 'ストーリー紹介',
      'btn_how_to_play': '操作方法・遊び方',
      'btn_settings': '設定 / 言語 (SETTINGS)',
      'btn_install_app': 'アプリをインストール',

      // PWA / App Installation Modal
      'install_title': 'カイト・アドベンチャーをインストール',
      'install_sub': '全画面横向き・オフラインでネイティブアプリのように遊ぼう！',
      'install_android_tab': 'ANDROID / CHROME',
      'install_ios_tab': 'IPHONE / IPAD (iOS)',
      'install_btn_now': '今すぐインストール',
      'install_already_installed': '✓ アプリはすでにインストールされています！',
      'install_android_guide':
          '「今すぐインストール」をタップするか、ブラウザメニュー（⋮）から「アプリをインストール」または「ホーム画面に追加」を選択してください。',
      'install_ios_step1':
          '1. Safari下部の共有ボタン [ ⎋ ] をタップします。',
      'install_ios_step2':
          '2. メニューをスクロールし、「ホーム画面に追加」[ ⊞ ] を選択します。',
      'install_ios_step3':
          '3. 「追加」をタップ。ホーム画面から起動すると自動で横全画面で快適に遊べます！',
      'btn_fullscreen_landscape': '全画面表示＆横向き固定',

      // Settings Modal / Screen
      'settings_title': 'ゲーム設定',
      'settings_subtitle': '言語とコントロールの設定',
      'language_label': '言語 / LANGUAGE / IDIOMA',
      'lang_en': 'ENGLISH (英語・デフォルト)',
      'lang_es': 'ESPAÑOL (スペイン語)',
      'lang_ja': '日本語 (現在選択中)',
      'virtual_controls_label': '画面タッチコントロール',
      'audio_settings_title': '音効・振動設定',
      'vibration_label': 'ボタン振動',
      'vibration_sub': 'ボタン操作時の触覚フィードバック',
      'music_label': 'BGM (音楽)',
      'sfx_label': '効果音 (SFX)',
      'hud_custom_title': 'ボタンのサイズ・透明度・配置',
      'btn_size_label': 'ボタンサイズ',
      'btn_opacity_label': '透明度 / 不透明度',
      'btn_edit_positions': 'ボタン配置を編集',
      'btn_reset_layout': '初期設定に戻す',
      'editor_banner_title': 'ボタンをドラッグして好きな位置へ移動！',
      'btn_save_layout': '保存して完了',
      'enabled': 'オン (ON)',
      'disabled': 'オフ (OFF)',
      'btn_close': '閉じる',
      'btn_back': '戻る',

      // Controls Guide
      'controls_title': '忍びの操作とアクション',
      'ctrl_move': '左右に移動',
      'ctrl_jump': 'ジャンプ / 壁キック',
      'ctrl_slash': '3連刀スラッシュ (ダメージ＋ノックバック！)',
      'ctrl_dash': '影ダッシュ (無敵回避)',
      'ctrl_kunai': '墨クナイ投げ (5秒クールダウン • スイッチ起動)',
      'ctrl_ougi': '奥義・千羽鶴斬 (霊力100%で発動)',
      'ctrl_pause': 'ポーズメニュー',
      'ctrl_tip':
          'ヒント：木箱を壊し、スイッチ宝珠を叩いて門を開き、太鼓で跳ね、上昇気流に乗って最終エリアの鳥居で待つボスを討て！',
      'btn_got_it': '了解！',

      // Story Intro (Optional from Menu)
      'story_skip': 'スキップ',
      'story_next': '次のコマへ',
      'story_begin': 'メニューへ戻る',
      'story_p1_chapter': '序章 • 第壱幕',
      'story_p1_title': '聖なる天墨の巻物',
      'story_p1_caption':
          '幾星霜もの間、若き忍カイトはネオ東京の社で「聖なる墨の巻物」を守り、世界の調和を保っていた。',
      'story_p2_chapter': '序章 • 第弐幕',
      'story_p2_title': '五人の闇武将の襲来',
      'story_p2_caption':
          '紅き日食の夜、帝王ムザン＝カイと四天王（クロカゲ、リュウ＝コウテイ、ヘビ姫、ユキ鬼）が巻物を奪い去った！',
      'story_p3_chapter': '序章 • 第参幕',
      'story_p3_title': 'カイトの誓い',
      'story_p3_caption':
          '天墨の刀を抜き放ち、カイトは5つの過酷なステージを駆け抜け、最奥で待ち受ける闇武将たちに挑む！',

      // Story Epilogue (Outro after defeating Final Boss Emperor Muzan-Kai)
      'epilogue_finish': '勝利の栄光へ',
      'epilogue_p1_chapter': '終章 • 第壱幕',
      'epilogue_p1_title': '血の月蝕の崩壊',
      'epilogue_p1_caption':
          '渾身の神速斬撃により、皇帝ムザンカイは討ち果たされた！闇の封印は無数の光るインクの火花となって砕け散り、邪悪なる玉座は永遠に崩れ去った。',
      'epilogue_p2_chapter': '終章 • 第弐幕',
      'epilogue_p2_title': '五つの世界の新生',
      'epilogue_p2_caption':
          'ネオ東京の空から黄金の天墨が降り注ぎ、蝕まれた大地が蘇る。桜が満開に咲き誇り、鳥居が清らかな輝きを取り戻し、平和が訪れた。',
      'epilogue_p3_chapter': '終章 • 第参幕',
      'epilogue_p3_title': 'カイトの伝説',
      'epilogue_p3_caption':
          '神聖なる誓いは果たされ、天墨の巻物は社へと奉納された。カイトは真の忍としての道を切り拓き、朝日のもとで新たな伝説が今、始まる。',

      // Chapter Select
      'select_chapter_title': '章セレクト',
      'select_chapter_sub': '5つのステージを突破し、5人の闇武将を打ち倒せ！',
      'boss_prefix': 'ボス：',
      'btn_play_chapter': '出陣',
      'tip_label': '攻略のヒント',
      'arena_gate_badge': '武将決戦の門',
      'arena_gate_desc':
          'ステージ最深部の武将を討伐し、聖なる墨の封印を解放して次なる試練へ進め！',

      // Chapter Names & Bosses
      'ch1_title': '第1章：ネオ東京の屋根裏',
      'ch1_sub': 'ネオン滑空レール・壁蹴り煙突と空中太鼓チェーン',
      'ch1_boss': 'クロカゲ (影の処刑人)',
      'ch1_tip': '影パリィ中にダッシュで背後に回り込み「バックスタブ」を決めろ！',
      'ch2_title': '第2章：紅蓮の城塞',
      'ch2_sub': '噴き上がる溶岩間欠泉・昇降リフトと二重封印門',
      'ch2_boss': 'リュウ＝コウテイ (炎龍将軍)',
      'ch2_tip': '竜帝の正面防御をダッシュで回り込み、背後から突き刺せ！',
      'ch3_title': '第3章：幽玄の竹林社',
      'ch3_sub': '樹冠の上昇気流・猛毒胞子トラップと揺れる竹筏',
      'ch3_boss': 'ヘビ姫 (毒蛇の女帝)',
      'ch3_tip': '高い足場へ跳び毒溜まりを回避し、蛇の構え中に背後から奇襲せよ！',
      'ch4_title': '第4章：氷牙の霊峰',
      'ch4_sub': '滑る氷床・落下する氷柱トラップと猛吹雪の横風',
      'ch4_boss': 'ユキ鬼 (氷河の巨鬼)',
      'ch4_tip': '雪鬼の氷結鎧は正面無効。ダッシュで背後を取り破壊せよ！',
      'ch5_title': '第5章：紅き日食の聖殿',
      'ch5_sub': '次元転移ポータル・血蝕の火柱と最終試練',
      'ch5_boss': 'ムザン＝カイ (紅き日食の覇王)',
      'ch5_tip': '無惨魁の虚空障壁は正面反撃！背後攻撃でスタンさせ奥義を叩き込め！',

      // HUD
      'hud_ougi_ready': '奥義発動可! [U]',
      'hud_kunai_ready': '準備完了 [L]',
      'hud_kunai': 'クナイ: ',
      'hud_spirit': '霊力 ',
      'hud_boss_arena': '⚔ ボス決戦 ⚔',
      'hud_stage_progress': 'ステージ ',
      'hud_controls_hint':
          '[A/D] 移動  [SPACE] ジャンプ  [J] 斬撃  [K] ダッシュ  [L] クナイ  [U] 奥義  [P] 一時停止',

      // Pause Overlay
      'pause_tag': '一時停止中',
      'pause_title': '時よ止まれ！！',
      'btn_resume': '戦いに戻る',
      'btn_restart_stage': 'ステージをやり直す',
      'btn_main_menu': 'メインメニュー',

      // Game Over Overlay
      'gameover_title': '敗北...',
      'gameover_sub': '墨が闇へと消えていく...',
      'score_label': 'スコア：',
      'btn_retry': '再び立ち上がる (リトライ)',

      // Victory Overlay
      'victory_chapter': '章クリア！！',
      'victory_all': '全5章完全制覇！！',
      'victory_sub_next': '闇武将を討ち取った！次のステージへ進め！',
      'victory_sub_all': 'ムザン＝カイを打ち倒し、聖なる巻物を取り戻した！',
      'final_score_label': '最終スコア：',
      'btn_next_chapter': '次の章へ',
      'btn_play_again': '最初から遊ぶ (第1章)',
      'btn_replay_stage': 'もう一度プレイ',
    },
  };
}
