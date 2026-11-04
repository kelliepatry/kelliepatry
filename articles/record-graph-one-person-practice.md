# A record graph for a one-person design practice

**Kellie Patry · KPHD Studio, Los Angeles · 4 November 2026 · working draft v0.1**

> This is a working paper, not a result. Everything in it is one practice over two days. The measures in section 6 have a baseline and no second reading yet. Section 8 lists what we have not done. Read it as a method and a set of claims to test, and tell me where it is wrong.

## Abstract

A one-person hospitality design practice holds its working record across two systems: a relational database as the authority, and a document workspace as the writing surface. Over two days we built a live graph over that record in which every entity is a node, every node has exactly one origin link back to the studio, every link carries a provenance label (original, calculated, editorial), and a missing origin is drawn as a defect. The graph is served by one read function to a human visual and to three AI consumers.

We report what the graph made visible that tables did not: 68 disconnected fragments that resolved to categories nobody had named, 86 recorded decisions with zero decision-to-decision links, a governance layer recorded more thoroughly than the design work it governs, and work delivered beyond contract on a completed project that no one had noticed. We position the approach against design rationale research, requirements traceability, W3C PROV, digital-thread knowledge graphs, Architecture Decision Records and graph-based retrieval for language models. The contribution is not a new ontology. It is a working combination for the smallest possible firm: capture where decisions already happen, an AI as the primary reader, provenance on every edge, and absence as a first-class signal.

## 1. The problem

A small design practice makes hundreds of decisions per project, in meetings, on markups and on site. Almost none are recorded as decisions. They survive as transcripts, drawing revisions and email. The consequences are familiar: a change made in the field cannot be traced to the design intent it replaced; scope delivered beyond the contract is invisible until after the fact; the same question gets answered twice because the first answer cannot be found.

In our record the symptom was concrete. One project held 40 design decisions and one link between them. The record held about 126 rulings about how the system itself runs, against about 40 decisions about the work.

The question: can a very small practice get decision lineage, meaning *what put this mark here, and what moves if the decision changes*, without adding a documentation task to the designer's day?

## 2. Prior work and where we sit

**Design rationale and the capture problem.** IBIS, gIBIS, QOC and Compendium spent four decades trying to record the issues, options and arguments behind design. The field's own retrospective names the obstacle: the capture problem, how to get quality input into a rationale system without disrupting the very process it documents, and the observation that it is not just a capture problem but a *useful* capture problem [1]. Designers in familiar situations do not see a need to record rationale, and are most inclined to reflect at breakdowns [2]. Compendium's answer was to invest the structuring effort at the point of capture, with the stakeholders in the room [1].

*Our position:* we treat the capture problem as settled and do not ask the designer to write rationale. Decisions are extracted from meeting transcripts and field notes by the same AI pipeline that already produces meeting recaps, and are written as records with a change-target and a supersedes link. The designer's only act is confirmation.

**Requirements traceability.** Gotel and Finkelstein's 1994 analysis found that most traceability failures come from *pre-specification* traceability: the inability to trace a requirement back to its origin, its stakeholders and the process that produced it. They concluded that traceability is socio-technical rather than a tooling problem [3]. Trace-link recovery research treats missing links as an information-retrieval task and treats every recovered link as a candidate until a person vets it [4].

*Our position:* the pre-specification gap is exactly the schematic-design-to-field gap we are closing. We adopt the candidate/vetted distinction directly. A lineage link is written only where the newer record names the older one, or the designer confirms it. A text match is a candidate, never a line.

**Provenance.** W3C PROV-O gives Entity, Activity and Agent, with `wasDerivedFrom` for entity-to-entity derivation, and deliberately does not make derivation transitive [5]. DecPROV extends PROV for decisions on the premise that analysing decisions after the fact is an exercise in provenance [6].

*Our position:* our three labels (original: a link row exists; calculated: origin chosen by a stated rule; editorial: a human grouping) are a coarser, practical version of PROV's qualified derivation. We have not mapped to PROV-O and should.

**Digital thread and AEC knowledge graphs.** Manufacturing and defence use ontologically linked knowledge graphs as a digital thread with provenance preserved so a field issue can be traced back through design [7]. In AEC, OPM-compliant knowledge graphs on the Linked Building Data stack separate explicit facts from derived facts and manage evolving design data [8]; change-propagation work models dependencies between components in an ontology and a dependency matrix [9]; recent work proposes decision-memory records for rejected and non-selected architectural decisions at the coordination-to-technical-design transition [10]. One industry framing calls the next step a *decision thread*, with decision latency (time to trace a field issue back through design) as the maturity measure [11].

*Our position:* we are a digital thread at the scale of one practice, with the decision rather than the model element as the unit of record. We did not reuse BOT or OPM; whether we should is open. Decision latency is adopted as a measure.

**Architecture Decision Records.** Software teams keep decisions as short dated records with a supersedes chain, and that chain is what keeps a decision log honest [12]. Recent work extracts ADRs from raw meeting transcripts with multi-agent workflows and flags the tension between enrichment and transcript-faithfulness [13].

