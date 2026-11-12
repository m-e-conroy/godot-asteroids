# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

