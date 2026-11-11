// ignore_for_file: avoid_print, unused_local_variable
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  print('=== KAITO ADVENTURE PROCEDURAL AUDIO GENERATOR ===');
  final gen = AudioGenerator();
  gen.generateAll();
  print('=== ALL AUDIOS GENERATED SUCCESSFULLY ===');
}

class AudioGenerator {
  static const int sampleRate = 22050; // Standard 22.05kHz 16-bit mono: clean, compact, instant load

  void generateAll() {
    final sfxDir = 'assets/audio/sfx';
    final bgmDir = 'assets/audio/bgm';
    Directory(sfxDir).createSync(recursive: true);
    Directory(bgmDir).createSync(recursive: true);

    print('Generating UI & Combat SFX...');
    _saveWav('$sfxDir/ui_click.wav', _genUiClick());
    _saveWav('$sfxDir/ui_start.wav', _genUiStart());
    _saveWav('$sfxDir/slash.wav', _genSlash());
    _saveWav('$sfxDir/slash_heavy.wav', _genSlashHeavy());
    _saveWav('$sfxDir/jump.wav', _genJump());
    _saveWav('$sfxDir/dash.wav', _genDash());
    _saveWav('$sfxDir/kunai_throw.wav', _genKunaiThrow());
    _saveWav('$sfxDir/kunai_hit.wav', _genKunaiHit());
    _saveWav('$sfxDir/enemy_hit.wav', _genEnemyHit());
    _saveWav('$sfxDir/enemy_defeat.wav', _genEnemyDefeat());
    _saveWav('$sfxDir/player_hurt.wav', _genPlayerHurt());
    _saveWav('$sfxDir/player_death.wav', _genPlayerDeath());
    _saveWav('$sfxDir/parry_counter.wav', _genParryCounter());
    _saveWav('$sfxDir/backstab_pierce.wav', _genBackstabPierce());
    _saveWav('$sfxDir/ougi_charge.wav', _genOugiCharge());
    _saveWav('$sfxDir/ougi_release.wav', _genOugiRelease());
    _saveWav('$sfxDir/boss_roar.wav', _genBossRoar());
    _saveWav('$sfxDir/pickup_coin.wav', _genPickupCoin());
    _saveWav('$sfxDir/victory.wav', _genVictoryFanfare());
    _saveWav('$sfxDir/game_over.wav', _genGameOverSting());

    print('Generating Seamless Japanese Shinobi BGM Loops...');
    _saveWav('$bgmDir/bgm_menu.wav', _genMenuBgm());
    _saveWav('$bgmDir/bgm_stage.wav', _genStageBgm());
    _saveWav('$bgmDir/bgm_boss.wav', _genBossBgm());
  }

  void _saveWav(String path, List<double> samples) {
    final numSamples = samples.length;
    final byteData = ByteData(44 + numSamples * 2);

    // RIFF
    byteData.setUint8(0, 0x52);
    byteData.setUint8(1, 0x49);
    byteData.setUint8(2, 0x46);
    byteData.setUint8(3, 0x46);
    byteData.setUint32(4, 36 + numSamples * 2, Endian.little);

    // WAVE
    byteData.setUint8(8, 0x57);
    byteData.setUint8(9, 0x41);
    byteData.setUint8(10, 0x56);
    byteData.setUint8(11, 0x45);

    // fmt 
    byteData.setUint8(12, 0x66);
    byteData.setUint8(13, 0x6D);
    byteData.setUint8(14, 0x74);
    byteData.setUint8(15, 0x20);
    byteData.setUint32(16, 16, Endian.little); // Subchunk1Size
    byteData.setUint16(20, 1, Endian.little);  // PCM
    byteData.setUint16(22, 1, Endian.little);  // Mono
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
    byteData.setUint16(32, 2, Endian.little);  // BlockAlign
    byteData.setUint16(34, 16, Endian.little); // BitsPerSample

    // data
    byteData.setUint8(36, 0x64);
    byteData.setUint8(37, 0x61);
    byteData.setUint8(38, 0x74);
    byteData.setUint8(39, 0x61);
    byteData.setUint32(40, numSamples * 2, Endian.little);

    for (int i = 0; i < numSamples; i++) {
      final s = (samples[i].clamp(-1.0, 1.0) * 32767).round().clamp(-32768, 32767);
      byteData.setInt16(44 + i * 2, s, Endian.little);
    }

    final file = File(path);
    file.writeAsBytesSync(byteData.buffer.asUint8List());
    print('  ✓ Saved $path (${(file.lengthSync() / 1024).toStringAsFixed(1)} KB)');
  }

  // ===================== SFX GENERATORS =====================

