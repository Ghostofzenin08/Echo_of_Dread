# Changelog

All notable changes to the **Echo of Dread** (Echo Rooms) project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned (Post-Audit Action Items)
- **Feature:** Implement unified `SettingsMenu` modal with Master, SFX, and Music volume sliders, Screen Shake toggle, and CRT shader toggle (BUG-08).
- **Feature:** Add procedural continuous sub-bass ambient background drone in `SoundManager`.
- **Feature:** In-world holographic interaction prompt glyphs (`"[E]"`) on levers and terminals.
- **Branding:** Harmonize project naming between repository and in-engine config (`Echo of Dread`) (BUG-09).

---

## [0.2.1] - 2026-10-16

### Fixed
- **Test Isolation (BUG-01):** Enforced hermetic test isolation in `test_runner.gd` with initial `SaveManager.reset_all_progress()`, expanding test suite to 151 passing tests.
- **Progression Overflow (BUG-02):** Clamped `SaveManager.unlock_level()` to `GameManager.TOTAL_LEVELS` (4), preventing nonexistent Chamber 5 from unlocking upon completing the final chamber.
- **Signal Race Condition (BUG-03):** Deferred `GameManager.level_started` signal dispatch via `call_deferred` so incoming scenes are fully instantiated and ready to receive signals.
- **Save State Robustness (BUG-04):** Added JSON Dictionary root assertions, save version tracking, and clamped value sanitization in `SaveManager.load_data()`.
- **Stale Interactables (BUG-05):** Implemented `Player.reset_state()` and integrated with `LoopManager.reset_loop()` and `clear_all_echoes()` to purge `nearby_interactables` cache across rewind teleports.
- **Boundary Interaction Replay (BUG-06):** Fixed interval math in `ActionRecorder.get_interactions_in_interval()` to ensure interactions recorded at exact `t = 0.0` are faithfully replayed by Echoes.
- **Signal Dead Code (BUG-07):** Connected `GameManager.loop_reset_requested` and `echoes_cleared_requested` to `LoopManager` in `initialize()`.
- **Save File Deletion Safety (BUG-10):** Handled return code of `DirAccess.remove_absolute()` in `SaveManager.reset_all_progress()` with error diagnostics.

---

## [0.2.0] - 2026-10-16

### Added
- **Automated Test Harness:** 141 comprehensive headless unit and integration tests in `scenes/test/test_runner.gd` covering autoloads, action interpolation, logic gates, audio bus routing, shaders, camera trauma, and scene instantiations.
- **Multi-Track Timeline Widget:** Real-time visual timeline in `GameHUD` showing temporal progress, 5s tick marks, urgent danger-zone pulsing, and discrete interaction diamonds for player and echoes.
- **Tactile Camera Subsystem:** `TactileCamera` with non-linear quadratic trauma decay, multi-harmonic procedural screen shake, and smooth velocity-based lookahead.
- **GLSL Temporal Rewind Post-Processing:** `shaders/temporal_rewind.gdshader` delivering screen-space VHS wave distortion, chromatic aberration, scanlines, and radial vignette during loop reset transitions.
- **Procedural Sound Engine:** 12 algorithmic 8-bit PCM sound effects generated in `SoundManager.gd` with pitch jitter ($\pm 5\%$) and dynamic low-pass frequency filtering during loop urgency (< 5s).
- **Campaign Chambers:** 4 fully functional puzzle chambers:
  - Chamber 01: Temporal Resonance (Tutorial plate & door)
  - Chamber 02: Synchronized Isolation (Dual-wing AND gate with bypass lever)
  - Chamber 03: The Vault & Capacitors (7s timed buttons & lethal laser barriers)
  - Chamber 04: The Resonance Core (4-way synchronized terminal climax)
- **Victory Screen:** Facility escape summary screen displaying total loop count, cumulative chronal drift, and per-chamber performance metrics.
- **Narrative Database:** Environmental lore terminal logs (`log_01` through `log_04`) chronicling Dr. Aris Thorne's tachyon breach containment efforts.
- **Comprehensive Documentation Suite:** `PROJECT_AUDIT.md`, `BUG_REPORT.md`, `ARCHITECTURE.md`, `GAMEPLAY_AND_PUZZLE_ROADMAP.md`, `UI_VISUAL_AUDIO_ROADMAP.md`, `PERFORMANCE_AND_BUILD_SIZE.md`, `COMMERCIAL_READINESS.md`, `RELEASE_CHECKLIST.md`, and updated root `README.md`.

### Changed
- Refactored `Echo` visuals to use procedural ghost aesthetics: dual harmonic interference rings, horizontal interior scanlines, and distinctive per-echo color palettes (Cyan, Magenta, Emerald, Amber, Royal Blue).
- Added dynamic tapering `Line2D` motion trails behind active Echoes.
- Restricted Echo interaction detector to explicitly ignore `TerminalLog` nodes to prevent unwanted narrative popups during echo playback.

---

## [0.1.0] - 2026-10-10

### Added
- Initial project architecture and 2D physics layers.
- Core 30-second time-loop recording and playback orchestrator (`LoopManager`, `ActionRecorder`).
- Basic interactables: `PressurePlate`, `LockedDoor`, and `CircuitWire`.
- Initial Player controller and basic keyboard input mapping.
