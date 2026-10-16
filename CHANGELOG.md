# Changelog

All notable changes to the **Echo of Dread** (Echo Rooms) project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.4.0] - 2026-10-16 (Custom Audio Track & Security Drone Enemy Patrols)

### Added
- **Custom Soundtrack Ingestion:** Replaced procedural drone noise with high-fidelity atmospheric track (`assets/audio/background_music.mp3`) routed seamlessly through `SoundManager`'s `Music` / `Ambience` bus with automated infinite looping and volume persistence.
- **Autonomous Security Drone Enemy AI (`scripts/entities/security_drone.gd`, `scenes/entities/security_drone.tscn`):**
  - Multi-state finite state machine (`PATROL`, `PAUSE`, `CHASE`, `INVESTIGATE`).
  - Waypoint navigation with customizable patrol pause durations.
  - Dynamic line-of-sight raycasting obstructing vision behind Layer 1 solid walls.
  - Forward vision cone ($90^\circ$ FOV, 190px range) rendered with animated alert-reactive vector visuals.
  - Proximity detection and high-speed interception mechanics.
  - Player capture consequence: triggers camera screen trauma (0.85), distinct `drone_alert` and `player_caught` procedural alarms, screen-space red chromatic interception HUD flash (`GameHUD.trigger_interception_flash()`), and instantaneous timeline collapse / loop reset ("lost for that loop").
  - Complete integration with the `"resettable"` and `"enemies"` groups for seamless loop reset synchronization.
- **Chamber Hazard Integration:**
  - Deployed patrol drone in Chamber 02 guarding the lower corridor route near Plate Beta.
  - Deployed patrol drone in Chamber 03 patrolling vertically in the central corridor between laser barriers.
  - Deployed two patrol drones in Chamber 04 (North and South wings) guarding the quantum core terminals.
- **Automated Verification Harness Expansion:** Expanded test runner (`scenes/test/test_runner.gd`) to 240 automated tests with 100% pass rate (240/240 passed cleanly), validating drone patrol, vision cone detection, alert signals, player capture and loop reset, state restoration, and BGM streaming.

---

## [0.3.0] - 2026-10-16 (Phase P1: Audio, UI & Polish Execution)

### Added
- **Unified Settings Menu (BUG-08):** Implemented accessible, dark sci-fi modal (`scenes/ui/settings_menu.tscn`, `scripts/ui/settings_menu.gd`) with Master, SFX, and Music/Ambience volume sliders (0–100%), Screen Shake toggle, CRT / Temporal Rewind Shader toggle, Back button, and Progress Reset with full-screen click-blocking confirmation safety alert dialog.
- **Menu Integrations:** Embedded `SettingsMenu` modal into both `MainMenu` and `PauseMenu`, providing seamless runtime configuration during menu browsing and live pause with robust ESC navigation and modal state resets.
- **Subterranean Ambient Harmonic Drone:** Implemented continuous procedural 5-harmonic sub-bass drone (`play_ambient_drone()`, `stop_ambient_drone()`) in `SoundManager.gd` routed through the `Ambience` audio bus with seamless mathematically continuous loop boundaries, 0.5 Hz gentle pulsation, and stream reference preservation across re-invocations to avoid audio popping. Connected to `BaseLevel` lifecycle and `GameManager` transitions.
- **In-World Holographic Interaction Prompts:** Implemented `InteractionPrompt` component (`scripts/ui/interaction_prompt.gd`) featuring subtle cyan breathing pulse, dynamic property setters, and smooth alpha fade transitions upon player proximity in `LeverSwitch`, `TimedButton`, and `TerminalLog`. Includes strict Player-detector filtering to prevent ghost Echoes from erroneously triggering prompts or dismissing active player prompts.
- **Automated Verification Harness Expansion:** Expanded headless test runner (`scenes/test/test_runner.gd`) to 219 automated tests (covering SettingsMenu, persistence roundtrips, ambient drone, prompt visibility, Echo isolation, and project title validation), maintaining a 100% pass rate (219/219).

### Changed
- **Project Title Harmonization (BUG-09):** Harmonized project naming in `project.godot` (`config/name="Echo of Dread"`, `config/description="Echo of Dread — A Sci-Fi Time-Loop Puzzle Game"`) and `MainMenu` header banner (`"ECHO OF DREAD"`).
- **Audio Routing & Bus Muting:** Harmonized `Ambience` bus volume modulation to link with `music_volume` in `SoundManager.apply_settings()`, and added explicit `AudioServer.set_bus_mute` when volume is at 0% to prevent residual noise and save CPU.
- **Reset Persistence:** Ensured `SaveManager.reset_all_progress()` calls `save_data()` to immediately persist pristine defaults to disk.

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
