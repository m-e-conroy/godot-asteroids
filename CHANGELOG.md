# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.5.0] - 2026-11-12

### Added
- **Wave Mutators & Cosmic Hazards (`Enemies/Hazards/`, `scripts/null_sector.gd`)**:
  - **Comet (`comet.tscn`, `comet.gd`)**: High-velocity icy vector streak with ion tail and frost sparks; limited to one active comet at a time, mutually destroys asteroids on impact, and shatters for `+500` pts + guaranteed power-up when shot down (`8` HP).
  - **Pulsar (`pulsar.tscn`, `pulsar.gd`)**: Rotating neutron star cycling through cooldown, dashed telegraph warning, and sweeping twin plasma beams.
  - **Black Hole (`black_hole.tscn`, `black_hole.gd`)**: Gravitational singularity with swirling accretion disk warping ship, bullet, and asteroid trajectories.
  - **Wave Mutator System & HUD Banner (`ui/hud.tscn`, `scripts/hud.gd`, `scripts/audio_manager.gd`)**: Wave 2+ anomaly rotation (`GRAVITY WELL`, `PULSAR CORE`, `COMET TRANSIT`, `DRONE SWARM`, `HYPER-DRIFT`) with animated banner, persistent status badge, and synth alert cue.
- **Synthesized Arcade Explosions (`scripts/audio_manager.gd`)**:
  - Pre-synthesized `explosion_small_stream` and `explosion_big_stream` (`AudioStreamWAV`) using sweeping low-pass filtered noise, sub-bass punch, and `tanh` saturation, wired across asteroids, ship deaths, saucers, comets, and bosses.
- **Welcome Screen Intel Browser Card 4 (`ui/attract_carousel.gd`)**:
  - Added Sector Anomalies & Wave Mutators dossier card with animated vector icons.

### Fixed
- **Welcome Screen Threat Dossier Alignment (`ui/attract_carousel.gd`)**:
  - Centered the two-column Threat Dossier & Bounties layout symmetrically around `center.x`.

## [1.4.0] - 2026-11-12

### Added
- **Procedural Arcade Synth Audio (`scripts/audio_manager.gd`)**:
  - Rising-tempo 2-note bass heartbeat synced to remaining wave asteroids.
  - Synthesized power-up arpeggio chimes, 10,000-pt extra life fanfare, EMP shockwave sub-bass sweep, wave clear, and game over cues.
- **Tactical Pause Menu (`ui/pause_menu.tscn`, `scripts/pause_menu.gd`)**:
  - Triggered with `P` or `ESC` during active gameplay.
  - Includes Master Audio Volume slider, CRT Scanlines toggle, Resume, Restart Sector, and Return to Briefing.
- **Combo Multiplier & Floating Score Popups**:
  - Kill-chain multiplier (`x1`–`x8`) with `3.5s` decay window and HUD badge (`scripts/score_manager.gd`, `scripts/hud.gd`).
  - Floating vector score popups (`effects/floating_score.gd`) at impact coordinates.
- **Rule-Based Procedural Boss Battles (Every 5 Waves)**:
  - Dynamically generated vector bosses (`Enemies/Boss/procedural_boss.gd`) with randomized radial symmetry (`3–8` arms), rotating shield arcs, tier-scaled HP/speed/bounty, and multi-pattern attack decks (Radial Spirals, Aimed Volleys, Escort Drone Deployment, and Telegraphed Lance Bursts).
  - Top-center Boss Health Bar in HUD.

### Changed
- **Main Scene Migration**: Moved primary game entry point from `asteroid_tests.tscn` to `Null_Sector.tscn` (`scripts/null_sector.gd`).
- **Loosened Ship Handling**: Relaxed `SPACE_DECELERATION_TIME` (`8.5s`) and `ROTATION_STABILIZATION` (`12.0`) in `Player/ship.gd` for smoother, less sticky space drift.

## [1.3.0] - 2026-11-12

### Added
- **CRT, Nebula & Combat VFX Polish Pass**:
  - **CRT Shader & HDR Bloom**: Added `effects/crt_overlay.gdshader` (scanlines, subtle chromatic aberration, phosphor bloom, and vignette) plus `WorldEnvironment` additive glow.
  - **Drifting Nebula & Space Dust Void**: Procedural multi-layered nebula clouds and parallax space dust motes (`effects/nebula_background.gd`) that drift and react to ship velocity.
  - **Trauma-Based Camera Shake**: Added `scripts/camera_shake.gd` triggered by asteroid splits, enemy kills, EMP blasts, and ship destruction.
  - **Shattering Vector Shrapnel**: Added `effects/vector_shrapnel.gd` spawning spinning, fading wireframe shards on all asteroid and enemy explosions.
  - **Glowing Laser Bolts & Plasma Thrusters**: Upgraded `scripts/bullet.gd` with phosphor laser tails and `Player/shipSprite.gd` with flickering dual-layer plasma plumes and RCS puffs.
