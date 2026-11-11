import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../../ui/app_localizations.dart';

class AudioService {
  static bool isTestMode = false;
  static bool _initialized = false;

  // SFX file paths (relative to assets/audio/)
  static const String sfxClick = 'sfx/ui_click.wav';
  static const String sfxStart = 'sfx/ui_start.wav';
  static const String sfxSlash = 'sfx/slash.wav';
  static const String sfxSlashHeavy = 'sfx/slash_heavy.wav';
  static const String sfxJump = 'sfx/jump.wav';
  static const String sfxDash = 'sfx/dash.wav';
  static const String sfxKunaiThrow = 'sfx/kunai_throw.wav';
  static const String sfxKunaiHit = 'sfx/kunai_hit.wav';
  static const String sfxEnemyHit = 'sfx/enemy_hit.wav';
  static const String sfxEnemyDefeat = 'sfx/enemy_defeat.wav';
  static const String sfxPlayerHurt = 'sfx/player_hurt.wav';
  static const String sfxPlayerDeath = 'sfx/player_death.wav';
  static const String sfxParryCounter = 'sfx/parry_counter.wav';
  static const String sfxBackstabPierce = 'sfx/backstab_pierce.wav';
  static const String sfxOugiCharge = 'sfx/ougi_charge.wav';
  static const String sfxOugiRelease = 'sfx/ougi_release.wav';
  static const String sfxBossRoar = 'sfx/boss_roar.wav';
  static const String sfxPickupCoin = 'sfx/pickup_coin.wav';
  static const String sfxVictory = 'sfx/victory.wav';
  static const String sfxGameOver = 'sfx/game_over.wav';

  // BGM file paths (relative to assets/audio/)
  static const String bgmMenu = 'bgm/bgm_menu.wav';
  static const String bgmStage = 'bgm/bgm_stage.wav';
  static const String bgmBoss = 'bgm/bgm_boss.wav';

  // Dedicated BGM AudioPlayer
  static AudioPlayer? _bgmPlayer;
  static String? _currentBgm;
  static String? _targetBgm;
  static bool _bgmIsPlaying = false;

  // Reusable SFX AudioPlayer Pool (Fixed 8 players - zero allocations, zero leaks)
  static const int _sfxPoolSize = 8;
  static final List<AudioPlayer> _sfxPool = [];
  static int _sfxIndex = 0;

  // Audio Cache configured with asset prefix
  static final AudioCache _audioCache = AudioCache(prefix: 'assets/audio/');

  /// Preload common SFX and initialize audio players with non-blocking audio focus
  static Future<void> init() async {
    if (isTestMode || _initialized) return;
    _initialized = true;

    try {
      final context = AudioContextConfig(
        focus: AudioContextConfigFocus.mixWithOthers,
      ).build();

      // Configure global context so all players mix cleanly without dropping tracks
      await AudioPlayer.global.setAudioContext(context);

      // Setup dedicated BGM player
      _bgmPlayer = AudioPlayer(playerId: 'kaito_bgm');
      _bgmPlayer!.audioCache = _audioCache;
      await _bgmPlayer!.setAudioContext(context);
      await _bgmPlayer!.setReleaseMode(ReleaseMode.loop);

      // Setup fixed SFX pool (8 reusable players)
      for (int i = 0; i < _sfxPoolSize; i++) {
        final p = AudioPlayer(playerId: 'kaito_sfx_$i');
        p.audioCache = _audioCache;
        await p.setAudioContext(context);
        await p.setReleaseMode(ReleaseMode.stop);
        _sfxPool.add(p);
      }

      // Preload critical assets in background without blocking startup
      _audioCache.loadAll([
        sfxClick,
        sfxStart,
        sfxSlash,
        sfxSlashHeavy,
        sfxJump,
        sfxDash,
        sfxKunaiThrow,
        sfxKunaiHit,
        sfxEnemyHit,
        sfxEnemyDefeat,
        sfxPlayerHurt,
        sfxPlayerDeath,
        sfxParryCounter,
        sfxBackstabPierce,
        sfxOugiCharge,
        sfxOugiRelease,
        sfxBossRoar,
        sfxPickupCoin,
      ]).catchError((_) => <Uri>[]);
    } catch (_) {
      // Ignored in test/headless environments
    }
  }

