import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../../ui/app_localizations.dart';

class AudioService {
  static bool isTestMode = false;
  static bool _initialized = false;
  static bool _audioHardwareUnavailable = false;
  static int _retryHardwareAfterMs = 0;
  static final List<StreamSubscription<dynamic>> _eventSubs = [];

  static void _markAudioHardwareUnavailable() {
    _audioHardwareUnavailable = true;
    _retryHardwareAfterMs = DateTime.now().millisecondsSinceEpoch + 30000;
  }

  static bool _isAudioHardwareReady() {
    if (!_audioHardwareUnavailable) return true;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now >= _retryHardwareAfterMs) {
      _audioHardwareUnavailable = false;
      return true;
    }
    return false;
  }

  static void _guardPlayerStream(AudioPlayer player) {
    _eventSubs.add(
      player.eventStream.listen(
        (_) {},
        onError: (Object _, StackTrace __) {
          _markAudioHardwareUnavailable();
        },
      ),
    );
  }

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

  // Dedicated pre-loaded SFX players keyed by asset path (1 player per sound).
  // Calling setSource() ONCE per SFX prevents Android SoundPool / MediaPlayer from
  // unloading, re-extracting from the APK, and re-decoding WAVs during combat!
  static final Map<String, AudioPlayer> _sfxPlayers = {};
  static final Set<String> _sfxLoaded = {};
  static final Set<String> _sfxInFlight = {};
  static final Map<String, int> _lastSfxPlayedMs = {};
  static final Map<String, double> _lastSfxVolume = {};
  static int _lastAnySfxMs = 0;
  static int _lastHapticMs = 0;

  static const List<String> _coreSfxFiles = [
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
    sfxVictory,
    sfxGameOver,
  ];

  // Audio Cache configured with asset prefix
  static final AudioCache _audioCache = AudioCache(prefix: 'assets/audio/');

  /// Preload common SFX and initialize audio players with non-blocking audio focus
  static Future<void> init() async {
    if (isTestMode || _initialized) return;
    _initialized = true;

    try {
      AudioLogger.logLevel = AudioLogLevel.none;

      final context = AudioContextConfig(
        focus: AudioContextConfigFocus.mixWithOthers,
      ).build();

      // Configure global context so all players mix cleanly without dropping tracks
      await AudioPlayer.global
          .setAudioContext(context)
          .catchError((_) => _markAudioHardwareUnavailable());

      // Setup dedicated BGM player
      _bgmPlayer = AudioPlayer(playerId: 'kaito_bgm');
      _guardPlayerStream(_bgmPlayer!);
      _bgmPlayer!.audioCache = _audioCache;
      await _bgmPlayer!
          .setAudioContext(context)
          .catchError((_) => _markAudioHardwareUnavailable());
      await _bgmPlayer!
          .setReleaseMode(ReleaseMode.loop)
          .catchError((_) => _markAudioHardwareUnavailable());

      // Pre-create and pre-load 1 dedicated low-latency AudioPlayer per SFX in background
      // so gameplay never triggers APK extraction or SoundPool.load() on Kirin/Mali devices.
      _preloadSfxPlayersInBackground(context);
    } catch (_) {
      // Ignored in test/headless environments or PCs without an audio output device
      _markAudioHardwareUnavailable();
    }
  }

  static Future<void> _preloadSfxPlayersInBackground(
      AudioContext context) async {
    try {
      await _audioCache.loadAll(_coreSfxFiles).catchError((_) {
        _markAudioHardwareUnavailable();
        return <Uri>[];
      });
      for (int i = 0; i < _coreSfxFiles.length; i++) {
        if (!_isAudioHardwareReady() || !_initialized) return;
        final sfxFile = _coreSfxFiles[i];
        final p = AudioPlayer(playerId: 'kaito_sfx_$i');
        _guardPlayerStream(p);
        p.audioCache = _audioCache;
        _sfxPlayers[sfxFile] = p;
        try {
          await p.setAudioContext(context);
          await p.setPlayerMode(PlayerMode.lowLatency);
          await p.setReleaseMode(ReleaseMode.stop);
          await p.setSource(AssetSource(sfxFile));
          _sfxLoaded.add(sfxFile);
        } catch (_) {
          _markAudioHardwareUnavailable();
          return;
        }
      }
    } catch (_) {
      _markAudioHardwareUnavailable();
    }
  }

  /// Play a sound effect using its pre-loaded dedicated AudioPlayer (zero re-decoding)
  static void playSfx(String sfxFile, {double volume = 1.0}) {
    if (isTestMode) return;
    if (!AppLocalizations.sfxEnabled.value) return;
    if (!_isAudioHardwareReady()) return;

    try {
      final vol = (AppLocalizations.sfxVolume.value * volume).clamp(0.0, 1.0);
      if (vol <= 0.001) return;

      // Drop overlapping calls if this SFX is still awaiting native JNI response
      // or if >= 3 SFX calls are simultaneously in flight (protects Kirin 710F audio thread).
      if (_sfxInFlight.contains(sfxFile) || _sfxInFlight.length >= 3) return;

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if ((nowMs - _lastAnySfxMs) < 24) return;
      final lastMs = _lastSfxPlayedMs[sfxFile];
      if (lastMs != null && (nowMs - lastMs) < 88) return;

      final player = _sfxPlayers[sfxFile];
      if (player == null || !_sfxLoaded.contains(sfxFile)) return;

      _lastAnySfxMs = nowMs;
      _lastSfxPlayedMs[sfxFile] = nowMs;
      _sfxInFlight.add(sfxFile);

      final prevVol = _lastSfxVolume[sfxFile];
      final needVolUpdate = prevVol == null || (prevVol - vol).abs() > 0.04;
      if (needVolUpdate) {
        _lastSfxVolume[sfxFile] = vol;
      }

      Future<void> trigger() async {
        try {
          if (needVolUpdate) {
            await player.setVolume(vol);
          }
          await player.stop();
          await player.resume();
        } catch (_) {
          _markAudioHardwareUnavailable();
        } finally {
          _sfxInFlight.remove(sfxFile);
        }
      }

      trigger();
    } catch (_) {
      _sfxInFlight.remove(sfxFile);
      _markAudioHardwareUnavailable();
    }
  }

  /// Play a looping background music track seamlessly with dedicated player
  static void playBgm(String bgmFile, {double volume = 1.0}) {
    if (isTestMode) return;
    _targetBgm = bgmFile;

    if (!AppLocalizations.bgmEnabled.value) {
      stopBgm();
      return;
    }
    if (!_isAudioHardwareReady()) return;

    try {
      final vol = (AppLocalizations.bgmVolume.value * volume).clamp(0.0, 1.0);
      if (_bgmPlayer == null) return;

      if (_currentBgm == bgmFile && _bgmIsPlaying) {
        _bgmPlayer!.setVolume(vol).catchError((_) {
          _markAudioHardwareUnavailable();
        });
        return;
      }

      _currentBgm = bgmFile;
      _bgmIsPlaying = true;

      _bgmPlayer!.stop().then((_) async {
        if (_currentBgm != bgmFile || !_isAudioHardwareReady()) return;
        await _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
        await _bgmPlayer!.setVolume(vol);
        await _bgmPlayer!.play(
          AssetSource(bgmFile),
          volume: vol,
          mode: PlayerMode.mediaPlayer,
        );
      }).catchError((_) {
        _markAudioHardwareUnavailable();
      });
    } catch (_) {
      _markAudioHardwareUnavailable();
    }
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
    if (!_isAudioHardwareReady()) return;
    if (_currentBgm == null && _targetBgm != null) {
      playBgm(_targetBgm!);
      return;
    }
    _bgmIsPlaying = true;
    try {
      _bgmPlayer?.resume().catchError((_) {
        _markAudioHardwareUnavailable();
      });
    } catch (_) {
      _markAudioHardwareUnavailable();
    }
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

  /// Button press haptic feedback (Light impact, throttled for low-end mobile SoCs)
  static void buttonHaptic() {
    if (isTestMode) return;
    try {
      if (AppLocalizations.hapticsEnabled.value) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - _lastHapticMs < 65) return;
        _lastHapticMs = now;
        HapticFeedback.lightImpact();
      }
    } catch (_) {}
  }

  /// Heavy event haptic feedback (Medium impact for damage, backstab, ougi)
  static void heavyHaptic() {
    if (isTestMode) return;
    try {
      if (AppLocalizations.hapticsEnabled.value) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - _lastHapticMs < 65) return;
        _lastHapticMs = now;
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
    _audioHardwareUnavailable = false;
    _sfxLoaded.clear();
    _sfxInFlight.clear();
    _lastSfxVolume.clear();
    try {
      for (final sub in _eventSubs) {
        await sub.cancel();
      }
      _eventSubs.clear();
      await _bgmPlayer?.dispose();
      _bgmPlayer = null;
      for (final p in _sfxPlayers.values) {
        await p.dispose();
      }
      _sfxPlayers.clear();
    } catch (_) {}
  }
}
