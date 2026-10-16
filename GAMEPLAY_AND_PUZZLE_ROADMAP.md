# ECHO OF DREAD (ECHO ROOMS) — GAMEPLAY & PUZZLE DESIGN ROADMAP

**Version:** 1.0.0  
**Design Lead:** Senior Gameplay & Level Design Agent  
**Core Game Mechanic:** Cooperative Time-Loop Problem Solving with Recorded Self-Echoes  

---

## 1. Audit of Current Puzzle Chambers (Campaign 1–4)

### Chamber 01: Temporal Resonance (`scenes/levels/level_01.tscn`)
- **Narrative Context:** Initial containment wing. Dr. Thorne's first log explains the tachyon breach and introduces quantum echo permanence.
- **Puzzle Layout:** A single room split by an interior wall with a central `LockedDoor`. A `PressurePlate` sits in the western chamber, and the `LevelExit` sits in the eastern chamber.
- **Intended Solution:**
  1. *Loop 1:* Player walks over to `PressurePlate` at `(240, 520)`, stands on it until the door unlocks, and holds position until the loop expires (or presses `[R]`).
  2. *Loop 2:* Echo 1 replays moving to the plate and standing on it, keeping the door open. The Player walks directly through the opened blast door to `LevelExit` at `(1080, 360)`.
- **Minimum Required Loops:** 2 Loops.
- **Required Interactions:** 1 continuous plate occupation.
- **Echo Dependencies:** Exactly 1 Echo required on `PressurePlate`.
- **Difficulty Rating:** 1 / 5 (Tutorial / Intuition Building).
- **Unintended Solutions / Cheese:** None. The central wall extends across the full room height; door is mandatory.
- **Estimated Completion Time:** 45 – 70 seconds.

---

### Chamber 02: Synchronized Isolation (`scenes/levels/level_02.tscn`)
- **Narrative Context:** Dual observation wings. Introduces multi-point simultaneous authorization across physically separated sectors.
- **Puzzle Layout:** A horizontal barrier divides the western wing into North (`PlateAlpha`) and South (`PlateBeta`) sectors. An AND-gate `LockedDoor` blocks the eastern wing exit. A `BypassLever` sits in the central corridor.
- **Intended Solution:**
  1. *Loop 1:* Player moves North, stands on `PlateAlpha`, and holds position.
  2. *Loop 2:* Player moves South into the lower wing, stands on `PlateBeta`. With Echo 1 on Alpha and Player on Beta, the AND-gate door opens.
  3. *Alternative (Bypass):* Player can toggle `BypassLever` to permanently power Circuit A, freeing future loops from holding `PlateAlpha`.
- **Minimum Required Loops:** 2 Loops (with Echo) or 3 Loops (if setting bypass first).
- **Required Interactions:** 2 plate holds OR 1 lever toggle + 1 plate hold.
- **Echo Dependencies:** 1 Echo on Plate Alpha + Player on Plate Beta.
- **Difficulty Rating:** 2.5 / 5 (Cooperative Multi-Tasking).
- **Unintended Solutions / Cheese:** The `BypassLever` is accessible from the central hall, allowing players who discover it to simplify the puzzle.
- **Estimated Completion Time:** 60 – 120 seconds.

---

### Chamber 03: The Vault & Capacitors (`scenes/levels/level_03.tscn`)
- **Narrative Context:** High-security facility vault. Introduces decay timing with `TimedButton` and lethal `LaserBarrier` hazards.
- **Puzzle Layout:** Two security laser gates (`LaserBarrier1` and `LaserBarrier2`) block passage. `TimedButton1` powers down Laser 1 for 7 seconds. `TimedButton2` powers down Laser 2 for 7 seconds. An `AlcovePlate` provides permanent deactivation for Laser 1 once reached.
- **Intended Solution:**
  1. *Loop 1:* Player presses `TimedButton1`, immediately dashes into the mid-chamber alcove, and holds `AlcovePlate` to keep Laser 1 disabled.
  2. *Loop 2:* Echo 1 holds `AlcovePlate`. Player runs past disabled Laser 1, hits `TimedButton2` at `(600, 520)`, and runs through Laser 2 before the 7-second timer elapses.
- **Minimum Required Loops:** 2 – 3 Loops.
- **Required Interactions:** 2 timed button hits, 1 plate hold.
- **Echo Dependencies:** Echo holding `AlcovePlate` or timed button trigger sync.
- **Difficulty Rating:** 3.5 / 5 (Strict Timing & Spatial Sequencing).
- **Failure States:** Touching an active laser triggers an alarm, screen trauma, and immediate loop reset.
- **Estimated Completion Time:** 90 – 180 seconds.

