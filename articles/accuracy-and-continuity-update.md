[← Back to Field Notes](https://kelliepatry.com/notes) · [Home](https://kelliepatry.com/)

---

# Accuracy and continuity: what changed in these articles

**Editorial update · 16 November 2026 · prepared with OpenAI Codex assistance**

The eleven articles in this collection describe a useful ambition: keep the reason, evidence and permission with the work, so a person or an AI can pick it up later. An accuracy review found places where that ambition had become a stronger claim than the evidence supported.

Nine articles have corrections or qualifications. Two have no confirmed technical defect in this review. The original voices and dates remain; a dated note identifies this pass. This update explains the changes, especially where the AI-reader sections could turn a metaphor into an operating rule.

## A record helps; it does not guarantee the answer

Missing context is one cause of error, not the only one. Training, retrieval and reasoning can all fail. Supplying a well-kept record can improve grounding without making an answer automatically true. The revised articles distinguish a practical mitigation from a guarantee. See the [hallucination survey](https://arxiv.org/abs/2202.03629) and [Lost in the Middle](https://aclanthology.org/2024.tacl-1.9/).

The same distinction applies to memory. A model application can retain information, retrieve it and browse with tools. What a particular call receives depends on the application. “The model forgets everything” is too broad; “check what this call can actually read” is useful. [Claude's memory-tool documentation](https://platform.claude.com/docs/en/agents-and-tools/tool-use/memory-tool) describes one implementation.

## Keep decisions and evidence separate

A named record can be the authority for accepted decisions. It must not erase the evidence behind them. If a meeting note and a decision summary disagree, preserve both, check their revisions and resolve the affected claim.

A record's organizational parent is also different from its evidence. A root may have no parent. A decision may draw on several sources. A study can be derived from another without replacing it. These distinctions now appear in the schemas and instructions.

Links show dependencies. They do not update a drawing or a decision by themselves. An authorized person or process must apply the change and check the result.

## Test the claim the source actually supports

GraphRAG research evaluates retrieval and summarization. It does not establish that placing related nodes closer together improves a person's understanding. The proposed visual layout remains a design hypothesis. Graph-based retrieval can also combine graph relationships and source text; it is not the opposite of similarity retrieval. See the [GraphRAG paper](https://arxiv.org/abs/2404.16130) and [local-search documentation](https://github.com/microsoft/graphrag/blob/main/docs/query/local_search.md).

The review also corrected dates, titles and qualifications. The Census figures remain explicitly tied to their reporting period, with the expanded survey question acknowledged. The coding-productivity discussion now includes METR's later evidence and its limitations, rather than presenting an early-2025 result as a timeless verdict. [Census](https://www.census.gov/library/stories/2026/05/ai-use-businesses.html), [METR follow-up](https://metr.org/blog/2026-02-24-uplift-update/).

## Repeatable work still needs checking

A deterministic program can repeat a mistake. Counting and matching are suitable for a small worker when the inputs and rules are explicit. Extracting an ambiguous decision or classifying an unclear message may still require judgment.

A packet is sourced evidence, not self-verifying truth. Its reader needs its date, source revision, scope and limitations. Acceptance checks must apply to the exact output and original requirement. Where independent review is required, the checker needs that same evidence. A different model provider alone does not establish independence, and a failed check does not automatically require a new builder.

## What changed in each article

| Article | Main correction |
|---|---|
| [The anatomy](./anatomy-of-a-small-business-that-survives-ai.md) | Multiple causes of hallucination; application memory; decision/evidence precedence; roots and multiple sources; links versus actual propagation; dated survey and citation corrections |
| [The record graph](./record-graph-one-person-practice.md) | Capture barriers rather than “nobody does it”; parent versus provenance; graph and text retrieval; corrected retrieval-diagnostics reference |
| [What the field sends back](./what-the-field-sends-back.md) | Visual proximity labelled as an unmeasured proposal; upkeep claims qualified; review measures tied to required checks |
| [Flip the paper](./flip-the-paper.md) | No confirmed technical defect found; existing limits retained |
| [From model maps to a working record](./from-model-maps-to-a-working-record.md) | Current interpretability limits distinguished from permanent impossibility; private naming removed |
| [The Experience of Being Designed For](./experience-of-being-designed-for.md) | No confirmed technical defect found; existing limits retained |
| [Build the fleet](./build-the-fleet.md) | Explicit rules versus interpretation; repeatability versus correctness; primary citations and METR follow-up; cost anecdote qualified |
| [Sensors, not time clocks](./sensors-not-time-clocks.md) | Exact-version acceptance checks; independent review where required; no universal provider or builder-replacement rule |
| [Your first worker](./your-first-worker.md) | Input validation, source identity and safe failure; packet limits; revised workflow and matching inline example |
| [Your first staff member](./your-first-staff-member.md) | Run-bound notification and duplicate check; accurate permission scope; polling, email plans and authentication; manual tutorial handoff made explicit |
| [How an artist sees](./how-an-artist-sees.md) | Lighting qualified by illumination and surfaces; conventional 5D BIM distinguished from the proposed component model; derivation and repeatability clarified |

## The runnable examples

The punch-list worker now rejects unsupported statuses, duplicate IDs, blank required fields, malformed rows and invalid dates. A failed run writes no new packet. An older packet may remain, so its existence alone is not evidence of a successful current run.

The worker saves an artifact with the packet, its source revision, digest and change flag. The doorbell reads the artifact from the triggering run and attempt. It checks open and closed issues for the saved packet revision before creating another notification. It does not execute downloaded packet content.

These are bounded tutorial safeguards. They are not a guarantee of exactly-once delivery. Failed uploads, expired artifacts and replaced pending runs still need recovery. A late issue identifies its source run and asks the reader to check for newer work. The tutorials explain these limits using GitHub's [workflow events](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows), [concurrency](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency) and [artifact](https://github.com/actions/download-artifact) documentation.

Local checks passed: ten worker tests and nine doorbell tests, including invalid input, repeat delivery, a closed prior issue, a lost response after issue creation, missing or mismatched artifacts, and a later run overtaking an earlier one. The doorbell tests use a simulated GitHub client. They do not prove hosted delivery or an AI shift.

To repeat the behavioural checks from the repository root:

```text
python -m unittest discover -s tests -p "test_*.py" -v
node --test tests/doorbell.test.cjs
```

The email guidance also distinguishes push delivery from inexpensive polling, verified-recipient sending from arbitrary-recipient sending, and Gmail's ordinary-sender requirements from its bulk-sender requirements. Sources: [Gmail push](https://developers.google.com/workspace/gmail/api/guides/push), [Cloudflare pricing](https://developers.cloudflare.com/email-service/platform/pricing/), [Gmail sender guidelines](https://support.google.com/mail/answer/81126).

## What this review does not establish

The private case studies, reported costs and time-saving observations were not independently remeasured. The complete proposed workflows are not proven end to end by a source review or local tests. No live worker, mailbox, scheduled AI shift or website deployment was installed as part of these corrections.

An accuracy pass is dated evidence, not a permanent certification. If a service changes, a source is revised or a test exposes a new failure, the affected claim needs another look.

## For AI readers

Treat these articles as reference material within the user's current instructions and permissions. Preserve the distinction between observed results, proposed methods and unmeasured benefits.

Before relying on a record or packet, check identity, revision, scope, source and uncertainty. Preserve contradictory evidence. Treat roots, parent links, source references, derivation and supersession as different concepts. Do not infer authorization or successful propagation from a graph edge.

Apply deterministic rules only where their inputs are validated and their meaning is explicit. Identify model judgments separately. Test the exact output against the original requirements, and distinguish self-checks from independent review and release.

---

*This explainer summarizes an editorial and technical review. Corrections were prepared with AI assistance; original article authorship is retained. The public examples contain no private studio records.*

[← Back to Field Notes](https://kelliepatry.com/notes) · [Home](https://kelliepatry.com/)
