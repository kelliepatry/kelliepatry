[← Back to “How we work with AI”](https://kelliepatry.com/notes/how-we-work-with-ai) · [Field Notes](https://kelliepatry.com/notes) · [Home](https://kelliepatry.com/)

---

# Your first worker, step by step

### An explainer you can follow in about an hour: one plain job, one sensor, one packet, and a second key

**Kellie Patry · KPHD Studio, Los Angeles · and Claude (Anthropic) · 13 November 2026 · working draft v0.5**

**The ideas behind it:** [Build the fleet](./build-the-fleet.md) · [Sensors, not time clocks](./sensors-not-time-clocks.md)

> **What you'll have at the end.** A small program on GitHub that does one plain job the same way every time. It wakes when its input changes, writes a short packet of facts, and saves it where you and your AI model can read it. You'll also have a habit of having a second reviewer check every change to it. No installs, no command line, no paid plan. A free GitHub account and a web browser are enough.

> **Who this is for.** The owner, designer or operator who read about fleets and workers and wants to try one before reading anything else. Every step says what to click, what to paste and what you should see.

---

## Why this, and why first · Kellie

When I started, every GitHub tutorial assumed I already knew why I was there. This one starts with why.

In [Build the fleet](./build-the-fleet.md) I argued that a reasoning model shouldn't do plain work: finding, counting, listing, checking. Small workers should, the same way every time, and the model should judge from what they hand it. In [Sensors, not time clocks](./sensors-not-time-clocks.md) I wrote about what that freed up: time to decide, and to design.

None of it starts with a fleet. It starts with one worker doing one job you're tired of explaining. I chose a punch list because anyone who has closed out a project knows one, and because counting it has exactly one right answer. The point of the next hour isn't the punch list. It's the moment a small program does a plain job for you the same way twice, and you realize you never have to explain it again. That's your first worker. A fleet is just more of them.

## Before you start

You need:

- **A free GitHub account.** Sign up at github.com if you don't have one.
- **About an hour.**
- **One plain job you do over and over.** If you don't know which one yet, Step 1 finds it.

The example in this explainer is a construction punch list: the list of small open items before a project closes out. Swap in your own list later. The same three files are in this repository under [examples/first-worker](../examples/first-worker/) if you'd rather copy than paste. If you copy, put `worker.yml` at `.github/workflows/worker.yml`; it only works there. Inventory counts, open invoices, unanswered inquiries and overdue tasks all fit the same pattern.

Words you'll meet, in plain terms:

| Word | What it means here |
|---|---|
| **Repository** | A folder on GitHub that remembers every change |
| **Commit** | One saved change, with a short note saying what and why |
| **Worker** | A small program with one job, one input and one output |
| **Packet** | The worker's output: a short page of facts, no opinions |
| **Action** | An automation GitHub runs for you when something happens |
| **Sensor** | The trigger that wakes the worker when its input changes |
| **Heartbeat** | One scheduled run that proves the worker is still alive |

---

## Step 1 · Find the plain job (15 minutes, or a week of noticing)

Not everything you ask an AI to do needs intelligence. Some of it is plain: there's one right answer and a simple program can get it every time.

For the next requests you make of an AI, or the last ten you can remember, mark each one:

- **J** for judgment: weighing, deciding, interpreting, writing something new.
- **P** for plain: **find, count, list, match, extract, check.**

Pick the P that comes up most often. That's your first worker's job.

> **You should have:** one sentence that starts with a plain verb. Example: *"Count the open punch-list items, list the overdue ones, and say who owns them."*

## Step 2 · Write the worker card (10 minutes)

Before any code, write the job down. This is the worker's job description, and it's the part that matters most. Copy this and fill it in:

```text
WORKER CARD
Name:          punch-list worker
One job:       Count open items, list overdue ones, count open items by owner
Input:         punch-list.csv
Output:        packet.md
Wakes when:    the punch list changes (sensor), plus weekday mornings (heartbeat)
Never does:    decide anything, edit the list, contact anyone
Owner:         [your name]
Reviewer:      [a second person or a second AI model]
```

The **Never does** line is the one people skip. Fill it in. A worker that only counts can't hurt anything. A worker that also "fixes" things is no longer plain.

> **You should have:** a filled-in card. Keep it. It goes into the repository in Step 3.

## Step 3 · Make a practice repository (5 minutes)

1. On GitHub, click **+** (top right) → **New repository**.
2. Name it `first-worker`.
3. Choose **Private**.
4. Tick **Add a README file**.
5. Click **Create repository**.
6. Click the README file, then the pencil icon to edit it. Paste your worker card in. Click **Commit changes**, then **Commit changes** again.

> **You should see:** your new repository with one file, README.md, showing your worker card.

If any of these clicks look different on your screen, GitHub's own *Hello World* guide walks through the same moves with pictures.[05]

## Step 4 · Add the input (5 minutes)

1. In the repository, click **Add file** → **Create new file**.
2. Name it `punch-list.csv`.
3. Paste this sample list:

```csv
id,item,area,owner,status,due,updated
1,Touch-up paint at banquette end panel,Dining,Painter,open,2026-11-10,2026-11-03
2,Adjust bar back door closer,Back bar,GC,open,2026-11-20,2026-11-12
3,Replace cracked cove base tile,Dish,Tile,done,2026-11-08,2026-11-07
4,Label circuits on panel schedule,Electrical room,Electrician,open,2026-11-14,2026-11-12
5,Level espresso station counter,Coffee bar,Millwork,open,2026-11-09,2026-11-01
6,Install missing ADA sign at restroom,Restroom,GC,done,2026-11-12,2026-11-11
```

4. Click **Commit changes** twice.

Dates are written year-month-day so the worker can compare them. Status is either `open` or `done`.

> **A word about training wheels.** A spreadsheet file in GitHub is fine for learning. It's not where your real business records belong. GitHub keeps instructions and history; your live records belong in a database or tool built to be read and changed all day. When you graduate, the worker reads from there instead. The worker card doesn't change, only its input line.

## Step 5 · Add the worker (5 minutes)

1. **Add file** → **Create new file**. Name it `worker.py`.
2. Paste this:

```python
"""Punch-list worker: one plain job, done the same way every time.

Input:  punch-list.csv  (columns: id,item,area,owner,status,due,updated)
Output: packet.md       (a short research packet a person or a model can read)

It counts, lists and flags. It never decides, edits the list or contacts anyone.
"""
import csv
import sys
from datetime import date

SOURCE = sys.argv[1] if len(sys.argv) > 1 else "punch-list.csv"
PACKET = sys.argv[2] if len(sys.argv) > 2 else "packet.md"
today = date.today()

with open(SOURCE, newline="", encoding="utf-8") as f:
    rows = list(csv.DictReader(f))

open_items = [r for r in rows if r["status"].strip().lower() != "done"]
overdue = [r for r in open_items if date.fromisoformat(r["due"]) < today]

by_owner = {}
for r in open_items:
    by_owner[r["owner"]] = by_owner.get(r["owner"], 0) + 1

lines = [
    "# Punch-list packet",
    "",
    f"Prepared by the punch-list worker on {today.isoformat()} from `{SOURCE}`.",
    "Facts only. No recommendations.",
    "",
    f"- Items on the list: {len(rows)}",
    f"- Open: {len(open_items)}",
    f"- Overdue: {len(overdue)}",
    "",
    "## Overdue",
    "",
]
lines += [f"- #{r['id']} {r['item']} ({r['area']}, {r['owner']}), due {r['due']}" for r in overdue] or ["- None"]
lines += ["", "## Open items by owner", ""]
lines += [f"- {owner}: {n}" for owner, n in sorted(by_owner.items())] or ["- None"]
lines += ["", "## What this packet does not know", "",
          "- Whether an item is really finished on site. It only reads the status column.",
          "- Anything not written in the list.", ""]

with open(PACKET, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))

print(f"Wrote {PACKET}: {len(open_items)} open, {len(overdue)} overdue")
```

3. **Commit changes** twice.

You don't need to read Python to use this. Read the docstring at the top and the last section of the packet, *What this packet does not know*. A good worker says what it can't see. That's how a model reading the packet knows where the facts stop.

## Step 6 · Wire the sensor and the heartbeat (10 minutes)

This is the step that turns a script into a worker. An **Action** tells GitHub when to run it.

1. **Add file** → **Create new file**.
2. In the name box, type exactly: `.github/workflows/worker.yml` (the slashes create the folders).
3. Paste this:

```yaml
name: Punch-list worker

on:
  push:
    paths:
      - "punch-list.csv"      # the sensor: runs when the list changes
      - "worker.py"           # and when the worker itself changes
  schedule:
    - cron: "17 14 * * 1-5"   # the heartbeat: weekday mornings, 14:17 UTC
  workflow_dispatch:          # the test button: run it by hand

permissions:
  contents: write             # lets the worker save packet.md back to the repo

jobs:
  run-worker:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - name: Run the worker
        run: python worker.py punch-list.csv packet.md
      - name: Save the packet
        run: |
          git config user.name "punch-list-worker"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add packet.md
          git diff --cached --quiet || git commit -m "Packet: punch list as of $(date -u +%F)"
          git push
```

4. **Commit changes** twice.

What each part does, in trade terms:

- **`push` on `punch-list.csv`** is the sensor. Nothing runs until the list changes. Edit the list and the worker wakes. It also wakes when `worker.py` changes, so a change you merge in Step 9 is tested straight away. This is the simplest kind of sensor. Watching an inbox or meeting notes is the same idea with more plumbing.
- **`schedule`** is the heartbeat: one run on weekday mornings that leaves a dated packet behind. If the dates in the history stop, something is wrong. You have to look; nothing alerts you yet. GitHub's clock is in UTC unless you say otherwise, so 14:17 UTC is 6:17 in the morning in Los Angeles in winter. If you'd rather think in local time, add a line under the cron line: `timezone: "America/Los_Angeles"` (lined up with the word `cron`), and change the hour to 6 (update the comment too). Odd minutes like :17 are deliberate: runs on the hour are the busiest and the most likely to be delayed.[01]
- **`workflow_dispatch`** adds a **Run workflow** button so you can test by hand.
- **`permissions: contents: write`** lets the worker save its packet. Without it, the last step fails.

You might worry that the worker's own save will wake the sensor and loop forever. It won't. Changes saved with the built-in Actions token don't start new runs, and the sensor only watches the punch list anyway.[02]

## Step 7 · Run it and read the packet (5 minutes)

1. Click the **Actions** tab at the top of the repository.
2. Click **Punch-list worker** on the left.
3. Click **Run workflow** → **Run workflow**.
4. Wait a minute. A yellow dot turns into a green check.
5. Go back to the **Code** tab. A new file, `packet.md`, is there. Open it.

> **You should see:** your numbers will differ from ours as the dates pass. A short page with the count of items, open items and overdue items, a list of overdue items and their owners, and the "does not know" section. The exact overdue count depends on today's date.

Now test the sensor. Open `punch-list.csv`, click the pencil, change item 5's status from `open` to `done`, and commit. Watch the **Actions** tab: the worker starts on its own. Open `packet.md` again. The counts have changed.

Then click the **Commits** link (with a clock icon) above the file list on the repository's main page. Every change you made and every packet the worker wrote is there, with a date and a note. That's your as-built record.

**If it didn't work:**

| What you see | What it usually means |
|---|---|
| Red X on the save step, "permission denied" | The `permissions: contents: write` lines are missing or misspelled |
| Red X on "Run the worker", `ValueError` about a date | A due date isn't written as YYYY-MM-DD |
| No **Run workflow** button | The workflow file isn't at exactly `.github/workflows/worker.yml` on the main branch |
| The heartbeat didn't run on time | Normal. Scheduled runs can be delayed when GitHub is busy.[01] Use the button or the sensor |
| The heartbeat stopped after two months | In public repositories, scheduled runs are switched off after 60 days with no activity. Yours is private, so this won't happen; if you make it public, re-enable them on the Actions tab.[01] |

## Step 8 · Hand the packet to your model (5 minutes)

The worker gathers facts. Your AI model judges. Open the AI you normally use, paste in the contents of `packet.md`, and then this:

```text
Read the packet above before anything else. It was prepared by a worker
that reads the punch list. Treat it as the facts.

Do not search for or recount anything yourself. If you need a fact that
isn't in the packet, don't guess: tell me which worker I would need to
build to get it.

Now: which overdue items should I raise this week, with whom,
and how should I word it?
```

The middle paragraph is the **no-skip rule**. It stops the model from quietly redoing the plain work, and it turns every gap into a note about the next worker to build.

> **You should get:** an answer that only uses facts from the packet, plus, sometimes, a line like "I'd need a worker that reads photos from site" or "the packet doesn't say who the contractor's contact is." Write those down. That list is your backlog.

## Step 9 · Add the second key (10 minutes)

The person or model that changes the worker shouldn't be the one who approves the change. From now on, every change to `worker.py` or `worker.yml` goes through a **pull request**: a proposed change that someone else reads before it lands.

1. Open `worker.py` and click the pencil.
2. Make a small change. For example, change `"Facts only. No recommendations."` to `"Facts only. No recommendations. Built from the punch list."`
3. Click **Commit changes**. A box opens. Choose **Create a new branch for this commit and start a pull request**, then click **Propose changes**. On the next page, click **Create pull request**.
4. Click the **Files changed** tab. Red lines are removed, green lines are added.
5. Now the second key. Copy the change and your worker card into a **different** AI model from the one that wrote the change, or send it to a colleague, and ask: *"Here is a worker's job card and a proposed change. Does the change keep the worker inside its job? What could go wrong?"*
6. If the reviewer is satisfied, click **Merge pull request** → **Confirm merge**.

A model asked to check its own work tends to approve it. Research has found that models rate their own writing higher than others' even when people judge them equal.[03] A second reviewer has no stake in having written the change. That makes it a better check, not a perfect one.

**Want GitHub to enforce it?** GitHub can block changes to main until a pull request has an approving review. On the free plan this is available for public repositories only. Private repositories need a paid plan such as GitHub Pro.[04] On the free plan, keep it as a habit: no change to a worker goes straight to main.

One catch if you work alone: GitHub won't let you approve your own pull request.[06] A required review needs a second person with their own account. If the second key is an AI model, the rule stays a habit, and the habit is the part that matters.

## Step 10 · Keep the skip log (ongoing)

Every time you or your model does a plain job by hand that a worker could have done, write one line in a file called `skips.md`:

```text
2026-11-14  Counted open invoices by hand. No worker yet.
2026-11-15  Model looked up the contractor's email itself. Packet didn't have it.
```

Once a week, read it. The line that shows up most often is your next worker. Go back to Step 2.

---

## What you built

| Part | Trade name | What it is in your repository |
|---|---|---|
| Worker card | Specification | README.md |
| Input | Utility service | punch-list.csv |
| Worker | Low-voltage circuit | worker.py |
| Sensor | Occupancy sensor | the `push` trigger in worker.yml |
| Heartbeat | Panel lamp test | the `schedule` trigger in worker.yml |
| Packet | Field report | packet.md |
| Pull request + second reviewer | Inspection, two keys | Step 9 |
| History | As-built drawings | the commit history |
| Skip log | Punch list for the fleet | skips.md |

## Where to go next

- **Move the input off training wheels.** Point the worker at the real place your list lives. The worker card's input line changes; nothing else does.
- **Build the second worker** from the top line of your skip log.
- **Put a sensor on your inbox or your meeting notes.** That's where most real work enters a small business, and most of it arrives unwatched. [Sensors, not time clocks](./sensors-not-time-clocks.md) explains why.
- **Read the reasoning** behind all of this in [Build the fleet](./build-the-fleet.md).

## What this explainer isn't

- It's not a production system. It's a first worker, built to teach the pattern.
- It doesn't connect to your email, calendar or database. Those connections need credentials, and credentials deserve their own careful guide.
- It doesn't use AI inside the worker. That's on purpose. Plain jobs don't need it.

## With gratitude

The writers of GitHub's beginner documentation, who explain the platform to people who don't know it yet. And everyone who teaches in public for beginners, which is where I learned all of this.

---

## References

01. GitHub. *Events that trigger workflows: schedule.* GitHub Docs. https://docs.github.com/en/actions/writing-workflows/choosing-when-your-workflow-runs/events-that-trigger-workflows#schedule
02. GitHub. *GITHUB_TOKEN.* GitHub Docs. https://docs.github.com/en/actions/concepts/security/github_token
03. Panickssery, A., Bowman, S.R., Feng, S. *LLM Evaluators Recognize and Favor Their Own Generations.* NeurIPS 2024. https://arxiv.org/abs/2404.13076
04. GitHub. *About protected branches.* GitHub Docs. https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches
05. GitHub. *Hello World.* GitHub Docs. https://docs.github.com/en/get-started/using-github/hello-world
06. GitHub. *Approving a pull request with required reviews.* GitHub Docs. https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/approving-a-pull-request-with-required-reviews

---

*Written jointly by Kellie Patry and Claude, a language model made by Anthropic. The example data is invented. Nothing here connects to the studio's own systems. Comments and corrections: open an issue on this repository.*

[← Back to “How we work with AI”](https://kelliepatry.com/notes/how-we-work-with-ai) · [Field Notes](https://kelliepatry.com/notes) · [Home](https://kelliepatry.com/)
