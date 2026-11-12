# Force Field System

## Goal

Implement a one-tap gradient blue force field that protects the ship for 4 seconds with elastic bounce physics, features a clockwise countdown meter arc and a faint 12-second recharge ring, and pushes colliding asteroids away.

## Key Specifications

- **Controls**: Single press of `shield` action (`S` / `Down Arrow`) activates the force field (no holding required).
- **Active Duration**: Exactly 4.0 seconds. Cannot be reactivated during recharge.
- **Recharge Duration**: Exactly 12.0 seconds. Must reach 100% before next use.
- **Visuals**:
  - Radiant electric/gradient blue circle aura around ship (`SHIELD_RADIUS = 40.0`).
  - Inner thicker countdown meter ring that sweeps down clockwise like a clock over 4.0s.
  - Faint 12.0s recharge ring that sweeps up clockwise from 0° to 360°, disappearing once ready.
- **Physics**:
  - Full damage immunity while active.
  - Rebounds ship elastically: `velocity = velocity.bounce(normal) * 1.15`.
  - Applies repulsive impulse to colliding asteroids: `collider.apply_central_impulse(-normal * impulse)`.
  - Circular collision boundary (radius 40) during force field activation for zero-clipping contact.

## Tasks

- [x] Task 1: Update `Player/ship.tscn` to add circular `ForceFieldCollision` shape (radius 40) directly to the ship CharacterBody2D → Verify: Node exists and is toggled with shield state.
- [x] Task 2: Implement Force Field State Machine in `Player/ship.gd` (`READY`, `ACTIVE`, `RECHARGING`) with 4.0s countdown, 12.0s recharge, and one-tap `shield` input → Verify: Tap triggers 4s active then 12s recharge; cannot re-trigger early.
- [x] Task 3: Implement Elastic Bounce & Impulses in `Player/ship.gd` upon collision while force field is active → Verify: Ship bounces cleanly off asteroids and pushes rocks backward with zero damage.
- [x] Task 4: Implement Force Field Visuals & Dual Meters in `Player/shipSprite.gd` (gradient blue field, clockwise countdown meter, faint recharge ring) → Verify: Countdown arc shrinks clockwise over 4s; faint ring fills over 12s and vanishes.
- [x] Task 5: End-to-End Verification: Verify all timings, transitions, collision handling, and visual states in gameplay → Verify: Clean logs, accurate physics responses, and visual polish.

## Done When

- [x] Single tap of `shield` activates a vibrant gradient blue force field.
- [x] Clock-style inner countdown arc shrinks over 4.0 seconds, then shield shuts off.
- [x] Faint recharge ring sweeps clockwise over 12.0 seconds and disappears when ready.
- [x] Colliding with asteroids while field is active bounces the ship and pushes rocks back without damaging the player.
