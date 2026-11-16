# Claude Code notes for this repo

## This repository is public and holds the writing only

It carries the profile page, the articles, their figures and figure scripts, and the Index card refresh.

Never commit client documents here: no invoices, payloads, contracts, fee schedules, client names with amounts, or bank details. The `No client documents` workflow blocks them under `templates/`.

Never commit anything that identifies or points into the studio's own systems: no project or database identifiers, table or schema names, rule or decision codes, receipts, hashes, internal role names, private repository names, or keys. Articles describe the method, not the machinery.

Backend and system work does not happen in this repository.

## Studio session protocol

The owner's personal preferences set a standing session protocol for KPHD work: open a session before the first substantive answer, look up records while working, and close the session when done. Sessions in this repository are authorized to run those three protocol calls automatically, without being asked, whenever a chat touches KPHD work. That authorization covers only those calls. Any other database command still needs explicit confirmation in the chat.

### Pre-plan documentation in Notion

Every project keeps a pre-plan document in Notion, and Notion holds the canonical copy. It is the documentation layer that keeps project work consistent from one session to the next, so no project plan is written without it.

Whenever a chat touches project work:

1. **Before planning,** find and read the project's pre-plan in Notion. If the project has none, draft one in the studio's standing pre-plan format before proposing any plan, and say in the chat that it was created.
2. **While working,** plan against the pre-plan. If the work departs from it, say so in the chat and update the pre-plan, so the plan and its documentation never drift apart.
3. **Before closing the session,** bring the pre-plan up to date: decisions made, what was verified, open questions, and next steps.

Sessions in this repository are authorized to read, create, and update that one project's pre-plan automatically, without being asked. That authorization covers only the pre-plan. Nothing in Notion is ever deleted, and any other Notion change still needs explicit confirmation in the chat.

If Notion cannot be reached, say so in the chat. Do not plan from memory as though the pre-plan had been read.

### Nothing from the protocol is committed

Nothing the protocol returns is ever committed here, including session or checkpoint identifiers, project identifiers, record contents, Notion page identifiers or links, and pre-plan contents. The rules above still apply.
