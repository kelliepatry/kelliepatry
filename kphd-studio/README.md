# KPHD Studio — Monotone Vermilion

Studio skin for Claude Code, built from the KPHD Monotone — Vermilion spec.

## What's inside
- **Two themes** (`themes/`): *KPHD Monotone — Vermilion (Light)* and *(Dark)*, all 23 color slots.
  Pick one with `/theme`. Without the plugin, copy either JSON into `~/.claude/themes/`.
- **Band above the prompt**: "KPHD STUDIO · operator-first design" between double vermilion rules.
- **Tool cards**: each tool action sits on a soft card with a rounded border and a `◆ Action · target` label.
- **Status line**: "KPHD Studio — Los Angeles".
- **Toasts**: "Filed to the record." on saves, "Draft ready for your review." on drafts,
  "Approval logged." when a plan is approved, "Palette applied." when a KPHD theme is chosen.
- **Commands** (one side panel, three tabs):
  - `/palette` — every slot as a live swatch with light / dark hex
  - `/zones` — mode legend: plan, auto-accept, shell, permission
  - `/kphd-brief` — Claude writes the session brief: Objective, Decisions, Structure, Dependencies, Risks, Sequence
    (named `/kphd-brief` because Claude Code already has a built-in `/brief`)

## Install
Run `claude --plugin-dir ./kphd-studio`, or add this folder to a plugin marketplace and `/plugin install kphd-studio`.
