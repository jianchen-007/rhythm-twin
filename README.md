# Rhythm Twin

A browser game that learns how you play it. Tap SPACE to make a spaceship hop along to procedurally generated music and collect coins; a translucent **digital twin** ship watches you, learns your tap timings, and tries to play the same level the same way you would.

Single HTML file, no build step, no dependencies. Open it and play.

[![Play locally](https://img.shields.io/badge/play-locally-pink)](index_v2_modes.html) [![MIT License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

## Quick start

Open `index_v2_modes.html` in any modern browser:

```
open index_v2_modes.html
```

Or serve via Python:

```
python3 -m http.server 8000
# then visit http://localhost:8000/index_v2_modes.html
```

Three modes:

- **▶ PRACTICE** — free play, nothing recorded
- **● TRAIN** — your taps teach the twin (anonymous local storage)
- **▷ WATCH TWIN** — sit back and watch the twin play in your style

After 4–6 TRAIN sessions, the twin's sparkline (visible in the start menu) should rise as it learns. Each level you clear (≥80% of coins) adds another coin per gap.

## File guide

| File | What it is |
|---|---|
| `index_v1_arc-and-coin.html` | The original single-mode build (one PLAY button, twin plays alongside the player) |
| `index_v2_modes.html` | **Main version** — three modes, level progression, twin self-evaluation sparkline, pause, fullscreen. Data stays in browser localStorage. |
| `index_v3_online.html` | Deployable build with optional anonymous auto-upload to Supabase. Use this for collecting data from multiple players. See `DEPLOY.md`. |
| `supabase_schema.sql` | Postgres schema + RLS policy for the `v3` backend |
| `DEPLOY.md` | Step-by-step deploy guide (Supabase + Netlify/Vercel/GitHub Pages, ~20 minutes, $0) |

## Controls

| Key | Action |
|---|---|
| SPACE / click / tap | Jump (tap mid-air to climb higher) |
| P | Pause / resume |
| F | Toggle fullscreen |

## How the twin works

The game records every SPACE press during a TRAIN session as a per-beat-gap observation: `{gap-length-in-beats, normalized-tap-times, gravity}`. When the twin plays, its planner picks one historical observation per gap (matching the current gap's beat count) and replays those tap times at the same relative position within the new gap. With more training sessions, the twin's run looks more like yours. The mechanism is intentionally simple — the architectural decomposition (Sense → Analyze → Model → Act) is what makes it interesting, not the modeling sophistication.

## Deploying online

`DEPLOY.md` walks through standing up a public link with free Supabase + free static hosting in about 20 minutes. Every TRAIN session auto-uploads with an anonymous UUID and an optional display name; you download the dataset as CSV from the Supabase dashboard.

## License

MIT — see `LICENSE`. Build on it, fork it, deploy your own.
