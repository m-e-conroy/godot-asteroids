# HUD, Scoring System & Game Over Plan

## Goal
Implement a retro digital clock (7-segment) HUD, scoring manager, lives display, and classic Game Over screen in Godot 4.2.

## Design Thesis & Aesthetic
- **Digital Clock Aesthetic**: 7-segment digital display with bright phosphor green lit segments and faint ghost unlit segments (classic 80s VFD/LED alarm clock & arcade cabinet look).
- **Lives Display**: Crisp miniature vector player ships (`▲ ▲ ▲`) drawn in neon lawn green.
- **Color Coding**:
  - Score & Wave: Digital Phosphor Green (`Color(0.16, 0.94, 0.0)`)
  - Shield Status: Electric Cyan (`Color(0.25, 0.75, 1.0)`)
  - Active Weapon Buffs: Golden Amber / Hot Magenta
  - Game Over Alert: Warning Red / Neon Green
- **Scoring Breakdown**:
  - Large Asteroid: 20 pts
  - Medium Asteroid: 50 pts
  - Small Asteroid: 100 pts
  - Extra Small Asteroid: 150 pts
  - Alien Saucer: 300 pts
  - Sentry Probe: 150 pts
  - Hunter Drone: 250 pts
  - Power-Up: 100 pts
  - Bonus Life: Awarded every 10,000 points

## Tasks
- [x] Task 1: Create Procedural 7-Segment Digital Display Component (`ui/digital_display.gd`) → Verify: Displays arbitrary numbers with realistic lit/unlit digital clock segments.
- [x] Task 2: Create Score & Game State Manager (`scripts/score_manager.gd`) → Verify: Tracks score, high score (saved to disk), 3 lives, bonus life thresholds, and emits update signals.
- [x] Task 3: Build Vector Wireframe HUD CanvasLayer (`ui/hud.tscn`, `scripts/hud.gd`) → Verify: Displays score, high score, lives ship icons, wave counter, shield status, and active weapon timer.
- [x] Task 4: Hook Scoring Triggers to Asteroids, Saucers, Drones, Probes, and Pickups → Verify: Destroying any entity awards the designated points and updates the HUD in real-time.
- [x] Task 5: Build Classic "GAME OVER" Overlay (`ui/hud.tscn`, `scripts/hud.gd`) → Verify: Triggers when lives reach 0, displays final score & high score, and restarts on Enter or R after 1s buffer.
- [x] Task 6: Integrate HUD and Game Over into Main Scene (`asteroid_tests.tscn`, `scripts/asteroid_tests.gd`) → Verify: Full gameplay loop from start, scoring, wave advancement, life loss, and restart works seamlessly.

## Done When
- [x] HUD displays score, high score, wave, and lives using 7-segment digital clock style.
- [x] Lives counter renders miniature vector ships and decrements on death.
- [x] Scoring awards points for all enemies/asteroids with extra lives every 10,000 pts.
- [x] Game Over screen triggers at 0 lives and restarts game on Enter or R key (buffered).

