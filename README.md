# breakbeat

A four-lane breakbeat trigger sequencer for Monome Norns and Crow.

## Install

In Maiden, run:

```text
;install https://github.com/danutpadel-oss/breakbeat
```

For TouchOSC control, also install [Toga](https://github.com/wangpy/toga):

```text
;install https://github.com/wangpy/toga
```

Import Toga's `toga.tosc` layout into TouchOSC and follow Toga's connection setup. Breakbeat automatically uses Toga when it is installed; a physical Arc remains compatible as a fallback.

The Toga grid shows the selected pattern on its first four rows:

- Row 1: kick
- Row 2: snare
- Row 3: hat
- Row 4: percussion

Tap any of the 16 step buttons to add or remove a hit. Edits are kept separately for each pattern during the session and remain in place while mutation and chaos generate variations. Press the bottom-right grid button (column 16, row 8) to restore the selected pattern to its original authored version.

## Connections

- Crow output 1: kick trigger
- Crow output 2: snare trigger
- Crow output 3: hat trigger
- Crow output 4: percussion trigger
- Crow input 2: bipolar mutation CV, 20 mutation points per volt

The mutation CV is added to the Norns mutation setting and clamped to 0–100. At 0 V, the Norns setting is unchanged.

## Norns controls

- E1: BPM
- E2: pattern
- E3: base mutation
- K2: reset and regenerate
- K3: play/stop

## Toga / Arc controls

- Ring 1: gate probability
- Ring 2: pattern selection
- Ring 3: chaos
- Ring 4: loop length, 1–16 steps

Mutation adds or removes hits. Chaos separately rotates and sometimes reverses lanes once per loop, keeping the result stable until the next loop.
