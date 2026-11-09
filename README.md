# 🥷 MANGA BLADE: INK SHINOBI (墨の刃)
### *Un juego de plataformas 2D estilo Manga / Shonen Cómic desarrollado con Flutter & Flame Engine*

---

## 📖 Sinopsis & Estilo Visual
**Manga Blade: Ink Shinobi** sumerge al jugador dentro de las páginas de un tomo manga japonés de acción shonen. Cada pantalla, efecto de ataque, interfaz y jefe está diseñado con técnicas gráficas de cómic tradicional:
- **Trama de Medios Tonos (Halftone / Screentones)** en fondos y paneles.
- **Líneas de Acción y Velocidad (Speed Lines / Concentration Lines)** en embestidas y ataques críticos.
- **Onomatopeyas Manga Dinámicas** (*SLASH!*, *DODODO!*, *SHINK!*, *BAM!*, *BOING!*, *ゴゴゴゴ*, *ズバッ!*).
- **Globos de Diálogo y Cut-Ins Cinemáticos** estilo cómic al activar habilidades y cambios de fase de jefes.
- **HUD tipo Viñeta** con frascos de tinta de salud, medidor de Técnica Secreta (*Ougi / 奥義*) y contador de combo.

---

## 🎮 Controles

El juego soporta tanto **Teclado (PC)** como **Controles Táctiles / Virtuales en Pantalla**:

| Acción | Tecla (PC) | Botón en Pantalla | Descripción |
| :--- | :--- | :--- | :--- |
| **Moverse Izquierda / Derecha** | `A` / `D` o `←` / `→` | `[ ◄ ]` / `[ ► ]` | Movimiento horizontal ágil |
| **Saltar / Wall Jump** | `Espacio` o `W` o `↑` | `[ JUMP ]` | Salto de altura variable y rebote en muros |
| **Combo de Espada** | `J` o `X` | `[ SLASH ]` | Combo melee de 3 golpes con arcos de tinta |
| **Dash Aéreo / Esquiva** | `K` o `C` o `Shift` | `[ DASH ]` | Desplazamiento supersónico con i-frames |
| **Lanzar Kunai** | `L` o `Z` | `[ KUNAI ]` | Ataque a distancia con proyectil shuriken |
| **Técnica Secreta (奥義 Ougi)** | `U` o `V` | `[ OUGI ]` | Ataque supremo que corta toda la pantalla (100% Espíritu) |
| **Pausa / Menú** | `ESC` o `P` | `[ ⏸ ]` | Pausa el manga y permite reiniciar o cambiar nivel |

---

## 🏯 Niveles y Jefes Interactivos

### 🌙 Capítulo 1: The Inked Rooftops (*墨の屋根*)
- **Entorno:** Tejados de pagodas tradicionales bajo una luna menguante gigante, trampas de pinchos y plataformas movedizas y quebradizas.
- **Enemigos:** Ninjas sombríos con katanas y drones Tengu aéreos que disparan agujas de tinta.
- **Jefe Interactivo 1: KUROKAGE (El Verdugo de las Sombras)**
  - **Mecánica de Guardia:** Levanta su espada en postura de contraataque. Golpear por la espalda o usar combo pesado rompe su postura (*GUARD BREAK*).
  - **Fase 1:** Teletransporte con nube de humo tras el jugador (*SHING!*) y tajos lunares.
  - **Fase 2 (Enfurecido < 50% HP):** Triggers cinemático Cut-In manga, duplica velocidad y lanza ráfagas de ondas oscuras por el suelo (*DODODO!*).

### 🌋 Capítulo 2: The Crimson Citadel (*紅蓮の城塞*)
- **Entorno:** La fortaleza ardiente del shogun, con sierras mecánicas giratorias, pozos de espinas y géiseres de fuego.
- **Jefe Interactivo 2: RYU-KOTEI (El Shogun Dragón)**
  - **Fase 1 (Dominio del Dragón):** Pisotón sísmico (*BOOM!!*) con ondas de choque dobles que requieren saltar o trepar plataformas elevadas.
  - **Fase 2 (Fragua de Magma < 66% HP):** Activa rejillas del suelo que disparan columnas de llamas telegrafiadas con `!`, y lanza esferas de energía en abanico.
  - **Fase 3 (Overdrive Final < 33% HP):** Modo berserker dorado/carmesí, embestidas ultrasónicas continuas y ráfagas devastadoras.

---

## 🚀 Cómo Ejecutar el Juego

### Opción 1: En el Navegador (Chrome / Edge)
En la terminal del proyecto (`C:\Users\Soporte\Desktop\TestGame`), ejecuta:
```bash
flutter run -d chrome
```
*(O simplemente `-d edge` para Microsoft Edge)*

### Opción 2: Probar la Build Web ya compilada
La versión de producción ya está compilada en la carpeta `build/web`. Puedes servirla instantáneamente con cualquier servidor estático local o abrirla en un navegador web.

---

## 📁 Arquitectura del Proyecto
```
lib/
├── main.dart                          # Entrada de la aplicación y montaje de Flame GameWidget
├── game/
│   ├── manga_game.dart                # Loop principal de juego, cámara, collision detection y audio/state
│   ├── components/
│   │   ├── player.dart                # Jugador shinobi "Kaito" con física, scarf dinámica, combos y estados
│   │   ├── manga_effects.dart         # Efectos visuales de cómic (onomatopeyas flotantes, speedlines, slash arcs)
│   │   ├── projectiles.dart           # Kunai de tinta, ondas oscuras, orbes y columnas de fuego
│   │   ├── platform.dart              # Plataformas sólidas, móviles, quebradizas y trampolines
│   │   ├── traps.dart                 # Pinchos y sierras circulares rotatorias
│   │   ├── collectibles.dart          # Rollos ninjas coleccionables, tazones de ramen y Torii gate
│   │   ├── enemies/
│   │   │   ├── enemy_grunt.dart       # Ninja enemigo con IA de patrulla y alerta '!'
│   │   │   └── enemy_drone.dart       # Enemigo volador Tengu con vuelo sinusoidal
│   │   └── bosses/
│   │       ├── boss_base.dart         # Clase base abstracta de bosses (barras de vida, stun/break y fases)
│   │       ├── boss_kurokage.dart     # Boss Capítulo 1 (Teletransporte, parry, ondas cortantes)
│   │       └── boss_ryu_kotei.dart    # Boss Capítulo 2 (3 fases, pisotones sísmicos, géiseres)
│   └── levels/
│       ├── level_one.dart             # Nivel 1: The Inked Rooftops
│       └── level_two.dart             # Nivel 2: The Crimson Citadel
└── ui/
    ├── comic_theme.dart               # Paleta de tinta manga, screentones, speedlines y bordes pop
    ├── comic_hud.dart                 # HUD de corazones, indicador de combo, barra de Ougi y HP de Boss
    ├── manga_cutin_overlay.dart       # Animación cinemática dramática estilo anime al cambiar de fase
    ├── virtual_joystick_overlay.dart  # Botones interactivos en pantalla con soporte táctil y ratón
    ├── chapter_select_overlay.dart    # Galería de selección de tomos/capítulos manga
    ├── pause_overlay.dart             # Menú de pausa estilo bloc de bocetos
    ├── game_over_overlay.dart         # Pantalla de derrota "To Be Continued..."
    └── victory_overlay.dart           # Pantalla de victoria con clasificación rango S
```