  /// Play a sound effect using pre-allocated round-robin audio player pool
  static void playSfx(String sfxFile, {double volume = 1.0}) {
    if (isTestMode) return;
    if (!AppLocalizations.sfxEnabled.value) return;

    try {
      final vol = (AppLocalizations.sfxVolume.value * volume).clamp(0.0, 1.0);
      if (vol <= 0.001) return;

      if (_sfxPool.isEmpty) return;

      final player = _sfxPool[_sfxIndex];
      _sfxIndex = (_sfxIndex + 1) % _sfxPool.length;

      player.stop().then((_) {
        player.setVolume(vol).then((_) {
          player.play(
            AssetSource(sfxFile),
            volume: vol,
            mode: PlayerMode.lowLatency,
          );
        }).catchError((_) {});
      }).catchError((_) {});
    } catch (_) {}
  }

  /// Play a looping background music track seamlessly with dedicated player
  static void playBgm(String bgmFile, {double volume = 1.0}) {
    if (isTestMode) return;
    _targetBgm = bgmFile;

    if (!AppLocalizations.bgmEnabled.value) {
      stopBgm();
      return;
    }

    try {
      final vol = (AppLocalizations.bgmVolume.value * volume).clamp(0.0, 1.0);
      if (_bgmPlayer == null) return;

      if (_currentBgm == bgmFile && _bgmIsPlaying) {
        _bgmPlayer!.setVolume(vol).catchError((_) {});
        return;
      }

      _currentBgm = bgmFile;
      _bgmIsPlaying = true;

      _bgmPlayer!.stop().then((_) {
        if (_currentBgm != bgmFile) return;
        _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
        _bgmPlayer!.setVolume(vol);
        _bgmPlayer!.play(
          AssetSource(bgmFile),
          volume: vol,
          mode: PlayerMode.mediaPlayer,
        );
      }).catchError((_) {});
    } catch (_) {}
  }

  /// Stop current BGM
  static void stopBgm() {
    if (isTestMode) return;
    _currentBgm = null;
    _bgmIsPlaying = false;
    try {
      _bgmPlayer?.stop().catchError((_) {});
    } catch (_) {}
  }

  /// Pause current BGM (e.g. during pause overlay)
  static void pauseBgm() {
    if (isTestMode) return;
    _bgmIsPlaying = false;
    try {
      _bgmPlayer?.pause().catchError((_) {});
    } catch (_) {}
  }

  /// Resume current BGM
  static void resumeBgm() {
    if (isTestMode) return;
    if (!AppLocalizations.bgmEnabled.value) return;
    if (_currentBgm == null && _targetBgm != null) {
      playBgm(_targetBgm!);
      return;
    }
    _bgmIsPlaying = true;
    try {
      _bgmPlayer?.resume().catchError((_) {});
    } catch (_) {}
  }

  /// Apply volume changes from settings
  static void updateBgmVolume() {
    if (isTestMode) return;
    try {
      if (!AppLocalizations.bgmEnabled.value) {
        pauseBgm();
      } else {
        if (_targetBgm != null) {
          playBgm(_targetBgm!);
        } else {
          resumeBgm();
        }
      }
    } catch (_) {}
  }

  /// Button press haptic feedback (Light impact)
  static void buttonHaptic() {
    if (isTestMode) return;
    try {
      if (AppLocalizations.hapticsEnabled.value) {
        HapticFeedback.lightImpact();
      }
    } catch (_) {}
  }

  /// Heavy event haptic feedback (Medium impact for damage, backstab, ougi)
  static void heavyHaptic() {
    if (isTestMode) return;
    try {
      if (AppLocalizations.hapticsEnabled.value) {
        HapticFeedback.mediumImpact();
      }
    } catch (_) {}
  }

  /// Clean disposal of all audio players
  static Future<void> dispose() async {
    _currentBgm = null;
    _targetBgm = null;
    _bgmIsPlaying = false;
    _initialized = false;
    try {
      await _bgmPlayer?.dispose();
      _bgmPlayer = null;
      for (final p in _sfxPool) {
        await p.dispose();
      }
      _sfxPool.clear();
    } catch (_) {}
  }
}
