# Ship Collision & Explosion System

## Goal
Implement instant ship destruction on unshielded collision with asteroids, featuring a retro vector fragment shatter explosion, particle burst VFX, audio impact, and safe respawn flow.

## Architecture & Visual Vision
- **Shatter Physics**: The ship's vector lines (`SHIP_SHAPE`) decouple into 4 discrete physics-driven flying wireframe segments that drift, rotate, and fade out.
- **Spark Debris Burst**: High-velocity neon green (`Color.LAWN_GREEN`) and white sparks burst outward.
- **Audio Feedback**: Heavy bass-heavy explosion sound using pitched impact stream.
- **Safe Respawn Loop**: 2-second respawn timer returning ship to center with temporary invulnerability shield.

## Tasks
- [x] Task 1: Create `effects/ship_explosion.tscn` and `scripts/ship_explosion.gd` with procedural vector line fragment debris and CPUParticles2D spark burst → Verify: Scene instantiates and animates line fragments drifting and fading.
- [x] Task 2: Update `Player/ship.gd` to handle fatal asteroid collisions, emit `ship_destroyed`, disable collision & controls, and hide sprite → Verify: Collision with asteroid triggers `ship_destroyed` without crashing.
- [x] Task 3: Update `scripts/asteroid_tests.gd` to instantiate `ship_explosion` upon `ship_destroyed` and handle safe respawn with temporary shield protection → Verify: Ship explodes on collision, particles & fragments play, and ship cleanly respawns after delay.
- [x] Task 4: Godot MCP & Verification: Configure Godot MCP binary path for `C:\Program Files\Godot\Godot_v4.2-stable_win64.exe` and verify game execution and logs → Verify: `godot.log` records clean collision and explosion sequence without errors.

## Done When
- [x] Ship is immediately destroyed when striking an asteroid without active shields.
- [x] Procedural vector debris fragments fly outward along with spark VFX and audio.
- [x] Player cleanly respawns after a delay with temporary protection.