*Our position:* our decision records are ADRs for buildings, with supersedes, refines, contradicts and feedback-to as the link roles. The faithfulness tension in [13] is our first risk.

**Graph-based retrieval for language models.** GraphRAG retrieves connected evidence rather than similar text, and current work logs the anchors, paths and supporting passages with each answer so the provenance trace is part of the output [14].

*Our position:* our graph is not an index a model extracted from documents. It is the record itself, read by the model through one documented function that returns a revision hash with every answer. That makes the model's reading auditable without a separate retrieval log.

**Personal knowledge graphs.** Obsidian-style graph views are widely judged beautiful and operationally weak: a topological map of links, not a working view, breaking down past a few hundred notes [15].

*Our position:* this is why the graph is not a vault view. Every node has one enforced origin, closed records draw faint inside their origin, lenses replace the all-types hairball, and a dot with no line is a defect, not decoration.

## 3. Method

**Setting.** One principal. Authority record in a Postgres database; writing surface in a document workspace; three AI consumers (two general models and a classification worker). Typologies: restaurants, bars, cafés, a surgical centre, retail.

**Record model.** Node types: studio, standing area, initiative (lab, program, build), study, ruling, project, phase, decision, milestone, execution process, tool, staff team, staff persona. Rules:

1. Every record has exactly one origin link.
2. Every node and edge carries a provenance label: original, calculated or editorial.
3. Decisions are split into a lineage family (design, scope, scope change, direction, field change) and an operational family (approval, publication, governance, budget, procurement). Only lineage-family decisions take decision-to-decision links.
4. Closed records stay inside their origin, drawn faint. No separate archive pile.
5. Studio work clusters into standing areas; a personal ideas pool is its own cluster with no owner.

**Forward rules.** Links are set at creation, not backfilled: a meeting recording gets a project at capture; document templates carry their phase; a ruling must name its target; a study must name its parent; a journal entry marked as an intention produces an initiative in state *framed*. A governed session close runs a defect check and refuses a clean close if defects were introduced.

**Read.** One function serves discover, find, children, compact and graph modes. Every answer returns a revision hash of nodes and edges. The human visual reads the same function live, with a stamped snapshot as fallback.

**Procedure, 2 to 4 November 2026.** Evidence-only backfill; standing areas created; a scope ledger built from meeting-extracted requests; a restudy of the graph against its stated objective; decision reclassification; one-origin rebuild; audits for loops and double paths; the first lineage link; staff ownership wired in; migration of the graph into the database with per-consumer tests.

## 4. How the questions, the record and the model connected

Figure 1 is the argument of this paper drawn in the graph's own grammar. The left column is what the designer asked. The middle is what the model read in the live record and showed. The right is what changed in the record as a result. The red dashed line is the claim: each picture raised the next question. No plan did.

![Figure 1. How the questions, the record and the model connected](../assets/record-graph-figure-1.png)

Figure 2 shows the graph's shape at eight points across the two days, redrawn from the counts recorded at each step.

![Figure 2. How the graph changed, 2 to 4 November](../assets/record-graph-figure-2.png)

## 5. Results

- **Fragmentation.** 68 connected pieces became 1 after one-origin enforcement. The fragments were not bad data. They were rulings about areas that existed in the principal's head but not as records. Naming six standing areas bound 70 of 71 studio-only rulings.
- **Defects.** 103, then 43, then 0 over one day, with a standing defect register afterwards.
- **Decisions.** 86 on record. After reclassification: 39 lineage-family, 47 operational. Zero decision-to-decision links before the restudy; one after. That one link was a field change on a completed project (a flat solid door replacing a custom millwork door) whose original decision had never been written anywhere except a meeting transcript.
- **Proportion.** About 126 rulings about the system against about 40 design and field decisions. One active project carried 13 decisions; the others carried none despite active decision-making.
- **Scope.** A scope ledger of 136 lines. The first read on a completed project showed construction administration and procurement delivered against a contract that excluded both, with dozens of construction-phase requests never ruled on.
- **Coverage.** 55 open areas, labs and studies given one named owner. The field and construction seat was found empty and created.
- **Consumers.** One model passed find-and-interpret, update-propagation and missing-information tests against baseline answers; the second is staged; the classification worker is blocked. The graph held 419 records and 650 links on 4 November.

## 6. Why seeing worked where reading did not

- Absence is invisible in a table and loud in a picture. 86 decisions in a list look like work done. 86 dots with no lines between them look like silence.
- Proportion is a glance in a picture and a query nobody runs in a table.
- Fragments pointed at missing categories, not missing data, which inverted the usual backfill instinct.
- A shared picture let the human and the model disagree about a specific empty spot instead of an abstraction.
- Each lens surfaced the next question without a plan. Figure 1 is that sequence.

## 7. Measures

Baseline recorded 3 November 2026. No post-baseline reading yet.

