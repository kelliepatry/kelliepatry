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

### Pre-plan documentation in Notion

Every project keeps its pre-plan documentation in Notion, and Notion holds the canonical copy. It is the documentation layer that keeps project work consistent from one session to the next, so no project plan is written without it.

The documentation has two levels, so that a long project never becomes one sheet nobody can read:

- **The master pre-plan** is one short page per project. It holds what is true for the whole project: the objective, the decisions that apply across workflows, the list of the project's workflows with their status, and a link to each workflow pre-plan. It is an overview and an index. Workflow detail does not go in it.
- **A workflow pre-plan** is one page per workflow within the project. It holds the detail for that workflow only: its scope, steps, decisions, dependencies, risks, and open questions.

Whenever a chat touches project work:

1. **Before planning,** read the project's master pre-plan, then the pre-plan for the workflow the work belongs to. Read other workflow pre-plans only when the work depends on them. If the master or the workflow pre-plan does not exist, draft it in the studio's standing pre-plan format before proposing any plan, and say in the chat that it was created.
2. **While working,** plan against the workflow pre-plan. If the work departs from it, say so in the chat and update it, so the plan and its documentation never drift apart.
3. **Before closing the session,** bring the workflow pre-plan up to date: decisions made, what was verified, open questions, and next steps. Update the master only when something changed at project level: a workflow started or finished, a workflow was added, or a decision reaches across workflows.

Each fact lives in one place. A decision that belongs to one workflow is recorded in that workflow pre-plan, and the master points to it instead of repeating it.

Sessions in this repository are authorized to read, create, and update that one project's master pre-plan and workflow pre-plans automatically, without being asked. That authorization covers only those pages. Nothing in Notion is ever deleted, and any other Notion change still needs explicit confirmation in the chat.

If Notion cannot be reached, say so in the chat. Do not plan from memory as though the pre-plan had been read.

### Nothing from the protocol is committed

Nothing the protocol returns is ever committed here, including session or checkpoint identifiers, project identifiers, record contents, Notion page identifiers or links, and pre-plan contents. The rules above still apply.
