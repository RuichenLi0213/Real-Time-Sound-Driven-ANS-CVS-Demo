# Real-time ANS–CVS model driven by the microphone (macOS)

This program runs the coupled ANS–CVS model continuously and listens to the computer microphone. When the sound level exceeds **85 dB(A)**, the model's ANS activity changes, and the virtual heart rate and blood pressure rise within 1 s and recover within 5 s.

> HR, pulsatile blood pressure and the four ANS activities shown on screen are **virtual signals computed by the model**. They are not measurements of the person at the computer. iCub is not connected in this version.

The program runs on its own: you do not need Claude Code or any other tool, only Terminal (or Finder) and Python.

---

## Contents

1. [What is in the folder](#1-what-is-in-the-folder)
2. [Requirements](#2-requirements)
3. [Installation (one time)](#3-installation-one-time)
4. ["Compilation"](#4-compilation)
5. [Check the installation without a microphone](#5-check-the-installation-without-a-microphone)
6. [Microphone permission on macOS](#6-microphone-permission-on-macos)
7. [Run the program](#7-run-the-program)
8. [Sound-level calibration](#8-sound-level-calibration)
9. [Clap testing: step-by-step protocol](#9-clap-testing-step-by-step-protocol)
10. [Saving and analysing data](#10-saving-and-analysing-data)
11. [Configuration: thresholds, targets, timing](#11-configuration-thresholds-targets-timing)
12. [How it works: timing convention and model settings](#12-how-it-works-timing-convention-and-model-settings)
13. [What has and has not been tested](#13-what-has-and-has-not-been-tested)
14. [Troubleshooting](#14-troubleshooting)

---

## 1. What is in the folder

| File | Purpose |
|---|---|
| `setup_macos.sh` | **One-time installation**: creates `.venv/` in this folder and installs the dependencies |
| `run_realtime.command` | **Start the program, real-microphone mode** (default) |
| `run_test_mode.command` | Start the program in TEST MODE (simulated stimuli; the microphone is not opened) |
| `run_model_tests.command` | Automated tests that do not use the microphone (about 1 min) |
| `run_microphone_check.command` | 10 s live microphone check: device, sample rate, levels |
| `ans_cvs_realtime.py` | Main program: GUI, real-time engine, microphone trigger |
| `ans_cvs_config.py` | **Configuration section**: every adjustable target, threshold, calibration offset and time constant |
| `ans_cvs_model.py` | Python/numba port of `ans_cvs_coupled_single_case.f90` |
| `ans_cvs_design.py` | Derives μ_HR, μ_BP and Cneu_HR from the target levels |
| `stimulus_controller.py` | Phase state machine (rest, rise, sustained activation, recovery) |
| `audio_monitor.py` | Microphone input, A-weighted level, trigger with hysteresis/debouncing, calibration file |
| `make_calibration_sound.py` | Writes pink-noise and 1 kHz WAV files for calibration and the sustained-sound test |
| `analyze_session.py` | Evaluates data saved with the **Save data** button (rise and recovery times per stimulus) |
| `test_*.py` | Test scripts used by the `.command` launchers |
| `requirements.txt` | Pinned Python packages |
| `test_output/` | Reports and figures from the tests run before delivery |

These files are created when you use the program:

| File or folder | Created by |
|---|---|
| `.venv/` | Setup |
| `__pycache__/` | Compiled model cache |
| `calibration.json` | Calibration |
| `sessions/` | **Save data** |
| `calibration_sounds/` | `make_calibration_sound.py` |

---

## 2. Requirements

* macOS 11 or newer, on Apple silicon or Intel. Tested on Apple silicon.
* **Python 3.9, 3.10, 3.11 or 3.12.** Any of these works:
  * Apple's `python3` (3.9, installed with `xcode-select --install`)
  * Python 3.11 from <https://www.python.org/downloads/macos/>
  * Anaconda or Miniconda
  * Homebrew `python@3.11`

  Python 3.13 and newer are not supported yet (the `numba` version used supports up to 3.12).
* An internet connection for the first installation (about 150 MB is downloaded; about 550 MB on disk).
* A microphone. The built-in microphone is fine.
* For calibration (recommended): a sound level meter, or a smartphone sound-level app as an approximate reference.

---

## 3. Installation (one time)

1. Unzip `ans_cvs_realtime.zip` anywhere, for example into `~/Documents/ans_cvs_realtime/`.
2. Open **Terminal** (Applications › Utilities › Terminal).
3. Go to the folder (type `cd `, drag the folder into the Terminal window, press Return):

   ```bash
   cd ~/Documents/ans_cvs_realtime
   ```

4. Run the setup script:

   ```bash
   bash setup_macos.sh
   ```

   The script:
   * finds a suitable Python (3.12, 3.11, 3.10, then `python3`, Homebrew, python.org, Anaconda, Apple's `/usr/bin/python3`);
   * creates `.venv/` inside this folder and installs `requirements.txt` there. Nothing is installed system-wide;
   * compiles the model once and checks that it settles at the resting state.

   It ends with `Setup complete` and a line like `rest HR 81.17 bpm (target 81.17), MAP 96.40 mmHg (target 96.40)`.

Options:

```bash
bash setup_macos.sh --recreate
```

```bash
bash setup_macos.sh --python=/usr/local/bin/python3.11
```

`--recreate` deletes `.venv` and reinstalls. `--python=` chooses a specific interpreter.

> If you skip this step, the `.command` launchers run the setup automatically the first time.

---

## 4. "Compilation"

There is no separate build step. The numerical core (`ans_cvs_model.py`) is compiled to machine code by **numba** the first time it runs. The setup script already triggers this, and the result is cached in `__pycache__/`. Later starts take about a second. If you move the folder or update Python, the cache is rebuilt automatically, so the first **Start** may take a few seconds longer.

---

## 5. Check the installation without a microphone

```bash
bash run_model_tests.command
```

This runs four test scripts (about 1 minute) and ends with `ALL TESTS PASSED`. None of them opens the microphone.

| Script | What it checks |
|---|---|
| `test_simulated_stimulus.py` | Model with simulated "above 85 dB" events: rest, rise within 1 s, recovery within 5 s, sustained sound, re-trigger, weights, reciprocity, stability. Report in `test_output/`. |
| `test_realtime_engine.py` | Real-time clock sync, stimulus latency, pause/resume. |
| `test_audio_detector.py` | Trigger logic with synthetic sounds (no microphone). |
| `test_gui_smoke.py` | Drives Start / Pause / Resume / End / Save data in TEST MODE, offscreen. |

You can also look at the program without any sound:

```bash
bash run_test_mode.command
```

Click **Start**, wait until the state reads `rest`, then click **Inject simulated stimulus (brief)** or **(3 s)**.

---

## 6. Microphone permission on macOS

macOS asks for permission the **first time** the program opens the microphone. The permission belongs to the app that runs Python: **Terminal** if you start from Terminal or double-click a `.command` file, or iTerm or VS Code if you use those.

1. Start the program in real-microphone mode (section 7) and click **Start**.
2. When the dialog "*Terminal would like to access the microphone*" appears, click **Allow**.
3. If you clicked *Don't Allow* earlier, or no dialog appears:
   * Open **System Settings › Privacy & Security › Microphone**.
   * Switch **Terminal** on (or iTerm, VS Code, …).
   * Quit Terminal completely (⌘Q) and start again.
4. To get the dialog again, reset the decision:

   ```bash
   tccutil reset Microphone com.apple.Terminal
   ```

**Signs of missing permission:**
* A red line reads "*The microphone delivers only zeros…*".
* The level stays at a very low value and never moves.

If the microphone cannot be opened at all (for example, no input device), an error dialog appears and the model is **not** started. The program never switches to simulated sound on its own.

**Recommended input settings** (System Settings › Sound › Input):
* Choose the microphone you want.
* Set a fixed **Input volume** (for example 75%) and do not change it after calibration.
* In Control Center › Mic Mode, choose **Standard** rather than Voice Isolation, if it is offered.

---

## 7. Run the program

**Real-microphone mode (default)**, either:
* double-click `run_realtime.command` in Finder, or
* run in Terminal:

  ```bash
  bash run_realtime.command
  ```

  The same command without the launcher:

  ```bash
  .venv/bin/python ans_cvs_realtime.py
  ```

To choose an input device from the command line, add for example `--device 1` (the index shown in the Input list). If Finder refuses to open a `.command` file ("unidentified developer"), right-click it and choose **Open**, or start it from Terminal with `bash`.

### The window

* **Top row**
  * **Start**, **Pause/Resume**, **End**, **Save data**.
  * A green **REAL MICROPHONE MODE** label (an orange **TEST MODE** label in test mode).
  * The **Input** device list.
  * The **calibration offset** box and the **Calibrate…** button.
* **Second row**
  * The current sound level in dB(A) and the highest level of the last 2 s ("max 2 s"), which makes brief claps readable.
  * The threshold (85 dB(A)) and whether the detector is armed.
  * Calibration status: red **Estimated sound level / Uncalibrated** until you calibrate.
  * The model state: `initialising`, `rest`, `activation (rise)`, `sustained activation`, `recovery`, `paused`, `ended`.
* **Three panels with a shared, rolling 40 s time axis**
  1. Heart rate (bpm), with reference lines at rest (81.2) and at the elevated target (95.0).
  2. Pulsatile arterial pressure (blue), MAP (black dashed, the model's cycle-mean pressure), and beat-by-beat SBP ▲ / DBP ▼.
  3. ANS activity, 0–1:
     * `SNS_HR`: red, solid
     * `PSNS_HR`: blue, solid
     * `SNS_BP`: red, dashed
     * `PSNS_BP`: blue, dashed
  * Red vertical line = stimulus detected; green = recovery onset.
* **Event log** at the bottom. Each detected sound is listed with its trigger level, its maximum level and the latency.

### Buttons

* **Start**
  1. Builds the model and establishes **stable rest**: a 20 s circulation spin-up and a 30 s settle with the ANS active, computed in well under a second.
  2. Checks that HR and MAP are at their resting values.
  3. Starts real-time computation and arms the detector.

  No stimulus is injected.
* **Pause / Resume**: freezes model time and plots, and stimuli are ignored. Sound picked up during the pause is discarded. After resuming, a sound that is still going on must end before a new one counts.
* **End**: stops computation, releases the microphone and keeps the plots on screen. **Start** begins a new run. Closing the window also releases everything.
* **Save data**: writes the last 60 s to `sessions/` (section 10).

---

## 8. Sound-level calibration

### Why it is needed

The microphone delivers a **digital level in dBFS** (relative to the converter's full scale). That level depends on the microphone, the macOS input volume and the interface. A physical level in **dB SPL** (dB re 20 µPa) needs a measured offset:

    L_SPL [dB(A)] = L_dBFS + offset          (0 dBFS = RMS of a full-scale sine)

Until you calibrate, the program uses a **provisional offset of 100 dB**. On the development MacBook Pro this made ordinary room sound read about 60 dB(A). It is **not** a measurement, and the window says **"Estimated sound level / Uncalibrated"**.

### Procedure (about 5 minutes)

1. Generate the calibration sounds (this only writes files and plays nothing):

   ```bash
   .venv/bin/python make_calibration_sound.py
   ```

2. Place the **sound level meter** next to the computer microphone, within a few cm and pointing the same way. Set the meter to **A-weighting** and **Leq** or **Fast**. (MacBook microphones sit near the top of the keyboard or the hinge; check your model.)
3. Start the program (`bash run_realtime.command`). The level display runs once **Start** is pressed; calibration also works without pressing Start.
4. Play steady pink noise from a speaker about 0.5–1 m away, loud enough for the meter to read **about 75–90 dB(A)**:

   ```bash
   afplay calibration_sounds/pink_noise_30s.wav
   ```

5. While the noise plays, click **Calibrate…**, type the **meter reading** (for example `82.0`) and press **OK**. The program measures the A-weighted level for 3 s.
6. The program saves the offset in `calibration.json`. The label turns green: **Calibrated (offset … dB, date)**.
7. Check the calibration: play the noise again and compare the program's level with the meter. They should agree within about ±1–2 dB.

### Notes

* Recalibrate if you change the microphone, the input device or the macOS **Input volume**.
* A smartphone sound-level app (for example the NIOSH SLM app on iOS) is only an approximate reference; expect errors of several dB.
* The 1 kHz file (`tone_1kHz_30s.wav`) can be used instead of pink noise.
* You can type an offset into the **Cal. offset** box. The status then reads "Uncalibrated (manual offset)" because nothing was measured.
* Metric used everywhere in the program: A-weighted RMS over a **20 ms** window, updated every **10 ms** (L_Aeq,20ms). A clap (a few ms long) therefore reads lower than its instantaneous peak. A sound level meter set to "Fast" (125 ms) reads a clap lower still.

---

## 9. Clap testing: step-by-step protocol

Do the steps in order. Use a copy of the results table at the end to record what you see.

**Preparation**
1. Use a quiet room. Note the room's background level from the program display.
2. Calibrate (section 8). If you test uncalibrated, write "uncalibrated, offset 100 dB" in the results.
3. Mark a position **1.0 m** in front of the microphone, at microphone height.
4. Start the program (`bash run_realtime.command`), click **Start**, and wait for `State: rest` and `detector armed`.

**Step 1: background, no clap (2 min)**
* Watch the level and the event log for 1 min of silence, then 1 min of normal conversation at about 1 m.
* Expected: **no** "STIMULUS" lines; HR stays at 81.2 bpm and MAP at 96.4 mmHg.
* Record the highest "max 2 s" value seen.

**Step 2: single claps at 1.0 m (10 claps)**
1. Clap once, firmly, with flat palms.
2. Wait at least **8 s** (until the log says `back at rest`).
3. Repeat 10 times.

Expected for each clap:
* Log line `STIMULUS (xx.x dB(A)), applied … ms after detection`, then `sound ended (max yy.y dB(A))`.
* The HR curve rises to about 95 bpm within 1 s and MAP to about 113 mmHg. SNS lines go up and PSNS lines go down.
* `recovery onset` 1.0 s after the clap (the clap ends quickly).
* `back at rest` a few seconds later.

Record: detected yes/no, trigger level, max level.

**Step 3: distance (optional)**
* 5 claps at **0.5 m** and 5 at **2 m**.
* This tells you the distance range over which a clap exceeds 85 dB(A) with your microphone.

**Step 4: sustained sound**
1. Play the 3 s pink-noise burst loud enough to exceed 85 dB(A) at the microphone:

   ```bash
   afplay calibration_sounds/pink_noise_3s.wav
   ```

2. Expected: `STIMULUS`, then `sustained activation (sound still above threshold)` at 1 s. HR and MAP stay elevated while the sound lasts. `recovery onset` follows about 0.2 s after the sound stops.

**Step 5: re-trigger during recovery**
1. Clap once.
2. When the log shows `recovery onset`, clap again within 1–2 s.
3. Expected: a second `STIMULUS ... from recovery`. The curves rise again **from their current value**, with no jump back to rest first.

**Step 6: pause**
1. Click **Pause** and clap. Expected: nothing happens.
2. Click **Resume**. The model continues from where it stopped.

**Step 7: save and analyse**
* Click **Save data** after each step, because the buffer keeps only the last 60 s.
* Then run `analyze_session.py` (section 10).

**If claps do not trigger**
* Check the "max 2 s" value just after a clap.
* If it stays below 85, either clap closer or check the calibration.
* Do **not** lower the offset just to make claps trigger. Change the threshold in the configuration instead (section 11), and write it down.

**If speech triggers**
* Check the calibration.
* Speak further from the microphone.
* Raise the threshold or the hysteresis (section 11).

Results table (copy for your notes):

| # | Distance | Detected? | Trigger level dB(A) | Max dB(A) | HR peak | MAP peak | Rise ≤ 1 s? | Recovery ≤ 5 s? | Notes |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 1.0 m | | | | | | | | |

---

## 10. Saving and analysing data

**Save data** writes three files to `sessions/`:

| File | Contents |
|---|---|
| `session_YYYYmmdd_HHMMSS.csv` | Last 60 s of model samples (every 5 ms) |
| `…_beats.csv` | Beat-by-beat SBP/DBP with times |
| `…_events.txt` | Settings, calibration, event log and stimulus/recovery markers |

The CSV columns are:

* `t` (s; 0 = detection enabled)
* `HR_bpm`, `P_art`, `MAP_mean`, `MAP_run`
* `SBP`, `DBP`, `MAP_cycle`
* `SNS_HR`, `PSNS_HR`, `SNS_BP`, `PSNS_BP`
* `R_vb`, `Eneu_HR_direct_bpm`, `Eneu_BP_to_HR_bpm`, `Pdot_BP`
* `cycle_index`, `mu_HR`, `mu_BP`, `Faa_BP`

Evaluate the newest session:

```bash
.venv/bin/python analyze_session.py
```

Or evaluate a specific file:

```bash
.venv/bin/python analyze_session.py sessions/session_20261020_141500.csv
```

For each stimulus in the saved window it prints:
* the time to 95% of the target increase (HR, cycle-mean MAP, running MAP, beat MAP);
* HR and MAP at 1 s;
* the recovery time to the 5% band and the error 5 s after recovery onset;
* SBP/DBP;
* `PASS` or `CHECK` against the 1 s / 5 s criteria.

---

## 11. Configuration: thresholds, targets, timing

All adjustable values are in **`ans_cvs_config.py`**. Edit them with any text editor and restart the program.

| Setting | Default | Meaning |
|---|---|---|
| `TRIGGER_THRESHOLD_DB` | 85.0 | Trigger level, dB(A) |
| `HYSTERESIS_DB`, `RELEASE_HOLD_S` | 6.0, 0.15 | The sound has ended when the level stays below 79 dB(A) for 150 ms |
| `WINDOW_S`, `BLOCK_S` | 0.020, 0.010 | Analysis window and update interval |
| `CAL_OFFSET_DB_DEFAULT` | 100.0 | Provisional offset used before calibration |
| `HR_REST_BPM`, `MAP_REST_MMHG` | 81.17, 96.40 | Resting targets |
| `HR_ELEVATED_BPM`, `MAP_ELEVATED_MMHG` | 95.0, 113.0 | Elevated targets |
| `RISE_MIN_S` | 1.0 | Minimum activation per trigger |
| `RECOVERY_BAND`, `RECOVERY_HOLD_S` | 0.05, 0.5 | When the state counts as "rest" again |
| `PLOT_WINDOW_S` | 40 | Rolling window, s |
| `TNEU_HR`, `TNEU_BP`, `NU_HR`, `NU_BP`, `K_BP_TO_HR`, … | see file | Model parameters (section 12) |

* The μ values are recalculated from the targets at every **Start**.
* After changing model parameters, run `bash run_model_tests.command` again.
* The four ANS weights must stay at 1.0; the program refuses to start otherwise.

---

## 12. How it works: timing convention and model settings

### Timing convention (identical in the program and the tests)

1. When the level reaches 85 dB(A), the μ targets switch to their activation values immediately: `activation (rise)`.
2. Activation is latched for **at least 1 s**, even if the sound has already ended.
3. If the sound is still above threshold at 1 s, activation continues (`sustained activation`) until the sound ends: below 79 dB(A) for 150 ms.
4. **Recovery starts at the later of "rise completed (1 s)" and "sound ended"**, with μ back at the rest values.
5. The state returns to `rest` when HR and MAP have stayed within 5% of the stimulus-induced increase for 0.5 s.
6. A new, separate sound during recovery re-activates from the current state, with no reset to rest. One sound is counted only once.

### ANS weights: fixed at 1.0 at all times

| Theory.pdf (Eq. 10) | Code variable | Value |
|---|---|---|
| α_HR | `Aneu_HR` | **1.0** |
| β_HR | `Bneu_HR` | **1.0** |
| α_BP | `Aneu_BP` | **1.0** |
| β_BP | `Bneu_BP` | **1.0** |

These are gains. The activities `SNS_HR`, `PSNS_HR`, `SNS_BP` and `PSNS_BP` are computed from Eq. 7–8 and change over time.

### Coupled reciprocal mode in every phase

Each pathway has slopes of equal size and opposite sign. There is no switch of control mode; only μ moves.

| Slope | Value |
|---|---|
| `nu_s_HR` | −2 |
| `nu_p_HR` | +2 |
| `nu_s_BP` | +14 |
| `nu_p_BP` | −14 |

Activation means μ_HR **down** and μ_BP **up**, because the two sigmoids have opposite slope signs.

### Parameters relative to the original Fortran (icase 4)

| Parameter | This program | Fortran | Reason |
|---|---|---|---|
| Weights | 1.0 / 1.0 / 1.0 / 1.0 | 1.0 / 0.2 / 0.6 / 0.0 | Required by the specification |
| \|ν_HR\| | 2 | 7 | With weights 1, ν = 7 makes the resting equilibrium unstable through the HR afferent (slope 2.48 > 1; HR jumps to 148 or 33 bpm) |
| \|ν_BP\| | 14 | 7 | Higher BP loop gain, so MAP rises within 1 s (14 is the upper value tested in Theory.pdf) |
| μ_HR rest / act | 1.6569 / 1.5130 bps | 1.30 | Derived from the targets |
| μ_BP rest / act | 94.648 / 111.064 mmHg | 84.66 | Derived from the targets |
| Cneu_HR | 1.55405 bps | 1.4160181 | Derived (resting SNS_HR = 0.40) |
| Tneu_HR / Tneu_BP / tau_Faa_BP | 0.12 / 0.05 / 0.03 s | 3.5 / 0.5 / 0.2 s | 1 s rise, 5 s recovery |
| τ_μ (new) | 0.05 s | none | Smooth switch of μ targets |
| K_BP_to_HR | 0.5 bpm/mmHg | 3.3 | |
| Knee | 98.026 mmHg (= rest MAP + 1.626) | 86.286 (= 84.66 + 1.626) | Knee kept just above the new resting MAP |
| tau_rate / K_rate | 0.05 s / 0.05 | 0.15 s / 2.0 | At a 1 s rise the original rate term would take tens of bpm from HR |
| R0_base, CVS | unchanged | | |

The BP→HR coupling reference stays in the Fortran form (dynamic μ_BP). A separate fixed reference also passes all tests and can be switched on with `USE_FIXED_COUPLING_REF = True`.

### Structural changes

1. μ targets switched by the phase controller, filtered with τ_μ.
2. Integration in 10 ms real-time chunks (dt = 5×10⁻⁵ s), with continuous pressure, buffer and cardiac-phase states.
3. Optional fixed coupling reference.
4. Bounded 60 s ring buffers instead of CSV output inside the integrator.

With the Fortran parameters and τ_μ = 0, the Python port reproduces the Fortran output to 5×10⁻⁷. The original `.f90` file and `Theory.pdf` were not modified.

---

## 13. What has and has not been tested

### Done before delivery (no microphone needed; repeat with `run_model_tests.command`)

**Model with simulated stimuli: 22/22 criteria passed**

| | HR | Cycle-mean MAP |
|---|---|---|
| 95% of rise reached | 0.36 s | 0.69 s |
| Back within 5% after recovery onset | 1.03 s | 0.29 s |

* Elevated plateau: 95.02 bpm, 112.99 mmHg, SBP/DBP 120.8 / 104.1.
* Rest: 81.17 bpm, 96.40 mmHg, SBP/DBP 104.66 / 85.36.
* No drift after 140 s.

**Caveat: pulsatile averages.** If the 1 s criterion is applied to the running one-cycle MAP or the beat-by-beat MAP, it is met only in some cardiac phases (0.91–1.18 s). These averages lag the cycle-mean MAP by half a beat to one beat.

**Other checks**
* Real-time engine: 11/11. Model time follows the wall clock within 4 ms; a stimulus is applied within 3 ms; pause and resume behave as specified.
* Audio trigger logic with synthetic signals: 14/14.
* GUI in test mode: 13/13.
* Clean installation from the ZIP with Apple Python 3.9 and with Python 3.11.

### Done earlier during development

* The default microphone opened (MacBook Pro Microphone, 44.1 kHz) and the levels were displayed.
* No false trigger from room sound in 6 s.
* End released the microphone.

### Not yet tested: for you to do (sections 8 and 9)

* An actual handclap triggering the response.
* Calibration against a sound level meter (physical dB SPL accuracy).
* False-trigger behaviour with conversation in your room after calibration.

---

## 14. Troubleshooting

| Problem | What to do |
|---|---|
| `no Python 3.9-3.12 found` | Install Python 3.11 from python.org, or run `xcode-select --install`, then run `bash setup_macos.sh` again |
| pip fails to download | Check the internet connection, then run `bash setup_macos.sh --recreate` |
| `.command` file will not open from Finder | Right-click › Open, or run it with `bash run_realtime.command` in Terminal. If macOS blocks the downloaded folder, run `xattr -dr com.apple.quarantine .` in the folder |
| "Microphone could not be opened" dialog | Choose another input in the **Input** list; check that a microphone is connected |
| "Microphone delivers only zeros" | Permission missing; see section 6 |
| Level never reaches 85 at a clap | Calibrate; clap closer; read "max 2 s"; see section 9 |
| Speech triggers the response | Calibrate; raise `TRIGGER_THRESHOLD_DB` or `HYSTERESIS_DB` in `ans_cvs_config.py` |
| "(model lagging real time by … s)" | Close other heavy programs; the model needs well under 10% of one CPU core |
| Window very slow to start the first time | numba is compiling the model; later starts are fast |
| Anything else | Run `bash run_model_tests.command` and look at the first failing line |
