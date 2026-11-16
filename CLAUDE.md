# Claude Code notes for this repo

## This repository is public and holds the writing only

It carries the profile page, the articles, their figures and figure scripts, and the Index card refresh.

Never commit client documents here: no invoices, payloads, contracts, fee schedules, client names with amounts, or bank details. The `No client documents` workflow blocks them under `templates/`.

Never commit anything that identifies or points into the studio's own systems: no project or database identifiers, table or schema names, rule or decision codes, receipts, hashes, internal role names, private repository names, or keys. Articles describe the method, not the machinery.

Backend and system work does not happen in this repository.

## Studio session protocol

The owner's personal preferences set a standing session protocol for KPHD work: open a session before the first substantive answer, look up records while working, and close the session when done. Sessions in this repository are authorized to run those three protocol calls automatically, without being asked, whenever a chat touches KPHD work. That authorization covers only those calls. Any other database command still needs explicit confirmation in the chat.

### Pre-plan documentation in Notion

Every project keeps its pre-plan documentation in Notion, and Notion holds the canonical copy. It is the documentation layer that keeps project work consistent from one session to the next, so no project plan is written without it.

The documentation has two levels, so that a long project never becomes one sheet nobody can read:

- **The master pre-plan** is one short page per project. It holds what is true for the whole project: the objective, the decisions that apply across phases, the list of phases with their status, and a link to each phase pre-plan. It is an overview and an index. Phase detail does not go in it.
- **A phase pre-plan** is one page per phase. It holds the detail for that phase only: its scope, decisions, dependencies, risks, sequence, and open questions.

Whenever a chat touches project work:

1. **Before planning,** read the project's master pre-plan, then the pre-plan for the phase the work belongs to. Read other phase pre-plans only when the work depends on them. If the master or the phase pre-plan does not exist, draft it in the studio's standing pre-plan format before proposing any plan, and say in the chat that it was created.
2. **While working,** plan against the phase pre-plan. If the work departs from it, say so in the chat and update it, so the plan and its documentation never drift apart.
3. **Before closing the session,** bring the phase pre-plan up to date: decisions made, what was verified, open questions, and next steps. Update the master only when something changed at project level: a phase started or finished, a phase was added, or a decision reaches across phases.

Each fact lives in one place. A decision that belongs to one phase is recorded in that phase pre-plan, and the master points to it instead of repeating it.

Sessions in this repository are authorized to read, create, and update that one project's master pre-plan and phase pre-plans automatically, without being asked. That authorization covers only those pages. Nothing in Notion is ever deleted, and any other Notion change still needs explicit confirmation in the chat.

If Notion cannot be reached, say so in the chat. Do not plan from memory as though the pre-plan had been read.

### Nothing from the protocol is committed

Nothing the protocol returns is ever committed here, including session or checkpoint identifiers, project identifiers, record contents, Notion page identifiers or links, and pre-plan contents. The rules above still apply.
