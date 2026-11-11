import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import '../../ui/app_localizations.dart';

class AudioService {
  static bool isTestMode = false;
  static String? _currentBgm;

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

  /// Preload common SFX to ensure instantaneous playback without initial disk latency
  static Future<void> init() async {
    if (isTestMode) return;
    try {
      await FlameAudio.audioCache.loadAll([
        sfxClick,
        sfxStart,
        sfxSlash,
        sfxJump,
        sfxDash,
        sfxKunaiThrow,
        sfxEnemyHit,
        sfxEnemyDefeat,
      ]);
    } catch (_) {
      // Ignored in headless/test environments
    }
  }

  /// Play a sound effect with volume and settings scaling
  static void playSfx(String sfxFile, {double volume = 1.0}) {
    if (isTestMode) return;
    if (!AppLocalizations.sfxEnabled.value) return;

    try {
      final vol = (AppLocalizations.sfxVolume.value * volume).clamp(0.0, 1.0);
      if (vol <= 0.001) return;
      FlameAudio.play(sfxFile, volume: vol);
    } catch (_) {}
  }

  /// Play a looping background music track seamlessly
  static void playBgm(String bgmFile, {double volume = 1.0}) {
    if (isTestMode) return;
    _currentBgm = bgmFile;

    if (!AppLocalizations.bgmEnabled.value) return;

    try {
      final vol = (AppLocalizations.bgmVolume.value * volume).clamp(0.0, 1.0);
      FlameAudio.bgm.play(bgmFile, volume: vol);
    } catch (_) {}
  }

  /// Stop current BGM
  static void stopBgm() {
    if (isTestMode) return;
    try {
      _currentBgm = null;
      FlameAudio.bgm.stop();
    } catch (_) {}
  }

  /// Pause current BGM (e.g. during pause overlay)
  static void pauseBgm() {
    if (isTestMode) return;
    try {
      FlameAudio.bgm.pause();
    } catch (_) {}
  }

  /// Resume current BGM
  static void resumeBgm() {
    if (isTestMode) return;
    if (!AppLocalizations.bgmEnabled.value) return;
    try {
      FlameAudio.bgm.resume();
    } catch (_) {}
  }

  /// Apply volume changes from settings
  static void updateBgmVolume() {
    if (isTestMode) return;
    try {
      if (!AppLocalizations.bgmEnabled.value) {
        FlameAudio.bgm.pause();
      } else {
        if (_currentBgm != null) {
          playBgm(_currentBgm!);
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
}
