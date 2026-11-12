# Alien Saucers, Dynamic Enemies & Wireframe Power-Ups Plan

## Goal
Implement the iconic Alien Saucer enemy (with level-scaling shooting and probe/drone deployment) that drops 4 distinct wireframe-designed power-ups upon destruction, with upgrade weapon logic on the player ship.

## Design Thesis & Aesthetic
- **Vector Wireframe Purity**: All enemies and power-ups are drawn procedurally via `_draw()` line art.
- **Color Differentiation**:
  - **Player**: Neon Lawn Green (`Color(0.16, 0.94, 0.0)`)
  - **Force Field**: Electric Cyan/Blue (`Color(0.25, 0.75, 1.0)`)
  - **Asteroids**: Dynamic Health Color (Green → Yellow → Red)
  - **Alien Saucer**: Neon Red/Magenta (`Color(1.0, 0.15, 0.4)`) with yellow canopy
  - **Hunter Drone**: Warning Amber/Orange (`Color(1.0, 0.55, 0.0)`)
  - **Sentry Probe**: Geometric Amethyst/Violet (`Color(0.8, 0.3, 1.0)`)
  - **Power-Ups**: 4 distinct non-letter wireframe geometries with custom palettes

## The 4 Wireframe Power-Up Designs
1. **Triple Shot / Spread Fire** (Golden Amber `Color(1.0, 0.8, 0.15)`):
   - Geometry: 3 divergent vector arrows/daggers radiating from a base node.
   - Effect: Fires 3 spread bullets simultaneously for 10 seconds.
2. **Rapid Fire / Plasma Stream** (Hot Magenta `Color(1.0, 0.25, 0.8)`):
   - Geometry: Interlocking dual chevrons / lightning energy bolt.
   - Effect: Eliminates firing delay, permitting continuous rapid laser streams for 10 seconds.
3. **EMP Shockwave / Nuke** (Brilliant Cyan `Color(0.2, 0.95, 1.0)`):
   - Geometry: Concentric diamond crosshair with 4 peripheral capacitor spikes.
   - Effect: Instant radial vector shockwave wiping out small asteroids, projectiles, and damaging larger targets.
4. **Force Field Overcharge Battery** (Cobalt Blue `Color(0.3, 0.7, 1.0)`):
   - Geometry: Rotating hexagonal shield capsule with an energetic pulsing core.
   - Effect: Instantly resets force field recharge to 100% READY (or adds extra duration).

## Enemy System & Level Scaling
- **Alien Saucer (`Enemies/Saucer/`)**:
  - Horizontal cruising flight with gentle sinusoidal vertical bobbing.
  - Periodic aimed lasers toward player ship (fire rate scales with level).
  - Spawns Sentry Probes (level 2+) and launches Hunter Drones (level 3+).
  - Explodes with custom vector line fragmentation upon death and drops a random Power-Up.
- **Hunter Drone (`Enemies/Drone/`)**:
  - Fast, agile angular vector dart that actively seeks and steers toward the player.
- **Sentry Probe (`Enemies/Probe/`)**:
  - Rotating geometric mine that floats in space and emits periodic pulses.

## Tasks
- [x] Task 1: Create Power-Up Scene & Wireframe Renderers (`Pickups/powerup.tscn`, `scripts/powerup.gd`) with 4 distinct geometric symbols and floating/rotation animation → Verify: All 4 power-up symbols render with proper colors and drift.
- [x] Task 2: Implement Player Power-Up State & Weapon Upgrades in `Player/ship.gd` (Triple spread shot, rapid fire, EMP blast trigger, shield recharge) → Verify: Collecting power-ups applies buffs, timers count down, and normal shooting restores.
- [x] Task 3: Create Alien Saucer Scene, AI, and Laser (`Enemies/Saucer/saucer.tscn`, `scripts/saucer.gd`, `scripts/saucer_bullet.gd`) → Verify: Saucer cruises, fires at player, takes damage, explodes into fragments, and drops power-ups.
- [x] Task 4: Create Sentry Probe & Hunter Drone Scenes (`Enemies/Probe/probe.tscn`, `Enemies/Drone/drone.tscn`) → Verify: Saucer deploys probes/drones in higher waves with active behaviors.
- [x] Task 5: Integrate Enemy Wave & Level Progression in `scripts/asteroid_tests.gd` → Verify: Saucers spawn at intervals, scale difficulty with level, and drop power-ups reliably.

## Done When
- [x] Saucers fly across the screen, targeting the player with lasers.
- [x] Destroying saucers drops one of 4 distinct wireframe power-up items.
- [x] Picking up items activates Triple Shot, Rapid Fire, EMP Blast, or Shield Overcharge.
- [x] Higher waves introduce Sentry Probes and Hunter Drones deployed by saucers.