- **Project Rebrand & Title: NULL SECTOR**:
  - Rebranded project to **`NULL SECTOR`** (*Tactical Vector Defense // Deep Space Intercept*).
  - Updated `project.godot` application title.
- **Arcade Welcome Screen & Attract Mode**:
  - Procedural dual-stroke vector **`NULL SECTOR`** hero logo component (`ui/vector_logo.gd`) featuring razor-thin hot white core, green phosphor blooming halo, and harmonic breathing glow.
  - 3-Card Cycling Attract Dossier (`ui/attract_carousel.gd`):
    - *Card 1: Threat Dossier & Bounties* with rotating vector miniatures of Asteroids (20–150 pts), Sentry Probes (150 pts), Hunter Drones (250 pts), Alien Saucers (300 pts), and bonus extra life at 10,000 pts.
    - *Card 2: Flight & Defense Manual* with ship wireframe blueprint and callout brackets for Thrust (`W/▲`), Gyro Steering (`A/D/◄►`), Pulse Lasers (`SPACE`), and Force Field (`S/▼`).
    - *Card 3: Tactical Ordnance & Power-Ups* detailing Triple Shot, Rapid Fire, EMP Shockwave, and Shield Overcharge.
    - Cycles automatically every 6.0s or manually via `◄ / ►`, `A / D`, or `Tab` with page indicator pips.
  - Top Telemetry bar with 6-digit persistent all-time high score, arcade coin-op status (`FREE PLAY`), and Sector 0-Null mission tag.
  - High-visibility pulsing launch prompt (`PRESS ENTER OR 'R' TO LAUNCH`).
- **Hyperspace Warp & State Machine Architecture**:
  - Implemented `STATE_WELCOME` -> `STATE_PLAYING` -> `STATE_GAMEOVER` in `scripts/asteroid_tests.gd`.
  - Ambient drifting asteroids populate the background during attract mode.
  - 0.35s radial hyperspace warp transition seamlessly clears the welcome screen and initializes the player at screen center with protective shield flare.
  - Pressing `ESC` during Game Over returns cleanly to the Welcome Screen, or automatically returns after 10 seconds of inactivity with a live countdown.
- **Retro Digital Clock HUD System**:
  - Procedural 7-segment digital display (`ui/digital_display.gd`) featuring bright phosphor green lit numerals and faint unlit ghost segments (`888888`), customizable slant, thickness, and zero-padding.
  - Top Bar displaying lives, 6-digit score, 6-digit persistent high score, and 2-digit wave counter.
  - Bottom Bar widgets for Force Field shield readiness/active/recharge state and active weapon buff duration (Triple Shot / Rapid Fire).
  - Wave announcement banner animating on new waves (`"WAVE 01"`).
- **Miniature Vector Ship Lives Display**:
  - Procedural wireframe ship icons (`ui/lives_display.gd`) showing remaining lives (`▲ ▲ ▲`).
  - Starts with 3 lives; decrements on ship destruction.
- **Scoring & Game State Architecture**:
  - Centralized `ScoreManager` (`scripts/score_manager.gd`) tracking real-time score, persistent high-score (`user://highscore.save`), current lives, and waves.
  - Scoring point table: Large Asteroid (20 pts), Medium (50 pts), Small (100 pts), Extra Small (150 pts), Alien Saucer (300 pts), Hunter Drone (250 pts), Sentry Probe (150 pts), Power-Up Pickups (100 pts).
  - Extra bonus life awarded every 10,000 points with audio and visual feedback.
- **Classic Arcade "GAME OVER" Loop**:
  - Full-screen Game Over overlay triggered at 0 lives, revealing final score, wave reached, and high-score notices.
  - Decoupled restart key from `Spacebar` (fire key) to `Enter` or `'R'` key with a 1.0s input buffer to prevent accidental skipping while shooting.
  - Flashing retro "PRESS ENTER OR 'R' TO PLAY AGAIN" prompt.
  - Pressing Enter or R cleanly reboots entities, resets score/lives to 3, and launches Wave 1.

## [1.2.0] - 2026-11-12

### Added
- **Alien Saucer Enemy**:
  - Horizontal cruising flight with sinusoidal vertical bobbing.
  - Active asteroid avoidance steering system.
  - Aimed laser firing at player (rate scales with wave progression).
  - Explodes into vector debris and drops random power-ups when destroyed or upon colliding with asteroids.
- **Deployable Enemies**:
  - **Sentry Probe (Wave 2+)**: Rotating amethyst geometric proximity mines.
  - **Hunter Drone (Wave 3+)**: Paced amber delta interceptors with homing pursuit steering.
- **Procedural Wireframe Power-Ups**:
  - **Triple Shot / Spread Fire**: Radiating vector daggers; fires 3 lasers simultaneously for 10s.
  - **Rapid Fire / Plasma Stream**: Interlocking dual chevrons; continuous rapid fire stream for 10s.
  - **EMP Shockwave Nuke**: Concentric diamond crosshair; instant radial clearing shockwave.
  - **Shield Overcharge Battery**: Rotating hexagonal energy capsule; restores Force Field to 100% READY.
- **Audio Integration**:
  - `sounds/explosion.wav` now plays for player ship and alien saucer destruction.
- **Player Visual Buffs**:
  - Gold wing stabilizer fins and triple nozzles for Triple Shot.
  - Animated magenta lightning chevrons for Rapid Fire.

### Fixed
- **Asteroid Speed Runaway**: Capped asteroid maximum velocity and spin in `_integrate_forces` to prevent physics catapulting on respawn.
- **Respawn Safe Clearance**: Respawn now clears a 160px safe zone around the screen center and keeps the ship's collision disabled during the 2-second invulnerability flicker.
- **Spread Fire Self-Collision**: Separated triple-shot muzzle positions and configured bullet collision masks so player bullets never collide with each other.

### Changed
- **Pure Inertial Flight Model**:
  - Capped maximum ship velocity to `320.0 px/s`.
  - Added smooth passive deceleration over ~5 seconds.
  - Added 0.15s auto-stabilization on rotational inertia to eliminate endless over-steering.
  - Removed legacy hardcoded friction overrides.

