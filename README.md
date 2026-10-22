# Echo of Dread

[![Play on itch.io](https://img.shields.io/badge/Play%20on-itch.io-FA5C5C?logo=itch.io&logoColor=white)](https://zeninxparth.itch.io/echo-of-dread)
[![Website](https://img.shields.io/badge/Website-Landing%20Page-00f0ff?logo=firefox-browser&logoColor=white)](https://ghostofzenin08.github.io/Echo_of_Dread/)
[![Godot Engine](https://img.shields.io/badge/Godot-v4.7.2--stable-478cbf?logo=godotengine&logoColor=white)](https://godotengine.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Tests: 394 Passed](https://img.shields.io/badge/Tests-394%20Passed-success.svg)](scenes/test/test_runner.gd)

**Echo of Dread** is a 2D top-down sci-fi time-loop puzzle game built using Godot Engine and GDScript.

Trapped within the subterranean Chronos Research Facility following a catastrophic tachyon manifold breach, reality snaps back every 30 seconds. To bypass high-security blast doors, laser grids, and synchronized terminal relays, you must record iterations of your own actions and cooperate with autonomous, holographic **Echoes** of your past self.

---

### 🎮 Play Now in Browser & Official Website

- 🌐 **Official Landing Webpage & Simulation:** [https://ghostofzenin08.github.io/Echo_of_Dread/](https://ghostofzenin08.github.io/Echo_of_Dread/)
- 🕹️ **Play on itch.io (Desktop & Mobile):** [https://zeninxparth.itch.io/echo-of-dread](https://zeninxparth.itch.io/echo-of-dread)

---

## Game Concept & Mechanics

> **"You cannot escape alone in linear time. But within this loop, you are your own teammate."**

- **The 30-Second Causal Curve:** Spacetime collapses every 30 seconds, rewinding the researcher to the chamber spawn point.
- **Adaptive Chronal Pacing:** Early onboarding chambers (1–5) feature an optional 15-second fast loop toggle via HUD or `[T]` to accelerate early puzzle iterations before standard 30s loops in Chamber 6+ and manual rewind in Chamber 11+.
- **Temporal Echoes:** When a loop resets, an Echo replays your previous run's exact trajectory, button presses, and pressure plate occupations. Up to 5 simultaneous echoes can collaborate on multi-stage logic gates.
- **50 Hand-Crafted Chambers:** 5 sprawling sectors—Alpha, Beta, Gamma, Delta, and Omega Wing—scaling in difficulty and cognitive complexity.
- **Dynamic Hazards:** Evade roaming security patrol drones, beat strict capacitor countdown timers, and bypass multi-lock laser barriers.
- **Rewind Progression System:** Calibrate temporal recall throughout Sector 1; manual chronal rewind unlocks starting in Chamber 11.
- **10 Decoded Story Logs:** Unravel Dr. Aris Thorne's forbidden research into the Singularity Core.
- **Cross-Platform Touch & Desktop:** Full keyboard controls for PC, plus an integrated on-screen virtual joystick and action buttons for mobile devices.
- **Dynamic Timeline Widget:** Multi-track HUD visualizer renders real-time temporal progress, danger-zone urgency pulsing, and discrete interaction pips.
- **Tactile Sensory Feedback:** Non-linear camera trauma decay, velocity lookahead, full-screen CRT temporal rewind GLSL post-processing, and dynamic audio frequency low-pass filtering.

---

## Controls

| Action | Primary Keybinding | Alternate Keybinding | Mobile / Touch | Description |
| :--- | :---: | :---: | :---: | :--- |
| **Move** | `W`, `A`, `S`, `D` | `Arrow Keys` | Virtual Joystick | Walk researcher in chamber |
| **Interact** | `E` | `Space` / `Enter` | `[ACT]` Button | Toggle switch, press button, or read log |
| **Early Loop Pacing** | `T` | — | `[15s / 30s]` Button | Toggle 15s fast / 30s standard loop duration *(Chambers 1–5)* |
| **Rewind Loop** | `R` | — | `[REWIND]` Button | Immediately rewind loop & spawn new Echo *(Chamber 11+)* |
| **Clear Echoes** | `C` | `Backspace` | `[CLEAR]` Button | Clear all past recordings & restart chamber at Loop #1 |
| **Pause / Menu** | `Escape` | `P` | `[\|\|]` Button | Open Pause Menu or dismiss active lore modal |

---

## Architecture & Project Structure

```
Echo_of_Dread/
├── project.godot                  # Engine configuration, touch emulation, and physics layers
├── export_presets.cfg             # Production export presets for Android, Windows, and Web
├── default_bus_layout.tres        # Multi-bus audio layout (Master, SFX, Echoes, Music, Ambience)
├── scenes/
│   ├── entities/                  # Player, Echo, and Security Drone scenes
│   ├── interactables/             # Pressure plates, doors, switches, lasers, wires, logs
│   ├── levels/                    # Dynamic ChamberRunner and custom level scenes
│   ├── test/                      # Headless automated test runner & test suite
│   └── ui/                        # Main menu, sector select, HUD, touch controls, modal
├── scripts/
│   ├── autoload/                  # Singletons: GameManager, SaveManager, SoundManager, NarrativeData
│   ├── camera/                    # TactileCamera with trauma-based procedural shake
│   ├── entities/                  # ActionRecorder, LoopManager, Player, Echo, SecurityDrone
│   ├── interactables/             # Circuit logic, doors, timed buttons, laser barriers
│   ├── levels/                    # BaseLevel, ChamberRunner, and RoomBuilder geometry
│   ├── ui/                        # GameHUD, TouchControls, VirtualJoystick, menus
│   └── world/                     # ChamberDatabase (50 procedural room blueprints)
├── shaders/
│   └── temporal_rewind.gdshader   # GLSL post-processing rewind shader with chromatic aberration
└── tests/                         # Test directory
```

---

## Running the Automated Test Suite

Echo of Dread includes an extensive automated test runner (`scenes/test/test_runner.tscn`) validating **394 unit and integration tests** without requiring a window manager.

### Run Headless Tests via Console:
```powershell
# From project root using Godot 4.7.x console binary:
& "path/to/godot_console.exe" --headless scenes/test/test_runner.tscn
```

### Expected Output:
```
==================================================
       ECHO OF DREAD — AUTOMATED TEST SUITE       
==================================================
[PASS] Autoload: SoundManager is initialized
[PASS] Autoload: SaveManager is initialized
[PASS] LoopManager: Initial loop is #1
[PASS] Recorder: t=1.5 linearly interpolates position (250, 100)
[PASS] RewindLock: LoopManager locks manual rewind for Chamber 1
[PASS] RewindLock: LoopManager unlocks manual rewind for Chamber 11
[PASS] ChronalPacing: Chambers 1–5 support 15s/30s loop duration toggle
[PASS] OmegaWing: Chamber 50 singularity door requires 4 corner plates
...
==================================================
TESTS COMPLETED: 394 / 394 PASSED
==================================================
ALL SYSTEMS NOMINAL. TEST RUNNER EXITING WITH CODE 0.
```

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

---

