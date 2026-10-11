# Math Drums

A four-output mathematical drum instrument for **norns / norns shield + USB crow**. No grid required, no audio engine. The display draws four event lanes with parent/child arcs inspired by the reference image. This is an original rhythm generator, not a reconstruction of the image's undocumented equations.

## Install

This instrument lives in the `math-drums` folder on the `math-drums` branch of the breakbeat repository. Copy that folder to `/home/we/dust/code/math-drums`, then restart/reload the script list and run `math-drums`. Do not put the entire breakbeat repository inside the math-drums folder.

From a norns SSH terminal:

```sh
git clone --branch math-drums --single-branch https://github.com/GeneralIndustry1910/breakbeat.git /tmp/math-drums-install
cp -R /tmp/math-drums-install/math-drums /home/we/dust/code/
```

If `/home/we/dust/code/math-drums` already exists, back it up before copying. Connect crow by USB and patch its outputs to your drum modules. Start with K2. Playback begins at the next four-beat clock boundary.

## Controls

| Control | Action |
| --- | --- |
| E1 | Complexity / branching depth and density |
| E2 | Chaos / logistic instability and timing perturbation |
| E3 | Gravity / attraction toward sixteenth-note positions |
| K2 | Play / stop |
| K3 | Mutate a deterministic selection of voices, 35% chance per voice |
| Hold K1 + E1 | Switch tree / information page |
| Hold K1 + E2 | Select mathematical system |
| Hold K1 + E3 | Coupling between voices |
| Hold K1 + K2 | Freeze mutation |
| Hold K1 + K3 | Next seed / regenerate |

Freeze blocks K3 mutations; encoders and next-seed still explicitly regenerate. Parameter edits take effect at the next loop boundary, avoiding mid-loop changes. Mutation may select no voices. Parameter edits reset mutation history. The playhead updates on events.

## Crow outputs

Defaults: OUT 1 kick trigger, OUT 2 snare trigger, OUT 3 hat trigger, OUT 4 modulation CV. Roles are patch suggestions; all four outputs are configurable in PARAMETERS.

- Trigger: 10 ms at the configured voltage.
- Gate: configurable 1–500 ms high duration, with a low segment at each retrigger. Long gates retrigger and restart their duration when events overlap.
- CV: mathematical event value scaled to 0–5 V, with configurable slew. Holds between events.
- Independent mute and voltage settings per output. Stop and cleanup force all four outputs to zero.

A single output sends either gate/trigger or CV. For simultaneous drum trigger and modulation, dedicate separate outputs to those roles. The script disables the global norns crow clock output on initialization because it needs all four outputs; re-enable your usual crow clock routing after exiting if desired.

## Mathematics

Four-beat loops begin with voice-specific root pulses. Recursive descendants use prime reciprocals, a logistic map, the golden-ratio conjugate, or modular ratios. Coupling blends a voice's state with the preceding voice. Chaos perturbs descendant timing and values; gravity continuously interpolates timing toward a quarter-beat grid. Root pulses preserve a rhythmic anchor. Seeded Park–Miller randomness perturbs the system without depending on Lua's global random state.

Events are bounded to one loop, capped at 160 before thinning, and separated by at least 1/32 beat on each output, including at the loop seam. Timing uses norns' global beat clock and absolute four-beat offsets, so simultaneous events share a timestamp and tempo changes follow the clock. Set clock source/tempo in the normal norns clock menu (internal, MIDI, Link, or crow input). USB and host scheduling introduce timing jitter; this is not an audio-rate or sample-accurate engine.

## Saving

Use norns parameter presets for settings and the seed. A seed plus controls reproduces a freshly generated pattern. To recall a partially mutated pattern exactly, use PARAMETERS → PATTERN SNAPSHOT → save current pattern / load saved pattern. One snapshot is stored in the script's data directory. Snapshot load restores mathematical controls and event ancestry; output modes/voltages stay under your current parameter settings. Save a parameter preset as well if you want those restored.

## Validation

`python tests/test_engine.py` uses `lupa` (`pip install lupa`) to check Lua syntax, deterministic generation, bounds, spacing, mutation preservation, scheduler behavior, and stop/cleanup with a mocked norns/Crow host. Real norns/Crow hardware has not been tested. Test at a moderate tempo first and confirm your drum modules respond to the configured gates.

References: https://monome.org/docs/crow/norns/ and https://monome.org/docs/norns/clocks/
