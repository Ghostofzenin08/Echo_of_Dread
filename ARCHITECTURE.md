# ECHO OF DREAD (ECHO ROOMS) — SYSTEM ARCHITECTURE DOCUMENT

**Version:** 1.0.0 (Post-Audit Baseline)  
**Engine:** Godot Engine 4.7.2.stable.official  
**Architecture Paradigm:** Component-driven, Autoload-coordinated, Procedural 2D Game Architecture  

---

## 1. System Topology & Architecture Overview

Echo of Dread is structured into modular layers designed to achieve maximum determinism, minimal memory footprint, and zero external binary asset overhead.

```
                           +------------------------+
                           |     project.godot      |
                           +------------------------+
                                       |
                   +-------------------+-------------------+
                   |                   |                   |
        +--------------------+ +----------------+ +------------------+
        |    SoundManager    | |  SaveManager   | |   GameManager    |
        | (Procedural Audio) | | (user:// JSON) | | (Flow / Loading) |
        +--------------------+ +----------------+ +------------------+
                   |                   |                   |
                   +-------------------+-------------------+
                                       |
                           +------------------------+
                           |      NarrativeData     |
                           |   (Lore Log Database)  |
                           +------------------------+
                                       |
            +--------------------------+--------------------------+
            |                                                     |
+-----------------------+                             +-----------------------+
|       UI LAYER        |                             |     LEVEL LAYER       |
|  - MainMenu           |                             |  - BaseLevel          |
|  - LevelSelect        |                             |  - RoomBuilder        |
|  - GameHUD            |                             |  - TactileCamera      |
|  - TimelineWidget     |                             |  - RewindPostProcess  |
|  - PauseMenu          |                             +-----------------------+
|  - VictoryScreen      |                                         |
+-----------------------+                     +-------------------+-------------------+
                                              |                                       |
                                  +-----------------------+               +-----------------------+
                                  |    LOOP ORCHESTRATION |               |  INTERACTABLE SUITE   |
                                  |  - LoopManager        |               |  - PressurePlate      |
                                  |  - Player             |               |  - LeverSwitch        |
                                  |  - ActionRecorder     |               |  - TimedButton        |
                                  |  - Echo (Instances)   |               |  - LockedDoor         |
                                  |  - CharacterVisual    |               |  - LaserBarrier       |
                                  +-----------------------+               |  - CircuitWire        |
                                                                          |  - TerminalLog        |
                                                                          |  - LevelExit          |
                                                                          +-----------------------+
```

---

## 2. Global Autoloads (Singletons)

All autoload singletons run with `process_mode = Node.PROCESS_MODE_ALWAYS` so they remain functional during menu pauses and level transitions.

1. **`GameManager` (`res://scripts/autoload/game_manager.gd`)**
   - **Responsibility:** Master orchestrator for level flow, scene transitions, narrative modal state, and input registration.
   - **Key Constants:** `TOTAL_LEVELS = 4`, `LEVEL_SCENE_PATHS`.
   - **Signals:** `level_started`, `level_completed`, `narrative_opened`, `narrative_closed`, `loop_reset_requested`, `echoes_cleared_requested`.

2. **`SaveManager` (`res://scripts/autoload/save_manager.gd`)**
   - **Responsibility:** Persistent disk serialization of level unlocks, best loop counts, completion times, discovered lore logs, and user configuration settings.
   - **Storage Path:** `user://savegame.json`.
   - **Signals:** `progress_updated`, `settings_changed`.

3. **`SoundManager` (`res://scripts/autoload/sound_manager.gd`)**
   - **Responsibility:** Real-time algorithmic synthesis and pooling of sound effects without external audio assets.
   - **Architecture:** Pre-allocates a pool of 10 `AudioStreamPlayer` (global) and 6 `AudioStreamPlayer2D` (spatial) nodes.
   - **Urgency Mechanism:** Dynamically modulates an `AudioEffectLowPassFilter` on the `SFX` bus (20,000 Hz down to 900 Hz) when time remaining in loop falls below 5.0 seconds.

4. **`NarrativeData` (`res://scripts/autoload/narrative_data.gd`)**
   - **Responsibility:** Immutable repository of facility lore logs, author attributions, and chronological timestamps (`log_01` through `log_04`).

---

## 3. Time-Loop & Echo Orchestration

The time-loop mechanic is driven by a precise recording and playback architecture:

```
  +--------------------------------------------------------------------------+
  |                               30.0s LOOP                                 |
  +--------------------------------------------------------------------------+
  t=0.0s                                              t=25.0s        t=30.0s
  +-----------------------------------------------------+---------------+----+
  | NORMAL PUZZLE EXPLORATION                           | URGENCY PHASE |RESET
  | - Player inputs recorded every physics frame        | - Audio LPF   |
  | - Active Echoes replay past trajectory & actions    | - HUD red     |
  | - Pressure plates & switches activate logic gates   | - Tick alarm  |
  +-----------------------------------------------------+---------------+----+
```

### A. Recording Subsystem (`ActionRecorder`)
- Recorded each physics frame: `{ time: float, pos: Vector2, vel: Vector2, facing: Vector2, interact: bool }`.
- Interactions are logged both in the frame stream and as discrete timestamps in `interaction_times: Array[float]`.
- Playback retrieval uses **Binary Search (`O(log N)`)** to locate adjacent bounding keyframes, followed by linear interpolation (`lerp`) of positions and velocities.

