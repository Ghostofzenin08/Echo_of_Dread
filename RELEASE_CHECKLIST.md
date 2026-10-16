# ECHO OF DREAD (ECHO ROOMS) — RELEASE READINESS CHECKLIST

**Target Milestone:** Alpha Demo / Public itch.io Release  
**Engine:** Godot Engine 4.7.2.stable.official (x86_64)  
**Status Key:**
- `[x] VERIFIED` — Fully implemented and confirmed by automated/manual testing.
- `[!] PENDING AUDIT FIX` — Defect identified; minimal patch documented, pending implementation.
- `[ ] PLANNED` — Scheduled for implementation in subsequent milestone.

---

## P0 — Core Stability & Defect Prevention

- [x] **Project Boots in Documented Engine:** Tested in Godot Engine 4.7.2 headless and GUI runner without engine crash.
- [x] **Automated Test Suite Baseline:** 141 automated unit tests run via `scenes/test/test_runner.tscn`.
- [!] **Test Suite Isolation (BUG-01):** Call `SaveManager.reset_all_progress()` at start of test suite to prevent bleed from existing save files.
- [!] **Progression Boundary Clamping (BUG-02):** Restrict `SaveManager.unlock_level()` to `GameManager.TOTAL_LEVELS` (prevent unlock of phantom Chamber 5).
- [!] **Signal Dispatch Timing (BUG-03):** Defer `GameManager.level_started` signal until after deferred `change_scene_to_file` finishes.
- [!] **Save File Schema & Version Validation (BUG-04):** Validate parsed JSON is a Dictionary, check `"version"`, and sanitize numeric ranges on load.
- [!] **Player Interactable Cache Purge (BUG-05):** Reset `player.nearby_interactables` and interaction state when teleported to spawn on loop rewind.
- [!] **Timestamp Zero Echo Interaction (BUG-06):** Ensure `ActionRecorder.get_interactions_in_interval` captures interactions at `t = 0.0`.
- [x] **Puzzle State Synchronization:** All interactables inherit `"resettable"` group and cleanly revert to unpowered/unlocked baseline on loop reset.
- [x] **Echo Object Cleanup:** Active echo nodes destroyed cleanly without memory leaks or phantom collision ghosts on loop reset.

---

## P1 — Gameplay & User Experience

- [x] **Deterministic Action Playback:** Player movement, rotation, and interactions replay accurately across multiple sequential loops.
- [x] **Loop Countdown Readability:** HUD displays real-time countdown with millisecond resolution, color warning shifts (< 10s, < 5s), and timeline widget.
- [x] **Urgency Phase Cues:** Dynamic SFX LowPassFilter muffle and countdown tick alarm engage when timer < 5.0 seconds.
- [x] **Distinct Visual Differentiation:** Real player is distinct from echoes; each echo has unique color, label, and tapered motion trail.
- [x] **Echo Interaction Safety:** Echoes never trigger narrative log modal dialogs.
- [x] **Terminal Narrative Delivery:** Terminals display Dr. Thorne's lore with dismissible modal on `[E]` or `[ESC]`.
- [ ] **Interactive Hover Prompts:** Display in-world `"[E]"` indicator above interactive levers and terminals.
- [ ] **Chamber Pacing Adjustment:** Rebalance transition between Chamber 2 and 3.

---

## P2 — Presentation & Audio Polish

- [x] **Procedural Screen Feel:** Camera trauma shake with quadratic decay on door slams, laser resets, and temporal rewinds.
- [x] **Camera Velocity Lookahead:** Viewport smoothly leads ahead of player locomotion vector.
- [x] **Temporal Rewind Shader:** Full-screen CRT post-processing effect with chromatic aberration and wave distortion on loop reset.
- [x] **Audio Bus Routing:** Dedicated `Master`, `SFX`, `Echoes`, `Music`, and `Ambience` buses configured in `default_bus_layout.tres`.
- [x] **Procedural Audio Synthesis:** 12 sound effects synthesized algorithmically without external audio assets.
- [x] **Ear Fatigue Prevention:** Procedural pitch jitter ($$\pm 5\%$$) applied to repeated sound effects.
- [ ] **Continuous Ambient Drone:** Procedural background synthesizer to eliminate dead silence during puzzle solving.
- [ ] **Footstep Sound Effects:** Subtle locomotion taps during player movement.

---

## P3 — Settings & Accessibility

- [x] **Persistence Infrastructure:** Master, SFX, and Music volumes, Screen Shake toggle, and CRT Shader toggle stored in `SaveManager`.
- [x] **Functional Setting Enforcement:** SoundManager and TactileCamera dynamically query and honor user settings.
- [!] **Settings UI Menu (BUG-08):** Embed dedicated Settings panel in Main Menu and Pause Menu with volume sliders and accessibility toggles.
- [!] **Progress Reset UI Control (BUG-10):** Add a `"RESET RESEARCH PROGRESS"` button with confirmation prompt in Settings UI.
- [x] **Dual Sensory Cues:** Visual color changes paired with distinct audio frequencies for hearing/vision accessibility.

---

## P4 — Platform, Export & Build Packaging

- [ ] **Export Presets Configuration:** Create `export_presets.cfg` for Windows Desktop (`x86_64`) and Web (`HTML5 / WebAssembly`).
- [ ] **Clean Standalone Export Verification:** Export project outside editor and verify executable launch, scene loading, and sound playback.
- [ ] **Exported Build Size Measurement:** Confirm packaged release size is within expected limits (~35–42 MB zipped for Windows, ~10 MB for Web).
- [ ] **Application Icon:** Verify `icon.svg` is properly converted and embedded into the Windows `.exe` executable resource header.

---

## P5 — Release Documentation & Store Assets

- [!] **Project Title Harmonization (BUG-09):** Harmonize `project.godot` (`Echo Rooms` vs `Echo of Dread`) with repository name.
- [x] **Root README Documentation:** Professional README documenting gameplay concept, keybindings, architecture, and test execution.
- [x] **Changelog:** Structured `CHANGELOG.md` following Keep a Changelog standards.
- [ ] **Promotional Banner:** 630 × 500 px itch.io cover art with high-contrast sci-fi vector logo.
- [ ] **Gameplay Screenshots:** 5 high-resolution 1080p screenshots showcasing player + echoes cooperating, timeline widget, and CRT rewind.
- [ ] **Gameplay Clip / GIF:** 15-second looping animated GIF showing a 2-echo synchronized door opening.

---

## P6 — Legal & Licensing

- [x] **Repository License:** Root `LICENSE` file contains valid MIT License (Copyright 2026 Oldest_dream08).
- [x] **Third-Party Asset Audit:** Verified zero external proprietary assets (no third-party sprites, no royalty-free stock music, no non-free fonts). 100% of codebase is MIT-compatible GDScript and GLSL shader code.
