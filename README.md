# 🥷 KAITO ADVENTURE: INK SHINOBI (墨の刃)
### *A 2D Manga / Shonen Comic Platformer Built with Flutter & Flame Engine*
<img width="1259" height="677" alt="image" src="https://github.com/user-attachments/assets/0e4e8a10-a824-4d4d-9e48-a75167230502" />
<img width="1259" height="675" alt="image" src="https://github.com/user-attachments/assets/42a190a6-1051-437c-8f8a-8f4e4c712286" />

---

## 📖 Synopsis & Visual Style
**Kaito Adventure: Ink Shinobi** immerses players directly into the living pages of a classic Japanese shonen action manga. Every screen, combat effect, interface overlay, and boss encounter is crafted with traditional comic book art techniques:
- **Halftone & Screentones**: Authentic print textures across backgrounds, clouds, and panel borders.
- **Speed & Action Lines**: Dynamic radial and horizontal concentration lines during dashes and critical slashes.
- **Dynamic Manga Sound Effects**: Stylized onomatopoeias popping right out of the battlefield (*SLASH!*, *DODODO!*, *SHINK!*, *BAM!*, *BOING!*, *ゴゴゴゴ*, *ズバッ!*).
- **Comic Prologue & Epilogue Panels**: Interactive story introduction at the start of the journey and a canonical narrative conclusion upon vanquishing the final boss.
- **Speech Balloons & Dramatic Anime Cut-Ins**: Manga cutscenes triggered during special ability executions and boss phase transitions.
- **Panel-Style HUD**: Inked heart containers, Secret Technique meter (*Ougi / 奥義*), hit combo counter, and PvP duel health bars.

---

## ⚔️ Local WiFi PvP Multiplayer (Up to 5 Players)
The game features a complete real-time local network multiplayer system with zero account creation or cloud server requirements:
- **Instant Room Discovery & Direct IP Connection**: Automatic UDP beacon room discovery across the same WiFi network, alongside direct IP join support (fully cross-compatible between Windows, Android, and Web).
- **Up to 5 Shinobis in Combat**: Jump into head-to-head 1v1 duels or chaotic up-to-5-player *Battle Royale* matches on the floating dojo arena.
- **Shinobi Customization**: Choose your custom nickname and personalize Kaito's outfit with an 8-color multiplayer palette.
- **Balanced PvP Combat Mechanics**:
  - Balanced health pool set to **300 HP** for tactical and competitive engagements.
  - Frame-accurate slash combos, projectile kunai throws, and ultimate Ougi flurry sync.
  - **Ring-Out Pitfall Hazard**: Stepping or getting knocked off the floating arena triggers an instant ring-out defeat.
  - Strict damage resolution: eliminated players are locked at 0 HP with health regeneration completely disabled.
- **Arena Celebration & Smash Bros-Style Winner Podium**:
  - 3.2-second in-arena victory celebration sequence for the champion before entering the podium.
  - Dynamic results podium spotlighting the winner with celebratory artwork and showing fallen opponents tinted with their respective custom colors.
  - **Interactive Rematch System**: A 10-second rematch countdown starts when two or more players vote ready, automatically cancelling if ready votes fall below two.

---

## 🎮 Controls

The game offers full support for both **PC Keyboard** and **On-Screen Virtual Touch Controls**:

| Action | PC Key | On-Screen Button | Description |
| :--- | :--- | :--- | :--- |
| **Move Left / Right** | `A` / `D` or `←` / `→` | `[ ◄ ]` / `[ ► ]` | Agile and responsive horizontal movement |
| **Jump / Wall Jump** | `Space` / `W` / `↑` | `[ JUMP ]` | Variable height jump and wall rebound |
| **Sword Combo** | `J` or `X` | `[ SLASH ]` | 3-hit melee combo with vibrant ink slash arcs |
| **Air Dash / Dodge** | `K` / `C` / `Shift` | `[ DASH ]` | Supersonic dodge with invulnerability frames (i-frames) |
| **Throw Kunai** | `L` or `Z` | `[ KUNAI ]` | Ranged shuriken attack with a 5-second tactical cooldown |
| **Secret Technique (奥義 Ougi)** | `U` or `V` | `[ OUGI ]` | Full-screen blade flurry unleashing 100% Spirit |
| **Pause / Menu** | `ESC` or `P` | `[ ⏸ ]` | Pauses the action to access settings or restart |

