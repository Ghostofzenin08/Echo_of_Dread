# Echo of Dread (Echo Rooms)

[![Godot Engine](https://img.shields.io/badge/Godot-v4.7.2--stable-478cbf?logo=godotengine&logoColor=white)](https://godotengine.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Tests: 141 Passed](https://img.shields.io/badge/Tests-141%20Passed-success.svg)](scenes/test/test_runner.gd)

**Echo of Dread** is a 2D top-down sci-fi time-loop puzzle game built using Godot Engine and GDScript.

Trapped within the subterranean Chronos Research Facility following a catastrophic tachyon manifold breach, reality snaps back every 30 seconds. To bypass high-security blast doors, laser grids, and synchronized terminal relays, you must record iterations of your own actions and cooperate with autonomous, holographic **Echoes** of your past self.

---

## Game Concept & Mechanics

> **"You cannot escape alone in linear time. But within this loop, you are your own teammate."**

- **The 30-Second Causal Curve:** Spacetime collapses every 30 seconds, rewinding the researcher to the chamber spawn point.
- **Temporal Echoes:** When a loop resets, an Echo replays your previous run's exact trajectory, button presses, and pressure plate occupations. Up to 5 simultaneous echoes can collaborate on multi-stage logic gates.
- **Dynamic Timeline Widget:** Multi-track HUD visualizer renders real-time temporal progress, danger-zone urgency pulsing, and discrete interaction pips for both player and echoes.
- **Tactile Sensory Feedback:** Non-linear camera trauma decay, velocity lookahead, full-screen CRT temporal rewind GLSL post-processing, and dynamic audio frequency low-pass filtering.
- **Zero Asset Bloat:** 100% procedural vector rendering and mathematical waveform audio synthesis. The entire clean source project occupies only **150 KB**.

---

## Controls

| Action | Primary Keybinding | Alternate Keybinding | Description |
| :--- | :---: | :---: | :--- |
| **Move Left** | `A` | `Left Arrow` | Walk researcher left |
| **Move Right** | `D` | `Right Arrow` | Walk researcher right |
| **Move Up** | `W` | `Up Arrow` | Walk researcher up |
| **Move Down** | `S` | `Down Arrow` | Walk researcher down |
| **Interact** | `E` | `Space` / `Enter` | Toggle switch, press capacitor button, or read terminal log |
| **Rewind Loop** | `R` | — | Immediately rewind current loop & spawn new Echo |
| **Clear Echoes** | `C` | `Backspace` | Clear all past recordings & restart chamber at Loop #1 |
| **Pause / Dismiss**| `Escape` | `P` | Open Pause Menu or dismiss active lore modal |

---

## Architecture & Project Structure

```
Echo_of_Dread/
├── project.godot                  # Engine configuration & physics layers
├── default_bus_layout.tres        # Multi-bus audio layout (Master, SFX, Echoes, Music, Ambience)
├── scenes/
│   ├── entities/                  # Player & Echo scenes
│   ├── interactables/             # Pressure plates, doors, switches, lasers, wires, logs
│   ├── levels/                    # Chamber scenes (Level 01 to 04)
│   ├── test/                      # Headless automated test runner & test suite
│   └── ui/                        # Main menu, level select, HUD, pause menu, victory screen
├── scripts/
│   ├── autoload/                  # Singletons: GameManager, SaveManager, SoundManager, NarrativeData
│   ├── camera/                    # TactileCamera with trauma-based procedural shake
│   ├── entities/                  # ActionRecorder, LoopManager, Player, Echo, CharacterVisual
│   ├── interactables/             # Circuit logic, doors, timed buttons, laser barriers
│   ├── levels/                    # BaseLevel and Chamber controllers
│   └── ui/                        # GameHUD, TimelineWidget, menus, victory screen
├── shaders/
│   └── temporal_rewind.gdshader   # GLSL post-processing rewind shader with chromatic aberration
└── tests/                         # Test directory
```

---

## Running the Automated Test Suite

Echo of Dread includes an extensive automated test runner (`scenes/test/test_runner.tscn`) validating **141 unit and integration tests** without requiring a window manager.

### Run Headless Tests via Console:
```powershell
# From project root using Godot 4.7.x console binary:
& "path/to/godot_console.exe" --headless scenes/test/test_runner.tscn
```

### Expected Output:
```
==================================================
       ECHO ROOMS — AUTOMATED TEST SUITE          
==================================================
[PASS] Autoload: SoundManager is initialized
[PASS] Autoload: SaveManager is initialized
[PASS] LoopManager: Initial loop is #1
[PASS] Recorder: t=1.5 linearly interpolates position (250, 100)
[PASS] Two-Echo Puzzle: Door unlocks when Echo holds Plate A and Player activates Plate B
...
==================================================
TESTS COMPLETED: 141 / 141 PASSED
==================================================
ALL SYSTEMS NOMINAL. TEST RUNNER EXITING WITH CODE 0.
```

---

## Building and Exporting

1. Open the project in **Godot Engine 4.7.x**.
2. Select **Project -> Export...**
3. Select your target preset:
   - **Windows Desktop (`x86_64`)**
   - **Web (`HTML5 / WebAssembly`)**
4. Click **Export Project** to produce release binaries.

---

## Technical Audit Reports

For detailed engineering analysis, defect registers, and development roadmaps, see:
- [`PROJECT_AUDIT.md`](PROJECT_AUDIT.md) — Comprehensive technical inventory and system analysis
- [`BUG_REPORT.md`](BUG_REPORT.md) — Complete bug register with reproduction steps and fixes
- [`ARCHITECTURE.md`](ARCHITECTURE.md) — Topology, lifecycle, physics layers, and memory discipline
- [`GAMEPLAY_AND_PUZZLE_ROADMAP.md`](GAMEPLAY_AND_PUZZLE_ROADMAP.md) — Chamber audit and puzzle expansion roadmap
- [`UI_VISUAL_AUDIO_ROADMAP.md`](UI_VISUAL_AUDIO_ROADMAP.md) — Sensory polish and accessibility enhancements
- [`PERFORMANCE_AND_BUILD_SIZE.md`](PERFORMANCE_AND_BUILD_SIZE.md) — Empirical size and performance measurements
- [`COMMERCIAL_READINESS.md`](COMMERCIAL_READINESS.md) — Commercial potential, market fit, and milestone strategy
- [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md) — Trackable release readiness checklist

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.  
Copyright (c) 2026 Oldest_dream08.