---

### Chamber 04: The Resonance Core (`scenes/levels/level_04.tscn`)
- **Narrative Context:** Sub-Level 4 Tachyon Core. The climax of the current prototype. Dr. Thorne's final transmission instructs the researcher to align all 4 terminal nodes simultaneously to break the causal loop.
- **Puzzle Layout:** A massive 4-input AND-gate `CoreDoor` requires simultaneous power from:
  1. `PlateNorth` (top-left wing)
  2. `PlateSouth` (bottom-left wing)
  3. `SwitchEast` (top-right wing)
  4. `PlateMaster` (bottom-right wing)
- **Intended Solution:**
  - *Loop 1:* Player runs to `PlateNorth` and holds position for the remainder of the 30s loop.
  - *Loop 2:* Player runs to `PlateSouth` and holds position.
  - *Loop 3:* Player runs to `SwitchEast` and toggles the switch on.
  - *Loop 4:* Player runs to `PlateMaster` and stands on it.
  - With Echo 1 on North, Echo 2 on South, Switch East flipped ON, and Player on Master, all 4 circuits ignite cyan. `CoreDoor` retracts and player dashes into the extraction portal.
- **Minimum Required Loops:** 3 – 4 Loops.
- **Required Interactions:** 3 plate occupations + 1 lever toggle.
- **Echo Dependencies:** 3 simultaneous Echoes actively engaged.
- **Difficulty Rating:** 4 / 5 (Macro-Coordination).
- **Estimated Completion Time:** 120 – 240 seconds.

---

## 2. Identified Design Weaknesses & Friction Points

1. **Repetitive "Stand and Wait" Loop Dead Time:**
   - In Chambers 01 and 04, the player must stand motionless on a pressure plate until the 30-second timer runs down to ensure their echo stays on the plate.
   - *Improvement:* Promote immediate player agency by highlighting the manual loop rewind hotkey `[R]` once the intended action has been performed, or introduce **latching pressure plates** and **polarity inverters**.
2. **Missing In-World Interaction Prompts:**
   - While `LeverSwitch` and `TerminalLog` display a subtle hover circle, there is no floating key prompt (e.g. `"[E] FLIP SWITCH"`) indicating the required action or current state.
3. **Pacing Spike Between Chamber 2 and 3:**
   - Chamber 2 is purely spatial. Chamber 3 abruptly introduces instant-kill laser hazards and strict 7-second time limits.
   - *Improvement:* Introduce a transitional chamber that teaches `TimedButton` without lethal laser penalties first.
4. **Lack of Dynamic Multi-Echo Synergies:**
   - Current puzzles primarily use echoes as static doorweights. Puzzles do not yet require echoes to pass items, activate relay switches in strict cadence, or guide moving obstacles.

---

## 3. Puzzle & Gameplay Expansion Roadmap

### Phase 1: Polish Existing Campaign (Chambers 01–04)
- **Interactive Action Pips in HUD:** Display exact timestamps where switches were toggled on the multi-track timeline widget.
- **Proximity Key Prompts:** Add floating holographic `"[E]"` prompt above interactive terminals and switches when within detector range.
- **Non-Lethal Laser Warning:** Add a 0.25s audio/visual warning buzz when approaching laser hazards before triggering full loop rewind.

### Phase 2: Campaign Expansion (Chambers 05–08)
- **Chamber 05: The Chronal Conveyor**
  - Introduces one-way moving walkways where echoes must time their passage to catch items or block sensor beams.
- **Chamber 06: Phase-Inversion Relays**
  - Introduces buttons that invert all active circuits: powered circuits turn off, unpowered circuits turn on. Requires echoes to toggle states in rhythmic anti-phase.
- **Chamber 07: Split Causality**
  - A chamber split into two temporal zones with different loop durations (15s in Zone A, 30s in Zone B).
- **Chamber 08: The Security Automaton**
  - A stationary security turret scans clockwise; echoes must deliberately draw turret gaze away from the path the player needs to cross.

### Phase 3: Advanced Endgame & Narrative Finale (Chambers 09–12)
- **Chambers 09–11:** Complex multi-room puzzle complexes requiring 4–5 synchronized echoes with tight spatial choreography.
- **Chamber 12: The Tachyon Manifold (Final Boss Puzzle):**
  - Real-time environmental destabilization where the loop shrinks by 3 seconds each cycle unless stabilizer rods are continuously maintained by cascading echoes.
