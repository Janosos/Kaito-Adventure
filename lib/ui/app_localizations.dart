import 'package:flutter/foundation.dart';

enum AppLanguage {
  en, // English (Default)
  es, // Español
  ja, // 日本語 (Japanese)
}

class AppLocalizations {
  /// Global reactive language notifier — always defaults to English (`AppLanguage.en`)
  static final ValueNotifier<AppLanguage> languageNotifier =
      ValueNotifier<AppLanguage>(AppLanguage.en);

  /// Global reactive setting for virtual on-screen controls
  static final ValueNotifier<bool> showVirtualControls =
      ValueNotifier<bool>(true);

  static AppLanguage get current => languageNotifier.value;

  static void setLanguage(AppLanguage lang) {
    languageNotifier.value = lang;
  }

  static String tr(String key) {
    final lang = languageNotifier.value;
    final map = _translations[lang] ?? _translations[AppLanguage.en]!;
    return map[key] ?? _translations[AppLanguage.en]![key] ?? key;
  }

  static String chapterTitle(int chapter) => tr('ch${chapter}_title');
  static String chapterSubtitle(int chapter) => tr('ch${chapter}_sub');
  static String chapterBoss(int chapter) => tr('ch${chapter}_boss');

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
      'btn_select_chapter': 'SELECT CHAPTER (1 - 5)',
      'btn_story_intro': 'STORY INTRO',
      'btn_how_to_play': 'HOW TO PLAY',
      'btn_settings': 'SETTINGS',

      // Settings Modal / Screen
      'settings_title': 'GAME SETTINGS',
      'settings_subtitle': 'LANGUAGE & CONTROLS CONFIGURATION',
      'language_label': 'LANGUAGE / IDIOMA / 言語',
      'lang_en': 'ENGLISH (DEFAULT)',
      'lang_es': 'ESPAÑOL (SPANISH)',
      'lang_ja': '日本語 (JAPANESE)',
      'virtual_controls_label': 'ON-SCREEN TOUCH CONTROLS',
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

      // Chapter Select
      'select_chapter_title': 'SELECT CHAPTER',
      'select_chapter_sub':
          'ADVANCE THROUGH 5 PROGRESSIVE STAGES & DEFEAT THE 5 WARLORDS!',
      'boss_prefix': 'BOSS: ',
      'btn_play_chapter': 'PLAY',

      // Chapter Names & Bosses
      'ch1_title': 'CHAPTER 1: NEO-TOKYO ROOFTOPS (4.6 KM)',
      'ch1_sub': 'Neon Zipline Rails, Wall-Jump Chimneys & Taiko Sky-Chains',
      'ch1_boss': 'KUROKAGE (Shadow Executioner)',
      'ch2_title': 'CHAPTER 2: CRIMSON CITADEL (5.0 KM)',
      'ch2_sub': 'Erupting Magma Geysers, Vertical Forge Lifts & Twin-Orb Gates',
      'ch2_boss': 'RYU-KOTEI (Dragon Shogun)',
      'ch3_title': 'CHAPTER 3: MYSTIC BAMBOO SHRINE (5.4 KM)',
      'ch3_sub': 'High-Altitude Wind Canopy, Poison Spore Vents & Swinging Rafts',
      'ch3_boss': 'HEBI-HIME (The Venom Empress)',
      'ch4_title': 'CHAPTER 4: FROSTFANG PEAKS (5.8 KM)',
      'ch4_sub': 'Slippery Ice Physics, Falling Ceiling Icicles & Blizzard Gusts',
      'ch4_boss': 'YUKI-ONI (The Glacial Titan)',
      'ch5_title': 'CHAPTER 5: ECLIPSE BLOOD SANCTUM (6.4 KM)',
      'ch5_sub': 'Dimensional Warp Portals, Blood Pillars & Grand Emperor Trial',
      'ch5_boss': 'MUZAN-KAI (Lord of the Eclipse)',

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
      'btn_select_chapter': 'SELECCIONAR CAPÍTULO (1 - 5)',
      'btn_story_intro': 'HISTORIA (INTRO)',
      'btn_how_to_play': 'CÓMO JUGAR',
      'btn_settings': 'AJUSTES / IDIOMA',

      // Settings Modal / Screen
      'settings_title': 'AJUSTES DEL JUEGO',
      'settings_subtitle': 'CONFIGURACIÓN DE IDIOMA Y CONTROLES',
      'language_label': 'IDIOMA / LANGUAGE / 言語',
      'lang_en': 'ENGLISH (INGLÉS)',
      'lang_es': 'ESPAÑOL (ACTIVO)',
      'lang_ja': '日本語 (JAPONÉS)',
      'virtual_controls_label': 'CONTROLES TÁCTILES EN PANTALLA',
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

