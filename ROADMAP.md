# NULL SECTOR — Development Roadmap

## Phase 1: Audio Polish & Pause Menu (Completed)
- [x] **Procedural Arcade Synth (`scripts/audio_manager.gd`)**:
  - Rising-tempo 2-note bass heartbeat synced to remaining wave targets.
  - Power-up pickup arpeggio chime.
  - Extra-life 10,000-pt milestone fanfare.
  - EMP Shockwave sub-bass sweep & Wave Clear / Game Over cues.
- [x] **Tactical Pause Menu (`ui/pause_menu.tscn`, `scripts/pause_menu.gd`)**:
  - Triggered with `P` or `ESC` during active gameplay (`process_mode = PROCESS_MODE_ALWAYS`).
  - Master volume / SFX toggle & CRT Overlay toggle.
  - Resume, Restart Mission, and Return to Briefing actions.

## Phase 2: Procedural Bosses & Combo Multiplier (Completed)
- [x] **Combo Multiplier & Floating Score Popups**:
  - Dynamic kill chain multiplier (`x1`–`x8`) with decay timer in HUD.
  - Floating vector score popups (`+300 x4`) at impact coordinates.
- [x] **Rule-Based Procedural Boss Generator (Every 5 Waves)**:
  - Modular vector hull assembler (core, rotating shield segments, wing turrets).
  - Wave-scaled attack patterns (sweeping laser beams, bullet curtains, drone bays).
  - Dedicated Boss HP bar in HUD.

## Phase 3: Wave Mutators & Cosmic Hazards (Completed)
- [x] **Comet**: High-velocity icy vector streak crossing the sector with debris tail.
- [x] **Pulsar**: Rotating neutron star emitting periodic sweeping energy beams.
- [x] **Black Hole**: Gravitational singularity warping ship, bullet, and asteroid trajectories.
- [x] **Wave Mutator Banner**: Announces active sector anomalies (e.g., `ANOMALY: GRAVITY WELL`, `ALERT: DRONE SWARM`).