| Measure | Baseline | Target |
|---|---|---|
| Decisions with a change-target | ~0% | every client-validated decision |
| Lineage links per active project | 0 (one project has 1) | ≥1 per design change |
| Decisions captured without the principal entering anything | not measured | all |
| Field items traced to an originating design decision | 1 | all |
| Principal re-entry count (times she had to relay context) | not measured | 0 |
| Decision latency, discovery to accepted correction | clock started 3 Nov | report on first cycle |
| Open intentions with a done-when | 35 of 35 (12 model-drafted, flagged) | all human-confirmed |

## 8. Threats to validity

1. **Single case, two days.** Nothing here generalises yet.
2. **The mirror partly paints itself.** Team groupings, several done-when statements and every calculated edge were written by the model. A defect count of zero can mean model-written answers. Mitigation: provenance labels on every edge; model-drafted content flagged in the record.
3. **Text match masquerading as lineage.** A make and model agreeing is a clue, not a line. Rule adopted; not yet enforced at write time.
4. **Inferred lineage is worse than none.** A wrong supersedes link misleads every later read. Rule: write only where the newer record names the older one, or the person confirms.
5. **Same-provider review.** Most checks were run by the system that built the thing. One independent read-only audit by a second agent was done. Independent human review has not.
6. **Survivorship in the record.** The record over-represents the one project whose decisions were captured. Absence elsewhere may be capture failure, not silence.
7. **The author is the subject.** The principal is both the designer whose decisions are examined and the author. Section 6 is self-report.

## 9. What we have not done yet

1. **PROV-O mapping.** Express the three provenance labels as PROV qualified derivation, with an Agent for who asserted each edge.
2. **Linked Building Data.** Test alignment with BOT and OPM on one project, or state why decision-centred beats element-centred at this scale.
3. **Change-propagation comparison.** The BIM dependency-matrix work [9] is the closest prior art to "tap the decision, see every sheet that moves." Not yet compared.
4. **Rejected options.** [10] records non-selected decisions; IBIS had it from the start. Our lineage family has no "considered and rejected" role.
5. **Transcript extraction evaluation.** [13] gives a published evaluation design for exactly our capture step. Run it on five of our meetings before claiming capture works.
6. **A vetted answer set.** The traceability field evaluates against one [4]. Build it from one completed project and score precision and recall.
7. **Path logging.** The read returns a revision hash, not the path the model took. Add it.
8. **Decision latency.** Report it on the first real correction cycle.
9. **Outside reader.** No second practice, no reviewer outside the system.
10. **Money and people dimensions.** Not started. The graph currently sorts by lineage and time only.

## 10. What is defensible to say now

As one practitioner's experience: the discovery narrative, the two-day evolution, and the five observations in section 6. As a method note: the record rules in section 3, positioned against the prior work in section 2. Not yet: any claim of effect, time saved, errors avoided or capture working, because no post-baseline measure exists.

## References

1. Buckingham Shum, S.J., Selvin, A.M., Sierhuis, M., Conklin, J., Haley, C.B., Nuseibeh, B. *Hypermedia support for argumentation-based rationale: 15 years on from gIBIS and QOC.* In Rationale Management in Software Engineering, Springer, 2006.
2. Horner, J., Atwood, M.E. *Effective design rationale: understanding the barriers.* Same volume.
3. Gotel, O.C.Z., Finkelstein, A.C.W. *An analysis of the requirements traceability problem.* ICRE 1994. doi:10.1109/ICRE.1994.292398.
4. Borg, M. *Advancing trace recovery evaluation.* arXiv:1602.07633. See also Niu et al. on task-aware trace vetting.
5. W3C. *PROV-O: The PROV Ontology.* Recommendation, 2013. https://www.w3.org/TR/prov-o/
6. Car, N. *DecPROV: the Decision Provenance ontology.* https://github.com/nicholascar/decprov-ont
7. Kraft, E. *Digital engineering and the digital thread.* NDIA Systems & Mission Engineering, 2024.
8. Rasmussen, M.H. et al. *Managing interrelated project information in AEC Knowledge Graphs.* Automation in Construction, 2019.
9. Pilehchian, B., Staub-French, S., Nepal, M.P. *A conceptual approach to track design changes within a multi-disciplinary BIM environment.* Canadian Journal of Civil Engineering, 2015.
10. Öz, K., Öz, M.H. *Making rejected and non-selected architectural design decisions traceable: a decision/memory model.* Buildings 16(12), 2026.
11. Sinequa. *From digital thread to decision thread in manufacturing AI.* 2026. Industry source.
12. Nygard, M. *Documenting architecture decisions.* 2011. Brown, S. *Visualising ADRs.* Pryce, N. *adr-tools.*
13. da Silva, L.D.C., Gama, K. *GADR: Gathering Architecture Decision Records from meeting transcriptions.* arXiv:2608.17694.
14. *OntoGraphRAG retrieval-state diagnostics.* arXiv:2606.22728. Microsoft Research, *GraphRAG*, 2024.
15. Community critiques of Obsidian graph view at scale, forum.obsidian.md and r/ObsidianMD, 2025 to 2026.

---

*Written with AI assistance on the studio's own record. The record, the graph and the live read are internal; this article describes them and does not expose them. Comments and corrections: open an issue on this repository.*