      // Chapter Select
      'select_chapter_title': 'SELECCIONAR CAPÍTULO',
      'select_chapter_sub':
          '¡AVANZA POR 5 ETAPAS PROGRESIVAS Y DERROTA A LOS 5 JEFES!',
      'boss_prefix': 'JEFE: ',
      'btn_play_chapter': 'JUGAR',

      // Chapter Names & Bosses
      'ch1_title': 'CAPÍTULO 1: TEJADOS DE NEO-TOKIO (4.6 KM)',
      'ch1_sub': 'Tirolesas Neón, Chimeneas de Salto en Pared y Tambores Taiko',
      'ch1_boss': 'KUROKAGE (Ejecutor de las Sombras)',
      'ch2_title': 'CAPÍTULO 2: CIUDADELA CARMESÍ (5.0 KM)',
      'ch2_sub': 'Géiseres de Magma, Elevadores Verticales y Puertas Dobles',
      'ch2_boss': 'RYU-KOTEI (Shogun Dragón)',
      'ch3_title': 'CAPÍTULO 3: SANTUARIO DE BAMBÚ MÍSTICO (5.4 KM)',
      'ch3_sub': 'Corrientes en las Copas, Esporas Venenosas y Balsas Móviles',
      'ch3_boss': 'HEBI-HIME (La Emperatriz del Veneno)',
      'ch4_title': 'CAPÍTULO 4: CUMBRES COLMILLO HELADO (5.8 KM)',
      'ch4_sub': 'Física de Hielo Resbaladizo, Estalactitas y Ventiscas',
      'ch4_boss': 'YUKI-ONI (El Titán Glacial)',
      'ch5_title': 'CAPÍTULO 5: SANTUARIO DEL ECLIPSE SANGRIENTO (6.4 KM)',
      'ch5_sub': 'Portales Dimensionales, Pilares Sangrientos y Gran Prueba Final',
      'ch5_boss': 'MUZAN-KAI (Señor del Eclipse)',

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
      'btn_select_chapter': '章を選択 (1 - 5)',
      'btn_story_intro': 'ストーリー紹介',
      'btn_how_to_play': '操作方法・遊び方',
      'btn_settings': '設定 / 言語 (SETTINGS)',

      // Settings Modal / Screen
      'settings_title': 'ゲーム設定',
      'settings_subtitle': '言語とコントロールの設定',
      'language_label': '言語 / LANGUAGE / IDIOMA',
      'lang_en': 'ENGLISH (英語・デフォルト)',
      'lang_es': 'ESPAÑOL (スペイン語)',
      'lang_ja': '日本語 (現在選択中)',
      'virtual_controls_label': '画面タッチコントロール',
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

      // Chapter Select
      'select_chapter_title': '章セレクト',
      'select_chapter_sub': '5つのステージを突破し、5人の闇武将を打ち倒せ！',
      'boss_prefix': 'ボス：',
      'btn_play_chapter': '出陣',

      // Chapter Names & Bosses
      'ch1_title': '第1章：ネオ東京の屋根裏 (4.6 KM)',
      'ch1_sub': 'ネオン滑空レール・壁蹴り煙突と空中太鼓チェーン',
      'ch1_boss': 'クロカゲ (影の処刑人)',
      'ch2_title': '第2章：紅蓮の城塞 (5.0 KM)',
      'ch2_sub': '噴き上がる溶岩間欠泉・昇降リフトと二重封印門',
      'ch2_boss': 'リュウ＝コウテイ (炎龍将軍)',
      'ch3_title': '第3章：幽玄の竹林社 (5.4 KM)',
      'ch3_sub': '樹冠の上昇気流・猛毒胞子トラップと揺れる竹筏',
      'ch3_boss': 'ヘビ姫 (毒蛇の女帝)',
      'ch4_title': '第4章：氷牙の霊峰 (5.8 KM)',
      'ch4_sub': '滑る氷床・落下する氷柱トラップと猛吹雪の横風',
      'ch4_boss': 'ユキ鬼 (氷河の巨鬼)',
      'ch5_title': '第5章：紅き日食の聖殿 (6.4 KM)',
      'ch5_sub': '次元転移ポータル・血蝕の火柱と最終試練',
      'ch5_boss': 'ムザン＝カイ (紅き日食の覇王)',

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