  /// UI Click: Snappy cartoon Japanese woodblock tap (50ms)
  List<double> _genUiClick() {
    const duration = 0.055;
    final totalSamples = (duration * sampleRate).toInt();
    final out = List<double>.filled(totalSamples, 0.0);
    final rnd = Random(42);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final env = exp(-t * 95.0);
      final freq = 880.0 * (1.0 - t * 6.0).clamp(0.2, 1.0);
      final tone = sin(2 * pi * freq * t) + 0.4 * sin(4 * pi * freq * t);
      final clickNoise = (rnd.nextDouble() * 2 - 1) * exp(-t * 320.0);
      out[i] = (tone * 0.75 + clickNoise * 0.25) * env * 0.85;
    }
    return out;
  }

  /// UI Start: Resonant Japanese hyoshigi clapper + taiko thump (420ms)
  List<double> _genUiStart() {
    const duration = 0.42;
    final totalSamples = (duration * sampleRate).toInt();
    final out = List<double>.filled(totalSamples, 0.0);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      // Hyoshigi wood crack (high resonant frequency)
      final woodEnv = exp(-t * 32.0);
      final wood = sin(2 * pi * 1280.0 * t) + 0.5 * sin(2 * pi * 2560.0 * t);

      // Low Taiko body boom
      final taikoEnv = exp(-t * 9.0);
      final taikoFreq = 160.0 * exp(-t * 18.0) + 55.0;
      final taiko = sin(2 * pi * taikoFreq * t);

      out[i] = (wood * woodEnv * 0.45 + taiko * taikoEnv * 0.65) * 0.90;
    }
    return out;
  }

  /// Katana Slash: Crisp anime steel slice swoosh + ringing blade (190ms)
  List<double> _genSlash() {
    const duration = 0.22;
    final totalSamples = (duration * sampleRate).toInt();
    final out = List<double>.filled(totalSamples, 0.0);
    final rnd = Random(1337);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      // Noise swoosh envelope: quick attack, fast release
      final swooshEnv = sin(pi * (t / duration).clamp(0.0, 1.0));
      final noise = (rnd.nextDouble() * 2 - 1);
      // Steel ring tone (2400Hz dropping to 1600Hz)
      final ringEnv = exp(-t * 18.0);
      final ring = sin(2 * pi * (2350.0 - t * 2500.0) * t) +
          0.3 * sin(2 * pi * 3600.0 * t);

      out[i] = (noise * swooshEnv * 0.60 + ring * ringEnv * 0.40) * 0.92;
    }
    return out;
  }

  /// Heavy Slash: Meaty critical slice with sub-bass cut (280ms)
  List<double> _genSlashHeavy() {
    const duration = 0.28;
    final totalSamples = (duration * sampleRate).toInt();
    final out = List<double>.filled(totalSamples, 0.0);
    final rnd = Random(2024);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final swoosh = sin(pi * (t / duration).clamp(0.0, 1.0)) * (rnd.nextDouble() * 2 - 1);
      final heavyRing = sin(2 * pi * (1450.0 - t * 1800.0) * t) * exp(-t * 14.0);
      final bassThump = sin(2 * pi * (95.0 - t * 120.0) * t) * exp(-t * 16.0);

      out[i] = (swoosh * 0.45 + heavyRing * 0.35 + bassThump * 0.50) * 0.95;
    }
    return out;
  }

  /// Jump: Cartoon springy ninja leap (170ms)
  List<double> _genJump() {
    const duration = 0.17;
    final totalSamples = (duration * sampleRate).toInt();
    final out = List<double>.filled(totalSamples, 0.0);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final env = sin(pi * (t / duration).clamp(0.0, 1.0));
      // Rising pitch from 240Hz to 680Hz
      final freq = 240.0 + (t / duration) * 440.0;
      final tone = sin(2 * pi * freq * t) + 0.25 * sin(4 * pi * freq * t);
      out[i] = tone * env * 0.85;
    }
    return out;
  }

  /// Dash: Swift air-cutter shadow dash whoosh (210ms)
  List<double> _genDash() {
    const duration = 0.21;
    final totalSamples = (duration * sampleRate).toInt();
    final out = List<double>.filled(totalSamples, 0.0);
    final rnd = Random(999);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final env = sin(pi * pow(t / duration, 0.65).clamp(0.0, 1.0));
      final noise = (rnd.nextDouble() * 2 - 1);
      final windTone = sin(2 * pi * (480.0 - t * 800.0) * t);
      out[i] = (noise * 0.70 + windTone * 0.30) * env * 0.88;
    }
    return out;
  }

  /// Kunai Throw: Whistling steel projectile throw (130ms)
  List<double> _genKunaiThrow() {
    const duration = 0.13;
    final totalSamples = (duration * sampleRate).toInt();
    final out = List<double>.filled(totalSamples, 0.0);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final env = exp(-t * 24.0);
      // Modulated whistling spin
      final mod = sin(2 * pi * 35.0 * t);
      final freq = 1750.0 + mod * 280.0 - t * 2500.0;
      final tone = sin(2 * pi * freq * t);
      out[i] = tone * env * 0.80;
    }
    return out;
  }

  /// Kunai Hit: Metallic spark & wall thud (150ms)
  List<double> _genKunaiHit() {
    const duration = 0.15;
    final totalSamples = (duration * sampleRate).toInt();
    final out = List<double>.filled(totalSamples, 0.0);
    final rnd = Random(77);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final spark = sin(2 * pi * 2700.0 * t) * exp(-t * 45.0) +
          0.5 * sin(2 * pi * 3950.0 * t) * exp(-t * 60.0);
      final thud = (rnd.nextDouble() * 2 - 1) * exp(-t * 85.0);
      out[i] = (spark * 0.70 + thud * 0.30) * 0.88;
    }
    return out;
  }

  /// Enemy Hit: Comic book punch impact BAM! (150ms)
  List<double> _genEnemyHit() {
    const duration = 0.15;
    final totalSamples = (duration * sampleRate).toInt();
    final out = List<double>.filled(totalSamples, 0.0);
    final rnd = Random(55);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final punchFreq = 160.0 * exp(-t * 28.0) + 40.0;
      final punchTone = sin(2 * pi * punchFreq * t);
      final noiseCrack = (rnd.nextDouble() * 2 - 1) * exp(-t * 90.0);
      final env = exp(-t * 22.0);
      out[i] = (punchTone * 0.65 + noiseCrack * 0.35) * env * 0.92;
    }
    return out;
  }

  /// Enemy Defeat: Ninja smoke vanish poof (240ms)
  List<double> _genEnemyDefeat() {
    const duration = 0.24;
    final totalSamples = (duration * sampleRate).toInt();
    final out = List<double>.filled(totalSamples, 0.0);
    final rnd = Random(333);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final env = sin(pi * (t / duration).clamp(0.0, 1.0)) * exp(-t * 8.0);
      final puffNoise = (rnd.nextDouble() * 2 - 1);
      final subPoof = sin(2 * pi * (220.0 - t * 450.0) * t);
      out[i] = (puffNoise * 0.60 + subPoof * 0.40) * env * 0.85;
    }
    return out;
  }

  /// Player Hurt: Impact pain shock (200ms)
  List<double> _genPlayerHurt() {
    const duration = 0.20;
    final totalSamples = (duration * sampleRate).toInt();
    final out = List<double>.filled(totalSamples, 0.0);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final env = exp(-t * 16.0);
      // Dissonant dual tones (140Hz + 215Hz)
      final tone = sin(2 * pi * 140.0 * t) + 0.6 * sin(2 * pi * 215.0 * t);
      out[i] = tone * env * 0.88;
    }
    return out;
  }

  /// Player Death: Dramatic cartoon defeat gong & fall (1.1s)
  List<double> _genPlayerDeath() {
    const duration = 1.10;
    final totalSamples = (duration * sampleRate).toInt();
    final out = List<double>.filled(totalSamples, 0.0);
    final rnd = Random(666);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      // Low gong
      final gong = (sin(2 * pi * 90.0 * t) + 0.4 * sin(2 * pi * 178.0 * t)) * exp(-t * 3.5);
      // Comic descending slide
      final slideFreq = (380.0 - t * 240.0).clamp(50.0, 400.0);
      final slide = sin(2 * pi * slideFreq * t) * exp(-t * 4.0);
      // Ground THUD at t = 0.55s
      double thud = 0.0;
      if (t >= 0.55) {
        final dt = t - 0.55;
        thud = (sin(2 * pi * 65.0 * dt) + (rnd.nextDouble() * 2 - 1) * 0.5) * exp(-dt * 18.0);
      }
      out[i] = (gong * 0.45 + slide * 0.30 + thud * 0.70) * 0.90;
    }
    return out;
  }

  /// Parry Counter: Clashing high-carbon katana steel CLANG! (450ms)
  List<double> _genParryCounter() {
    const duration = 0.45;
    final totalSamples = (duration * sampleRate).toInt();
    final out = List<double>.filled(totalSamples, 0.0);
    final rnd = Random(1212);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final env = exp(-t * 9.5);
      final bell1 = sin(2 * pi * 2850.0 * t);
      final bell2 = sin(2 * pi * 3420.0 * t);
      final bell3 = sin(2 * pi * 1180.0 * t);
      final transient = (rnd.nextDouble() * 2 - 1) * exp(-t * 120.0);
      out[i] = (transient * 0.40 + (bell1 + bell2 * 0.7 + bell3 * 0.5) * 0.60) * env * 0.95;
    }
    return out;
  }

  /// Backstab Pierce: Piercing critical sting SHING!! (520ms)
  List<double> _genBackstabPierce() {
    const duration = 0.52;
    final totalSamples = (duration * sampleRate).toInt();
    final out = List<double>.filled(totalSamples, 0.0);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final env = exp(-t * 7.5);
      // Fast sweeping pitch upwards + crystal chime
      final sweepFreq = 700.0 + (1.0 - exp(-t * 16.0)) * 1800.0;
      final sweep = sin(2 * pi * sweepFreq * t);
      final chime = sin(2 * pi * 3150.0 * t) + 0.4 * sin(2 * pi * 4725.0 * t);
      out[i] = (sweep * 0.55 + chime * 0.45) * env * 0.95;
    }
    return out;
  }

  /// Ougi Charge: Celestial ink powerup resonance (900ms)
  List<double> _genOugiCharge() {
    const duration = 0.90;
    final totalSamples = (duration * sampleRate).toInt();
    final out = List<double>.filled(totalSamples, 0.0);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final env = pow(t / duration, 1.4);
      final vib = 1.0 + 0.05 * sin(2 * pi * 12.0 * t);
      final freq = (220.0 + (t / duration) * 440.0) * vib;
      final chord = sin(2 * pi * freq * t) +
          0.6 * sin(2 * pi * freq * 1.5 * t) +
          0.4 * sin(2 * pi * freq * 2.0 * t);
      out[i] = chord * env * 0.85;
    }
    return out;
  }

  /// Ougi Release: Massive celestial dragon ink explosion (1.25s)
  List<double> _genOugiRelease() {
    const duration = 1.25;
    final totalSamples = (duration * sampleRate).toInt();
    final out = List<double>.filled(totalSamples, 0.0);
    final rnd = Random(888);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final blastEnv = exp(-t * 3.8);
      final subBass = sin(2 * pi * (65.0 - t * 30.0) * t);
      final roarNoise = (rnd.nextDouble() * 2 - 1) * exp(-t * 5.5);
      final celestialBell = (sin(2 * pi * 1760.0 * t) + 0.5 * sin(2 * pi * 2640.0 * t)) * exp(-t * 2.2);

      out[i] = (subBass * 0.50 + roarNoise * 0.45 + celestialBell * 0.35) * blastEnv * 0.95;
    }
    return out;
  }

  /// Boss Roar: Demonic warlord battle roar (850ms)
  List<double> _genBossRoar() {
    const duration = 0.85;
    final totalSamples = (duration * sampleRate).toInt();
    final out = List<double>.filled(totalSamples, 0.0);
    final rnd = Random(404);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final env = sin(pi * (t / duration).clamp(0.0, 1.0));
      final growlMod = sin(2 * pi * 22.0 * t);
      final baseFreq = 75.0 + growlMod * 30.0;
      final saw = 2.0 * (t * baseFreq - (t * baseFreq).floor()) - 1.0;
      final noise = (rnd.nextDouble() * 2 - 1) * 0.4;
      out[i] = (saw + noise) * env * 0.90;
    }
    return out;
  }

  /// Pickup Coin / Celestial Scroll: Bright sparkling chime (260ms)
  List<double> _genPickupCoin() {
    const duration = 0.26;
    final totalSamples = (duration * sampleRate).toInt();
    final out = List<double>.filled(totalSamples, 0.0);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      // Two-note ascending bell chime (B5 -> E6)
      double tone = 0.0;
      final t1 = t;
      tone += sin(2 * pi * 987.77 * t1) * exp(-t1 * 14.0);
      if (t >= 0.08) {
        final t2 = t - 0.08;
        tone += sin(2 * pi * 1318.51 * t2) * exp(-t2 * 12.0) * 1.2;
      }
      out[i] = tone * 0.65;
    }
    return out;
  }

  /// Victory Fanfare: Triumphant Japanese taiko roll + koto arpeggio (2.6s)
  List<double> _genVictoryFanfare() {
    const duration = 2.60;
    final totalSamples = (duration * sampleRate).toInt();
    final out = List<double>.filled(totalSamples, 0.0);

    // Koto notes (D Insen scale): D4 (293.66), F4 (349.23), G4 (392.0), A4 (440.0), C5 (523.25), D5 (587.33)
    final notes = [293.66, 349.23, 392.0, 440.0, 523.25, 587.33];
    final noteTimes = [0.0, 0.22, 0.44, 0.66, 0.88, 1.15];

    for (int n = 0; n < notes.length; n++) {
      final startTime = noteTimes[n];
      final freq = notes[n];
      final startIdx = (startTime * sampleRate).toInt();

      for (int i = startIdx; i < totalSamples; i++) {
        final t = (i - startIdx) / sampleRate;
        final env = exp(-t * (n == notes.length - 1 ? 1.8 : 3.5));
        final plucked = sin(2 * pi * freq * t) +
            0.4 * sin(4 * pi * freq * t) +
            0.2 * sin(6 * pi * freq * t);
        out[i] += plucked * env * 0.32;
      }
    }

    // Taiko drum hits at 0.0s, 0.66s, 1.15s, 1.45s
    final taikoHits = [0.0, 0.66, 1.15, 1.45];
    for (final th in taikoHits) {
      final sIdx = (th * sampleRate).toInt();
      for (int i = sIdx; i < totalSamples; i++) {
        final dt = (i - sIdx) / sampleRate;
        final tEnv = exp(-dt * 6.5);
        final tTone = sin(2 * pi * (120.0 * exp(-dt * 16.0) + 50.0) * dt);
        out[i] += tTone * tEnv * 0.45;
      }
    }

    // Normalize
    for (int i = 0; i < totalSamples; i++) {
      out[i] = out[i].clamp(-1.0, 1.0) * 0.92;
    }
    return out;
  }

  /// Game Over Sting: Mournful temple bell gong + descending shakuhachi flute (2.2s)
  List<double> _genGameOverSting() {
    const duration = 2.20;
    final totalSamples = (duration * sampleRate).toInt();
    final out = List<double>.filled(totalSamples, 0.0);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      // Temple bell gong
      final gong = (sin(2 * pi * 110.0 * t) +
              0.5 * sin(2 * pi * 220.0 * t) +
              0.25 * sin(2 * pi * 330.0 * t)) *
          exp(-t * 2.2);

      // Descending sad flute
      final fluteFreq = (392.0 - t * 80.0).clamp(160.0, 440.0);
      final fluteEnv = sin(pi * (t / duration).clamp(0.0, 1.0)) * exp(-t * 1.5);
      final flute = (sin(2 * pi * fluteFreq * t) +
          0.15 * sin(4 * pi * fluteFreq * t));

      out[i] = (gong * 0.55 + flute * fluteEnv * 0.45) * 0.88;
    }
    return out;
  }

  // ===================== BGM GENERATORS =====================

  /// Menu BGM: Traditional Japanese Shinobi Courtyard (~10.66s seamless loop)
  /// Hirajoshi Pentatonic Scale in A (A, B, C, E, F)
  List<double> _genMenuBgm() {
    const bpm = 90.0;
    const beatDuration = 60.0 / bpm; // ~0.666s
    const totalBeats = 16;
    final duration = totalBeats * beatDuration; // ~10.666s
    final totalSamples = (duration * sampleRate).toInt();
    final out = List<double>.filled(totalSamples, 0.0);

    // Hirajoshi Pentatonic notes in Hz
    // A2=110, E3=164.8, A3=220, B3=246.9, C4=261.6, E4=329.6, F4=349.2, A4=440, B4=493.9, C5=523.3, E5=659.3
    const a2 = 110.0;
    const e3 = 164.81;
    const a3 = 220.0;
    const b3 = 246.94;
    const c4 = 261.63;
    const e4 = 329.63;
    const f4 = 349.23;
    const a4 = 440.0;
    const b4 = 493.88;
    const c5 = 523.25;
    const e5 = 659.25;

    // Melody: (beat, note, duration, volume)
    final melody = [
      (0.0, a4, 1.0, 0.65),
      (1.0, c5, 0.8, 0.60),
      (2.0, b4, 1.2, 0.70),
      (3.5, a4, 0.5, 0.55),
      (4.0, e4, 1.0, 0.60),
      (5.0, f4, 0.8, 0.62),
      (6.0, e4, 1.5, 0.68),
      (8.0, c4, 0.8, 0.60),
      (9.0, e4, 0.8, 0.65),
      (10.0, a4, 1.2, 0.75),
      (11.5, b4, 0.5, 0.60),
      (12.0, c5, 1.0, 0.70),
      (13.0, b4, 0.8, 0.65),
      (14.0, a4, 2.0, 0.75),
    ];

    // Synthesize Koto Plucks
    for (final note in melody) {
      final beat = note.$1;
      final freq = note.$2;
      final dur = note.$3;
      final vol = note.$4;

      final startSample = (beat * beatDuration * sampleRate).toInt();
      final lenSamples = (dur * beatDuration * 1.8 * sampleRate).toInt();

      for (int i = 0; i < lenSamples; i++) {
        final targetIdx = (startSample + i) % totalSamples;
        final t = i / sampleRate;
        final env = exp(-t * 2.8);
        final plucked = sin(2 * pi * freq * t) +
            0.45 * sin(4 * pi * freq * t) +
            0.22 * sin(6 * pi * freq * t) +
            0.12 * sin(8 * pi * freq * t);
        out[targetIdx] += plucked * env * vol * 0.28;
      }
    }

    // Synthesize Ambient Bamboo Flute (Shakuhachi) phrases
    final flutePhrases = [
      (0.5, e4, 2.5, 0.35),
      (4.5, a4, 2.8, 0.38),
      (8.5, f4, 2.5, 0.35),
      (12.5, e4, 3.0, 0.40),
    ];

    for (final fp in flutePhrases) {
      final beat = fp.$1;
      final freq = fp.$2;
      final dur = fp.$3;
      final vol = fp.$4;

      final startSample = (beat * beatDuration * sampleRate).toInt();
      final lenSamples = (dur * beatDuration * sampleRate).toInt();

      for (int i = 0; i < lenSamples; i++) {
        final targetIdx = (startSample + i) % totalSamples;
        final t = i / sampleRate;
        final env = sin(pi * (t / (dur * beatDuration)).clamp(0.0, 1.0));
        final vib = 1.0 + 0.015 * sin(2 * pi * 5.2 * t);
        final fTone = (sin(2 * pi * (freq * vib) * t) +
            0.20 * sin(4 * pi * (freq * vib) * t));
        out[targetIdx] += fTone * env * vol * 0.26;
      }
    }

    // Taiko gentle heart-beat (beats 0, 2, 4, 6, 8, 10, 12, 14)
    for (int b = 0; b < totalBeats; b += 2) {
      final startSample = (b * beatDuration * sampleRate).toInt();
      for (int i = 0; i < (beatDuration * sampleRate).toInt(); i++) {
        final targetIdx = (startSample + i) % totalSamples;
        final t = i / sampleRate;
        final tTone = sin(2 * pi * (85.0 * exp(-t * 14.0) + 42.0) * t);
        final tEnv = exp(-t * 5.5);
        out[targetIdx] += tTone * tEnv * 0.34;
      }
    }

    // Bass root notes (A2 on beats 0..7, E3 on beats 8..11, A2 on beats 12..15)
    final bassNotes = [
      (0.0, 8.0, a2),
      (8.0, 4.0, e3),
      (12.0, 4.0, a2),
    ];
    for (final bn in bassNotes) {
      final startSample = (bn.$1 * beatDuration * sampleRate).toInt();
      final lenSamples = (bn.$2 * beatDuration * sampleRate).toInt();
      final freq = bn.$3;
      for (int i = 0; i < lenSamples; i++) {
        final targetIdx = (startSample + i) % totalSamples;
        final t = i / sampleRate;
        final bTone = sin(2 * pi * freq * t) + 0.3 * sin(4 * pi * freq * t);
        final bEnv = sin(pi * (t / (bn.$2 * beatDuration)).clamp(0.0, 1.0));
        out[targetIdx] += bTone * bEnv * 0.22;
      }
    }

    // Normalize smoothly
    for (int i = 0; i < totalSamples; i++) {
      out[i] = out[i].clamp(-1.0, 1.0) * 0.88;
    }
    return out;
  }

  /// Stage BGM: High-Octane Anime Ninja Action Loop (~14.22s seamless loop)
  /// D Minor / Kumoi Pentatonic at 135 BPM
  List<double> _genStageBgm() {
    const bpm = 135.0;
    const beatDuration = 60.0 / bpm; // ~0.444s
    const totalBeats = 32;
    final duration = totalBeats * beatDuration; // ~14.22s
    final totalSamples = (duration * sampleRate).toInt();
    final out = List<double>.filled(totalSamples, 0.0);
    final rnd = Random(717);

    // Frequencies
    const d2 = 73.42;
    const d3 = 146.83;
    const f3 = 174.61;
    const g3 = 196.0;
    const a3 = 220.0;
    const bb3 = 233.08;
    const c4 = 261.63;
    const d4 = 293.66;
    const f4 = 349.23;
    const g4 = 392.0;
    const a4 = 440.0;
    const bb4 = 466.16;
    const c5 = 523.25;
    const d5 = 587.33;

    // 1. Driving Taiko Drum Kit Pattern
    for (int b = 0; b < totalBeats; b++) {
      final beatSample = (b * beatDuration * sampleRate).toInt();

      // Heavy Kick Taiko on beats 0, 2 (and 16th syncopations on 0.75, 2.5)
      final kickBeats = [0.0, 0.75, 2.0, 2.5];
      for (final kb in kickBeats) {
        final sIdx = (beatSample + (kb * beatDuration * sampleRate).toInt()) % totalSamples;
        for (int i = 0; i < (beatDuration * sampleRate).toInt(); i++) {
          final targetIdx = (sIdx + i) % totalSamples;
          final t = i / sampleRate;
          final kick = sin(2 * pi * (140.0 * exp(-t * 24.0) + 48.0) * t) * exp(-t * 9.0);
          out[targetIdx] += kick * 0.38;
        }
      }

      // Snare / Rimshot Taiko on beats 1 and 3
      final snareBeats = [1.0, 3.0];
      for (final sb in snareBeats) {
        final sIdx = (beatSample + (sb * beatDuration * sampleRate).toInt()) % totalSamples;
        for (int i = 0; i < (beatDuration * 0.8 * sampleRate).toInt(); i++) {
          final targetIdx = (sIdx + i) % totalSamples;
          final t = i / sampleRate;
          final crack = (rnd.nextDouble() * 2 - 1) * exp(-t * 26.0) * 0.45;
          final tone = sin(2 * pi * 240.0 * t) * exp(-t * 16.0) * 0.35;
          out[targetIdx] += (crack + tone) * 0.35;
        }
      }
    }

    // 2. Energetic Pumping Bassline (16th notes groove)
    final bassProgression = [
      (0, 8, d2),
      (8, 8, bb3 / 2),
      (16, 8, c4 / 2),
      (24, 8, d2),
    ];
    for (final bp in bassProgression) {
      final startBeat = bp.$1;
      final numBeats = bp.$2;
      final freq = bp.$3;

      for (int b = 0; b < numBeats; b++) {
        for (int sixteenth = 0; sixteenth < 4; sixteenth++) {
          // Play on sixteenth 0, 1, 2 (driving rhythm)
          if (sixteenth == 3) continue;
          final curBeat = startBeat + b + sixteenth * 0.25;
          final sIdx = (curBeat * beatDuration * sampleRate).toInt();
          final len = (beatDuration * 0.22 * sampleRate).toInt();

          for (int i = 0; i < len; i++) {
            final targetIdx = (sIdx + i) % totalSamples;
            final t = i / sampleRate;
            final bass = (sin(2 * pi * freq * t) + 0.35 * sin(4 * pi * freq * t)) * exp(-t * 14.0);
            out[targetIdx] += bass * 0.25;
          }
        }
      }
    }

    // 3. Fast Shamisen Ninja Melody
    final shamisenMelody = [
      // Bar 1-2 (Beats 0..7)
      (0.0, d4), (0.5, f4), (1.0, g4), (1.5, a4), (2.0, d5), (2.5, c5), (3.0, a4), (3.5, g4),
      (4.0, f4), (4.5, g4), (5.0, a4), (5.5, f4), (6.0, d4), (7.0, d4),
      // Bar 3-4 (Beats 8..15)
      (8.0, f4), (8.5, g4), (9.0, bb4), (9.5, c5), (10.0, d5), (10.5, f4), (11.0, g4), (11.5, a4),
      (12.0, bb4), (12.5, a4), (13.0, g4), (13.5, f4), (14.0, d4), (15.0, a4),
      // Bar 5-6 (Beats 16..23)
      (16.0, c5), (16.5, d5), (17.0, c5), (17.5, a4), (18.0, g4), (18.5, a4), (19.0, c5), (19.5, d5),
      (20.0, f4), (20.5, g4), (21.0, a4), (21.5, c5), (22.0, a4), (23.0, g4),
      // Bar 7-8 (Beats 24..31)
      (24.0, d4), (24.5, f4), (25.0, g4), (25.5, a4), (26.0, d5), (27.0, a4), (28.0, f4), (29.0, d4),
      (30.0, d4), (30.5, f4), (31.0, d4),
    ];

    for (final note in shamisenMelody) {
      final beat = note.$1;
      final freq = note.$2;
      final sIdx = (beat * beatDuration * sampleRate).toInt();
      final len = (beatDuration * 0.9 * sampleRate).toInt();

      for (int i = 0; i < len; i++) {
        final targetIdx = (sIdx + i) % totalSamples;
        final t = i / sampleRate;
        final env = exp(-t * 9.5);
        final pluck = sin(2 * pi * freq * t) +
            0.55 * sin(4 * pi * freq * t) +
            0.28 * sin(6 * pi * freq * t) +
            0.15 * sin(8 * pi * freq * t);
        out[targetIdx] += pluck * env * 0.26;
      }
    }

    // Normalize smoothly
    for (int i = 0; i < totalSamples; i++) {
      out[i] = out[i].clamp(-1.0, 1.0) * 0.88;
    }
    return out;
  }

  /// Boss Warlord BGM: Epic Demon Samurai Duel (~12.80s seamless loop)
  /// C Minor / Insen War Scale at 150 BPM
  List<double> _genBossBgm() {
    const bpm = 150.0;
    const beatDuration = 60.0 / bpm; // 0.400s
    const totalBeats = 32;
    final duration = totalBeats * beatDuration; // 12.80s
    final totalSamples = (duration * sampleRate).toInt();
    final out = List<double>.filled(totalSamples, 0.0);
    final rnd = Random(999);

    const c2 = 65.41;
    const eb2 = 77.78;
    const f2 = 87.31;
    const g2 = 98.0;
    const c3 = 130.81;
    const eb3 = 155.56;
    const f3 = 174.61;
    const g3 = 196.0;
    const ab3 = 207.65;
    const c4 = 261.63;
    const eb4 = 311.13;
    const f4 = 349.23;
    const g4 = 392.0;
    const ab4 = 415.30;
    const c5 = 523.25;

    // 1. War Taiko Thunderous Double-Time Drums
    for (int b = 0; b < totalBeats; b++) {
      // 16th-note rolling war taiko
      for (int s = 0; s < 4; s++) {
        final curBeat = b + s * 0.25;
        final sIdx = (curBeat * beatDuration * sampleRate).toInt();
        final isAccent = (s == 0) || (s == 2 && b % 2 == 1);

        for (int i = 0; i < (beatDuration * 0.22 * sampleRate).toInt(); i++) {
          final targetIdx = (sIdx + i) % totalSamples;
          final t = i / sampleRate;
          final kick = sin(2 * pi * (160.0 * exp(-t * 30.0) + 40.0) * t) * exp(-t * 12.0);
          final rim = (rnd.nextDouble() * 2 - 1) * exp(-t * 38.0) * (isAccent ? 0.35 : 0.12);
          out[targetIdx] += (kick * (isAccent ? 0.42 : 0.24) + rim) * 0.70;
        }
      }
    }

    // 2. Heavy Brass / Low Strings Dramatic Stabs on bar downbeats
    final brassStabs = [
      (0.0, c2, c3), (3.5, c2, c3),
      (8.0, eb2, eb3), (11.5, f2, f3),
      (16.0, g2, g3), (19.5, ab3 / 2, ab3),
      (24.0, c2, c3), (28.0, g2, g3), (30.0, c2, c3),
    ];
    for (final stab in brassStabs) {
      final beat = stab.$1;
      final fLow = stab.$2;
      final fHigh = stab.$3;
      final sIdx = (beat * beatDuration * sampleRate).toInt();
      final len = (beatDuration * 1.8 * sampleRate).toInt();

      for (int i = 0; i < len; i++) {
        final targetIdx = (sIdx + i) % totalSamples;
        final t = i / sampleRate;
        final env = exp(-t * 3.5);
        final brass = (sin(2 * pi * fLow * t) +
            0.7 * sin(2 * pi * fHigh * t) +
            0.4 * sin(4 * pi * fHigh * t) +
            0.2 * sin(6 * pi * fHigh * t));
        out[targetIdx] += brass * env * 0.30;
      }
    }

    // 3. Fast Tense War Koto Arpeggios (16th notes)
    final kotoNotes = [c4, eb4, f4, g4, ab4, g4, f4, eb4];
    for (int b = 0; b < totalBeats; b++) {
      for (int s = 0; s < 4; s++) {
        final noteIdx = (b * 4 + s) % kotoNotes.length;
        final freq = kotoNotes[noteIdx];
        final curBeat = b + s * 0.25;
        final sIdx = (curBeat * beatDuration * sampleRate).toInt();
        final len = (beatDuration * 0.24 * sampleRate).toInt();

        for (int i = 0; i < len; i++) {
          final targetIdx = (sIdx + i) % totalSamples;
          final t = i / sampleRate;
          final env = exp(-t * 18.0);
          final koto = sin(2 * pi * freq * t) + 0.4 * sin(4 * pi * freq * t);
          out[targetIdx] += koto * env * 0.18;
        }
      }
    }

    // Normalize smoothly
    for (int i = 0; i < totalSamples; i++) {
      out[i] = out[i].clamp(-1.0, 1.0) * 0.90;
    }
    return out;
  }
}