---

## 🏯 Story Mode: Chapters & Interactive Bosses

### 🌙 Chapter 1: The Inked Rooftops (*墨の屋根*)
- **Setting**: Traditional pagoda rooftops beneath a giant crescent moon, spike traps, and crumbling platforms.
- **Enemies**: Shadow ninjas wielding katanas and flying Tengu drones.
- **Boss: KUROKAGE (The Shadow Executioner)**: Smoke-bomb teleportation, shadow blade waves, and a counter posture that requires heavy combo strikes to shatter (*GUARD BREAK*).

### 🌋 Chapter 2: The Crimson Citadel (*紅蓮の城塞*)
- **Setting**: A blazing warlord fortress filled with spinning buzzsaws, spike pits, and magma vents.
- **Boss: RYU-KOTEI (The Dragon Shogun)**: Dual-shockwave seismic stomps, telegraphed flame geysers erupting from the floor, and a berserk crimson rage mode.

### 🐍 Chapter 3: The Serpentine Sanctum (*蛇神の聖域*)
- **Setting**: An underground temple covered in toxic mist and swinging platforms suspended over bottomless chasms.
- **Boss: HEBI-HIME (The Serpent Mistress)**: Serpentine lunges, homing venom spheres, and optical illusions that test player reflexes.

### ❄️ Chapter 4: The Frostfang Peak (*霜牙の頂*)
- **Setting**: Blizzard-swept mountain peaks with horizontal crosswinds and slippery ice platforms.
- **Boss: YUKI-ONI (The Frost Demon)**: Falling giant icicles, visibility-reducing blizzards, and heavy body slams.

### 🌑 Chapter 5: The Shadow Palace (*影の宮殿*)
- **Setting**: The dark heart of Neo-Tokyo featuring disappearing platforms and rhythmic switch orbs.
- **Final Boss: MUZAN-KAI (The Shadow Emperor)**: Incorporates combat techniques from all previous warlords, opening dimensional rifts and unleashing celestial ink storms.

---

## 🚀 How to Run & Play

