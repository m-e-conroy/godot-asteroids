# NULL SECTOR: Welcome Screen & Arcade Attract Mode Plan

## Goal

Implement the Welcome Screen and Arcade Attract Mode for NULL SECTOR (Godot 4.2), featuring procedural vector typography, high score telemetry, a 3-card cycling attract dossier (threats, controls, power-ups), and a seamless hyperspace transition into gameplay.

## Tasks

- [x] Task 1: Update Project Name & Metadata (`project.godot`) → Verify: Project title set to "NULL SECTOR".
- [x] Task 2: Create Procedural Vector Logo Component (`ui/vector_logo.gd`) → Verify: Draws dual-stroke vector glyphs for "NULL SECTOR" with pulse animation.
- [x] Task 3: Create 3-Card Attract Carousel Component (`ui/attract_carousel.gd`) → Verify: Renders Threat Dossier, Flight Manual with ship blueprint, and Power-Up Upgrades; auto-cycles every 6s or via arrow keys.
- [x] Task 4: Assemble Welcome Screen Scene & Controller (`ui/welcome_screen.tscn`, `scripts/welcome_screen.gd`) → Verify: Top telemetry with 7-segment high score, logo, carousel, pulsing launch prompt, and warp transition.
- [x] Task 5: Integrate Game State Machine (`scripts/asteroid_tests.gd`) → Verify: Starts in `STATE_WELCOME` with ambient background asteroids, transitions to `STATE_PLAYING` on Enter/R/Space, and loops through `STATE_GAMEOVER`.
- [x] Task 6: Update Documentation (`CHANGELOG.md`) → Verify: Document NULL SECTOR rebrand and Welcome Screen.
