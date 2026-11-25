# Claude Code notes for this repo

## This repository is public and holds the writing only

It carries the profile page, the articles, their figures and figure scripts, and the Index card refresh.

Never commit client documents here: no invoices, payloads, contracts, fee schedules, client names with amounts, or bank details. The `No client documents` workflow blocks them under `templates/`.

Never commit anything that identifies or points into the studio's own systems: no project or database identifiers, table or schema names, rule or decision codes, receipts, hashes, internal role names, private repository names, or keys. Articles describe the method, not the machinery.

Backend and system work is never committed to this repository. A session opened here may still read and write the studio record under the session protocol below; none of it lands in a commit.

## Do not document in Markdown files

Writing notes, summaries, plans, handoffs, changelogs, READMEs or "docs" as `.md` files violates studio protocol. Do not create them, in this repository or in a scratch folder, unless the owner asks for that specific file in the chat.

- New `.md` files belong only under `articles/` (the writing) or `examples/` (files an article ships). Editing an existing `.md` file is fine.
- Explanations, status and summaries go in the chat reply. Anything that must be kept goes to the project's Notion pre-plans, a studio notebook or the studio record through the session protocol, never to a file.
- A `PreToolUse` hook (`.claude/hooks/no-new-md.mjs`) refuses new `.md` files outside `articles/` and `examples/`. Do not get around it with a shell command, a different extension or another folder.

## Studio session protocol

The owner's personal preferences set a standing session protocol for KPHD work: open a session before the first substantive answer, look up records while working, and close the session when done. Sessions in this repository are authorized to run those three protocol calls automatically, without being asked, whenever a chat touches KPHD work.

### Standing database lane

The owner has also given Claude a standing lane in the studio database, so these do not need a yes in the chat each time:

- **Reading.** Read queries are free.
- **Notebooks.** Claude writes studio notebooks. A notebook cannot be edited in place through the connector, so a change is a new version: the name carries the version and date, and the description names the notebook it supersedes. Claude never deletes a notebook. The owner clears superseded versions.
- **Record writes.** Additive only: an insert, or an idempotent upsert through an existing governed function. Each one is logged the same day on the session close with what changed, where, and how to undo it.
- **Structure changes.** Tables, columns, functions, grants and schedules change by named migration only, and the pull request to the private system repository follows. The existing review path for structure stays.

Still never, and still the owner's alone:

- No delete, truncate or drop on a populated table.
- Money and billing records, client contact, sends, publishing, deletions, moving authority from one system to another, and any ruling that names the owner.

Check the rulings on record for the topic before acting. If a ruling and this file disagree, the ruling wins; say so in the chat.

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

The owner has set a direction to retire Notion. Until she rules that into effect, this section stands as written. When she asks for a plan as a notebook, write it as a notebook and leave a pointer to it in the workflow pre-plan, so the plan is not kept twice.

### Nothing from the protocol is committed

Nothing the protocol returns is ever committed here, including session or checkpoint identifiers, project identifiers, record contents, Notion page identifiers or links, and pre-plan contents. The rules above still apply.
