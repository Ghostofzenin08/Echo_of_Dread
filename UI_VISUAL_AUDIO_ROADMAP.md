# ECHO OF DREAD (ECHO ROOMS) — UI, VISUAL & AUDIO ROADMAP

**Version:** 1.0.0  
**Lead Specialists:** UI/UX Engineer, Technical Artist, Audio Specialist  
**Design Theme:** Hard Sci-Fi, Vector Minimalism, Ambient Terminal Aesthetics, CRT Temporal Distortion  

---

## 1. UI & UX Assessment & Improvement Plan

### Current State
The user interface is clean, uncluttered, and functional:
- **`MainMenu`:** Centered vertical layout with Start, Chamber Select, How-To-Play modal, and Exit.
- **`LevelSelect`:** 4-button chamber grid with lock indicators and best loop count stars.
- **`GameHUD`:** Top telemetry bar showing Chamber Title, 30s Countdown timer, Multi-track TimelineWidget, Loop counter, and Echo counter. Bottom bar shows keybind hints.
- **`TerminalModal`:** Green phosphor CRT data screen for Dr. Thorne's lore logs.
- **`PauseMenu`:** Minimalist modal with Resume, Restart Chamber, and Return to Menu.
- **`VictoryScreen`:** Facility escape debriefing with cumulative chronal loop statistics and completion times.

### Deficiencies & Friction
1. **No In-Game Settings Screen:**
   - Although `SaveManager` saves `master_volume`, `sfx_volume`, `music_volume`, `screen_shake`, and `crt_shader`, there is currently no UI panel to adjust these values.
   - **Remedy:** Implement a unified `SettingsModal` embedded into both `MainMenu` and `PauseMenu` with:
     - Master, SFX, and Music volume sliders (0% to 100%).
     - Screen Shake intensity toggle / slider.
     - CRT Rewind Shader toggle.
     - Fullscreen / Windowed display mode toggle.
2. **Missing Level Progression Reset in UI:**
   - Players cannot wipe their save file from within the game client.
   - **Remedy:** Add `"RESET RESEARCH PROGRESS"` button in Settings with a confirmation dialog.
3. **Chamber Select Details:**
   - `LevelSelect` displays best loop counts, but does not display best completion times.
   - **Remedy:** Format cards to display both: `★ BEST: 2 LOOPS (18.4s)`.

---

## 2. Visual Quality & Aesthetics Plan

### Strengths
- **Instant Distinction Between Player and Echoes:**
  - Player: Deep cobalt blue suit (`#2e8cf2`), bright cyan visor (`#4df2ff`), subtle floor contact shadow.
  - Echoes: Distinct spectral color grading per loop (Cyan, Magenta, Emerald, Amber, Royal Blue), double harmonic interference rings, horizontal interior scanlines, periodic micro-glitch lines, and dynamic tapering motion trails (`Line2D`).
- **Tactile Camera & Screen Feel:**
  - Camera trauma with non-linear decay ($$\text{trauma}^2$$) creates punchy, impactful feedback on door slams, laser resets, and temporal rewinds.
  - Smooth velocity lookahead ($$0.22\times$$ velocity) prevents jarring viewport centering.
- **Temporal Rewind Post-Processing:**
  - Custom GLSL shader with VHS wave distortion, chromatic aberration, scanline subtraction, and cyan color wash.

### Proposed Visual Polish
1. **Interactive Prompt Glyphs:**
   - Render a small floating diamond prompt above levers and terminals when the player is within interaction distance.
2. **Ambient Particle Atmospherics:**
   - Add a lightweight `CPUParticles2D` system for slow-drifting dust motes in research rooms to accentuate spatial depth and abandoned facility atmosphere.
3. **Circuit Wire Flow Animation:**
   - Currently, circuit wires glow and pulse. Add moving directional electrical dashes along active wire paths pointing from switches toward doors.
4. **Enhanced Laser Barrier Feedback:**
   - Add crackling particle sparks at the emitter post junctions when lasers are active.

---

## 3. Audio & Sound Design Plan

### Current Implementation
- 100% procedural waveform synthesis in `SoundManager.gd`.
- 12 procedural sound effects synthesized into 8-bit PCM WAV buffers:
  - `click` (880 Hz square wave)
  - `switch_on` (660 -> 880 Hz sine sweep)
  - `switch_off` (880 -> 440 Hz sine sweep)
  - `plate_press` (150 -> 90 Hz triangle wave)
  - `plate_release` (110 -> 160 Hz triangle wave)
  - `door_open` (200 -> 600 Hz sine sweep)
  - `door_close` (500 -> 180 Hz sine sweep)
  - `loop_rewind` (120 -> 1200 Hz saw sweep)
  - `level_win` (4-note arpeggio C5-E5-G5-C6)
  - `terminal_beep` (1200 Hz sine chirp)
  - `tick` (1000 Hz sine tick)
  - `alarm` (750 -> 600 Hz warning saw)
- Audio bus routing: Dedicated `Echoes` bus routed through `SFX`, dynamic LowPassFilter cutoff sweep on SFX bus during loop urgency (< 5s), $$\pm 5\%$$ pitch jitter.

### Audio Additions & Refinements
1. **Procedural Background Drone (Ambient Music):**
   - Synthesize a continuous, low-frequency atmospheric drone (sub-bass 55 Hz + 82.5 Hz binaural beat with subtle amplitude modulation) routed to the `Ambience` bus to eliminate dead silence during puzzle solving.
2. **Footstep Acoustic Feedback:**
   - Subtle procedural low-velocity taps (soft 80 Hz pulse with random pitch variation) during player locomotion.
3. **Sound Effect Softening:**
   - Increase internal sample rate of generated WAV buffers from 22,050 Hz to 44,100 Hz with cubic interpolation to smooth high-frequency square wave anti-aliasing artifacts.

---

## 4. Accessibility Strategy

1. **Color-Vision Deficiency (Colorblindness):**
   - Echoes are differentiated by both color AND numeric labels (`"ECHO #1"`, `"ECHO #2"`).
   - Door frames use positional status indicators (dual lights on frame) in addition to color (green/red) and physical panel slide positions.
2. **Photosensitivity / Motion Sickness:**
   - Provide explicit settings toggles to disable Screen Shake (`screen_shake = false`) and CRT Rewind Shaders (`crt_shader = false`).
3. **Auditory Accessibility:**
   - All critical audio cues (loop urgency countdown, laser contact, switch toggle) have redundant visual counterparts (flashing timer, timeline danger zone pulse, wire color shift).