### B. Echo Subsystem (`Echo`)
- Subclasses `CharacterBody2D` on collision layer 3 (`Echoes`).
- Instantiated dynamically by `LoopManager._respawn_echoes()` up to `max_echoes = 5`.
- Each echo is assigned a distinctive high-visibility holographic palette from `ECHO_COLORS` (Cyan, Magenta, Emerald, Amber, Royal Blue).
- Renders an autonomous `Line2D` motion trail (tapered curve from head to tail with matching color gradient).
- Replays physical interactions at recorded timestamps via proximity checks against interactables.
- **Safety Restriction:** Echoes explicitly ignore `TerminalLog` interactions to prevent unwanted modal popups.

---

## 4. Physics & Collision Layer Matrix

The game uses 4 distinct 2D physics layers configured in `project.godot`:

| Layer | Bit | Name | Used By | Collides With (Mask) | Description |
| :---: | :---: | :--- | :--- | :--- | :--- |
| **1** | `1` | **World** | `RoomBuilder`, `LockedDoor`, `LaserBarrier` | Layer 2 (`Player`), Layer 3 (`Echoes`) | Static walls, solid blast doors, active laser hazards |
| **2** | `2` | **Player** | `Player` | Layer 1 (`World`) | Controllable researcher body |
| **3** | `4` | **Echoes** | `Echo` | Layer 1 (`World`) | Holographic ghost playback entities |
| **4** | `8` | **Interactables** | `PressurePlate`, `LeverSwitch`, `TimedButton`, `TerminalLog`, `LevelExit` | Layer 2 (`Player`), Layer 3 (`Echoes`) | Trigger areas for puzzles and mechanisms |

*Interaction Detection:* `Player.InteractionDetector` has `collision_layer = 0` and `collision_mask = 8` (`Interactables`), detecting objects via Area2D signals.

---

## 5. Puzzle Logic & Event Propagation

Puzzle elements utilize a decoupled signal architecture. All puzzle interactables are members of the `"resettable"` group:

```
               [ PressurePlate / LeverSwitch / TimedButton ]
                                     |
                               state_changed(bool)
                                     |
              +----------------------+----------------------+
              |                                             |
              v                                             v
       [ CircuitWire ]                               [ LockedDoor ]
      set_powered(bool)                        (LogicMode: AND / OR)
  (glows & pulses cyan)                                     |
                                                  _evaluate_state()
                                                            |
                                               door_state_changed(bool)
                                                            |
                                             +--------------+--------------+
                                             |                             |
                                             v                             v
                                      [ CollisionShape ]            [ TactileCamera ]
                                     disabled = is_open              add_trauma(0.35)
```

- **`LockedDoor`:** Supports multi-trigger registration with boolean logic (`AND` / `OR`). Plays animated sliding door retraction via Godot `Tween` and dynamically enables/disables collision.
- **`LaserBarrier`:** Instant-kill / loop-restart hazard. Connected to triggers via `invert_trigger = true` (power ON deactivates laser). Contact with Player triggers camera trauma (0.8) and immediate loop rewind.
- **`CircuitWire`:** Visual feedback conduit connecting power sources to doors/barriers with animated pulses.

---

## 6. Audio Architecture & Dynamic Urgency Filter

```
                           +----------------------+
                           |      Master Bus      |
                           +----------------------+
                              ^        ^        ^
               +--------------+        |        +---------------+
               |                       |                        |
     +-------------------+    +-----------------+    +----------------------+
     |     Music Bus     |    |  Ambience Bus   |    |       SFX Bus        |
     | (Synthesized BGM) |    | (Spatial Drones)|    | (LowPassFilter 20kHz)|
     +-------------------+    +-----------------+    +----------------------+
                                                                ^
                                                                |
                                                     +----------------------+
                                                     |      Echoes Bus      |
                                                     | (Ghost Sound FX)     |
                                                     +----------------------+
```

- When `loop_time >= 25.0s`:
  $$\text{urgency} = \frac{5.0 - \text{time\_remaining}}{5.0} \in [0.0, 1.0]$$
  $$\text{cutoff\_hz} = \text{lerp}(20000.0, 900.0, \text{urgency})$$
  $$\text{pitch\_offset} = \text{urgency} \times 0.12$$
- Pitch jitter ($$\pm 5\%$$) is procedurally added to all SFX invocations to eliminate repetitive acoustic fatigue.

---

## 7. Memory & Garbage Collection Discipline

1. **Object Lifecycles:**
   - Active Echoes are freed cleanly via `queue_free()` inside `LoopManager._clear_echo_nodes()` prior to each loop respawn.
   - Transient `Tween` references (`_rewind_tween`, `_tween`) are explicitly killed via `.kill()` if still running when a new transition begins.
2. **Audio Stream Pooling:**
   - No `AudioStreamPlayer` nodes are dynamically allocated during gameplay. All 16 players (10 non-spatial, 6 spatial) are instantiated during `_ready()` and reused across all levels.
3. **No External Asset Load Overhead:**
   - Because all visuals are procedural vector draw calls and all audio is pre-generated in-memory `AudioStreamWAV` buffers, runtime memory consumption remains stable below **65 MB**.
