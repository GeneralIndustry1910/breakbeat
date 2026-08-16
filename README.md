# breakbeat

A four-lane breakbeat and ratchet trigger sequencer for Monome Norns and Crow.

## Install

In Maiden, run:

```text
;install https://github.com/GeneralIndustry1910/breakbeat
```

For TouchOSC control, also install [Toga](https://github.com/wangpy/toga):

```text
;install https://github.com/wangpy/toga
```

Download `breakbeat.tosc` from this repository and import it into the current version of TouchOSC. The layout uses Toga's responsive grid transport but replaces its four small encoder wheels with wide button strips designed for phones.

Configure the TouchOSC UDP connection as follows:

- Host: the Norns IP address shown under **SYSTEM > WIFI**
- Send port: `10111`
- Receive port: `8002`

Start the TouchOSC layout and press its connection button.

## TouchOSC layout

The four colored control strips across the top each contain 16 large buttons:

- Green row: gate probability, 0-100%
- Blue row: base mutation, 0-100%
- Pink row: chaos, 0-100%
- Purple row: loop length, 1-16 steps

The lower 16x8 grid is arranged as follows:

- Row 1: kick
- Row 2: snare
- Row 3: hat
- Row 4: percussion
- Row 5: patterns 1-16
- Row 6: patterns 17-32
- Bottom-right button: restore the selected pattern to its authored version

Rows 1-4 display the actual pattern currently playing, including mutation, rotation, and reversal. The playhead is highlighted.

Tap a drum step repeatedly to cycle through its gate modes:

```text
off -> single pulse -> two pulses -> four pulses -> off
```

Two- and four-pulse ratchets are evenly synchronized inside the current 16th-note step, so they continue to follow the selected Norns clock source. Increasing LED brightness indicates single, double, and four-pulse gates.

Manual edits are maintained separately for each pattern during the current session. Mutation and chaos generate from the edited pattern without permanently overwriting it.

## Crow connections

- Crow output 1: kick trigger
- Crow output 2: snare trigger
- Crow output 3: hat trigger
- Crow output 4: percussion trigger
- Crow input 2: bipolar mutation CV, 20 mutation points per volt

The mutation CV is added to the Norns mutation setting and clamped to 0-100. At 0 V, the Norns setting is unchanged.

## Norns controls

- E1: BPM
- E2: pattern
- E3: base mutation
- K2: restore the selected pattern
- K3: play/stop

## Physical Arc controls

- Ring 1: gate probability
- Ring 2: pattern selection
- Ring 3: chaos
- Ring 4: loop length, 1-16 steps

Mutation adds or removes gates. Chaos separately rotates and sometimes reverses lanes once per loop, keeping the result stable until the next loop.

## Layout attribution

The grid transport inside `breakbeat.tosc` is derived from [wangpy/toga](https://github.com/wangpy/toga), which is distributed under the GNU GPL v3. The new control surface, OSC mappings, sequencer behavior, and phone-oriented layout are specific to Breakbeat.