### Option 1: Play in Web Browser (Online PWA)
Play directly in your browser with automatic landscape orientation support on mobile devices and desktop:
👉 **[kaito-adventure-beta.vercel.app](https://kaito-adventure-beta.vercel.app/)**

Or run locally in development:
```bash
flutter run -d chrome
```

### Option 2: Windows Native Desktop (PC)
Pre-built portable 64-bit release packaged in the `releases/` directory:
* Extract: `releases/Kaito-Adventure-Windows.zip`
* Run: `manga_platformer.exe`

To build from source:
```bash
flutter build windows --release
```

### Option 3: Install on Android (Optimized APKs)
Pre-compiled APK packages available in the `releases/` directory:
* **Recommended (ARM64-v8a)**: `releases/Kaito-Adventure-Android-arm64.apk` (~39 MB, optimized for modern 64-bit Android smartphones).
* **Universal**: `releases/Kaito-Adventure-Android-Universal.apk` (~72 MB, compatible with all Android architectures).

To build from source:
```bash
flutter build apk --release --split-per-abi
```

---

## 📁 Project Architecture
```
lib/
├── main.dart                          # Application entry point, orientation lock, and GameWidget mount
├── game/
│   ├── manga_game.dart                # Core Flame game loop, camera tracking, network sync & lifecycle
│   ├── cartoon_assets.dart            # Unified registry for 2D sprites, spritesheets, and animations
│   ├── components/
│   │   ├── player.dart                # Local shinobi "Kaito" (physics, 3-hit combo, scarf, Ougi & states)
│   │   ├── remote_player.dart         # Remote PvP opponent (state interpolation, aura, and nametag)
│   │   ├── manga_effects.dart         # Comic visual FX (onomatopoeia text, speed lines, slash arcs, dust)
│   │   ├── projectiles.dart           # Inked kunai (5s cooldown) and boss projectile components
│   │   ├── platform.dart              # Solid, moving, crumbling, ice, and bouncy taiko platforms
│   │   ├── traps.dart                 # Rotating buzzsaws, stationary spikes, and retractable needles
│   │   ├── collectibles.dart          # Collectible ninja scrolls, restorative ramen bowls, and Torii gates
│   │   ├── enemies/
│   │   │   ├── enemy_grunt.dart       # Ground ninja minion with '!' alert indicator and patrol AI
│   │   │   ├── enemy_drone.dart       # Flying Tengu drone with sinusoidal pathing
│   │   │   └── enemy_oni_archer.dart  # Ranged Oni archer with charged arrow attacks
│   │   └── bosses/
│   │       ├── boss_base.dart         # Abstract boss base with health bars, stun states, and phases
│   │       ├── boss_kurokage.dart     # Stage 1 Boss: Smoke teleportation and parry counter
│   │       ├── boss_ryu_kotei.dart    # Stage 2 Boss: Seismic shockwaves and floor geysers
│   │       ├── boss_hebi_hime.dart    # Stage 3 Boss: Toxic lunges and serpentine illusions
│   │       ├── boss_yuki_oni.dart     # Stage 4 Boss: Giant icicles and blizzard squalls
│   │       └── boss_muzan_kai.dart    # Final Stage Boss: Dimensional rifts and ink storm
│   ├── levels/
│   │   ├── level_one.dart             # Stage 1: The Inked Rooftops
│   │   ├── level_two.dart             # Stage 2: The Crimson Citadel
│   │   ├── level_three.dart           # Stage 3: The Serpentine Sanctum
│   │   ├── level_four.dart            # Stage 4: The Frostfang Peak
│   │   ├── level_five.dart            # Stage 5: The Shadow Palace
│   │   └── pvp_arena.dart             # Suspended PvP Arena with pitfall ring-out mechanics
│   └── services/
│       ├── audio_service.dart         # Audio engine (looping BGM, SFX pooling, and haptic feedback)
│       ├── lan_multiplayer_service.dart # Local WebSocket server, UDP broadcast, lobby and sync manager
│       ├── pwa_service.dart           # Cross-platform PWA installation helpers
│       ├── pwa_service_web.dart       # JavaScript interop for fullscreen and install prompts
│       └── pwa_service_stub.dart      # Platform fallback stub for non-web environments
└── ui/
    ├── comic_theme.dart               # Pop-art colors, comic panel borders, typography, and styles
    ├── comic_hud.dart                 # Story HUD with heart jars, combo counter, Ougi bar, and boss gauge
    ├── virtual_joystick_overlay.dart  # Responsive virtual touch controls with layout customization
    ├── main_menu_overlay.dart         # Title menu with Story, Multiplayer, and Settings navigation
    ├── chapter_select_overlay.dart    # Chapter and stage gallery with progressive unlocking
    ├── story_intro_overlay.dart       # Interactive comic book prologue depicting Kaito's origin
    ├── story_epilogue_overlay.dart    # Cinematic manga epilogue unlocked after completing the campaign
    ├── manga_cutin_overlay.dart       # Dramatic anime cut-in overlay during boss phase transitions
    ├── multiplayer_overlay.dart       # Multiplayer lobby (room list, nickname input, and color selector)
    ├── multiplayer_hud.dart           # PvP duel and battle royale HUD with 300 HP gauges
    ├── multiplayer_results_overlay.dart # Smash-style podium, victory/defeat sprites, and 10s rematch
    ├── settings_overlay.dart          # Audio volume controls, language selection, and HUD touch editor
    ├── pause_overlay.dart             # Sketchbook-styled pause menu
    ├── game_over_overlay.dart         # "To Be Continued..." defeat overlay
    └── victory_overlay.dart           # Stage completion overlay with Shinobi rank grading
```
