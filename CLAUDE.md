# Claude Code notes for this repo

## This repository is public and holds the writing only

It carries the profile page, the articles, their figures and figure scripts, the Index card refresh and the kphd-studio plugin.

Never commit client documents here: no invoices, payloads, contracts, fee schedules, client names with amounts, or bank details. The `No client documents` workflow blocks them under `templates/`.

## The backend lives in `kelliepatry/studio-home` (private)

Kellie ruled on 2026-11-11 that the technical backend is kept apart from the public writing. The invoice template, the Supabase operating notes and standing SQL authorization, the `kphd-supabase` skill update and the build archives are in `studio-home`. Do backend work there, not here.

Sessions in this repository carry no standing authorization to run Supabase SQL. The governing record is in Supabase `core.governance_decisions`.
