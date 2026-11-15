# Claude Code notes for this repo

## This repository is public and holds the writing only

It carries the profile page, the articles, their figures and figure scripts, and the Index card refresh.

Never commit client documents here: no invoices, payloads, contracts, fee schedules, client names with amounts, or bank details. The `No client documents` workflow blocks them under `templates/`.

Never commit anything that identifies or points into the studio's own systems: no project or database identifiers, table or schema names, rule or decision codes, receipts, hashes, internal role names, private repository names, or keys. Articles describe the method, not the machinery.

Backend and system work does not happen in this repository.

## Do not document in Markdown files

Writing notes, summaries, plans, handoffs, changelogs, READMEs or "docs" as `.md` files violates studio protocol. Do not create them, in this repository or in a scratch folder, unless the owner asks for that specific file in the chat.

- New `.md` files belong only under `articles/` (the writing) or `examples/` (files an article ships). Editing an existing `.md` file is fine.
- Explanations, status and summaries go in the chat reply. Anything that must be kept goes to the studio record through the session protocol, never to a file.
- A `PreToolUse` hook (`.claude/hooks/no-new-md.mjs`) refuses new `.md` files outside `articles/` and `examples/`. Do not get around it with a shell command, a different extension or another folder.

## Studio session protocol

The owner's personal preferences set a standing session protocol for KPHD work: open a session before the first substantive answer, look up records while working, and close the session when done. Sessions in this repository are authorized to run those three protocol calls automatically, without being asked, whenever a chat touches KPHD work. That authorization covers only those calls. Any other database command still needs explicit confirmation in the chat.

Nothing the protocol returns is ever committed here, including session or checkpoint identifiers, project identifiers, and record contents. The rules above still apply.
