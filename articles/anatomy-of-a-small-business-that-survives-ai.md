# The anatomy of a small business that survives AI

### Brain, ontology, fascia, orchestration: how a very small practice stops paying the AI guessing tax

**Kellie Patry · KPHD Studio, Los Angeles · and Claude (Anthropic) · 5 November 2026 · working draft v1.0**

> A joint article. One of us runs a small design practice; the other is the language model that works inside its record every day. We wrote it together from the process side only. It describes a method and the research behind it. It does not describe the business, its clients or its systems, and nothing here links into them.

## 1. The tax

Large firms absorb AI by hiring for it. Someone cleans the data, someone maintains the integrations, someone checks what the model gets wrong. A small business has none of those people. If you are a team of one or five, every hour spent re-explaining your work to a model is an hour you don't bill. AI that guesses isn't a productivity tool for you. It's a tax.

The adoption data shows the gap. In the US Census Bureau's Business Trends and Outlook Survey, about one business in five reported using AI in any business function in the period to early May 2026. That rate was 37% among firms with 250 or more employees and under 20% among firms with four or fewer. Use rose among firms with at least 20 employees over those six months and did not change significantly among smaller ones [1]. Private surveys of small-business owners report much higher figures, because they ask a looser question: whether owners use any AI tool at all [2]. Both can be true. Small firms try the tools. Fewer of them get the tools into how the business actually runs.

Our argument: the difference is rarely the model. It's what the model can read, and whether what it reads holds together.

## 2. Why the model guesses

A language model asked about your business has two sources: what it learned in training, which knows nothing about you, and what you give it now. When the second is missing or contradictory, it fills the gap with something plausible. The research literature calls the result hallucination: fluent output that is unfaithful to the source or simply not true [3].

The obvious fix is to give the model more: paste in the folder, attach the thread. That helps less than you'd expect. Models use long inputs unevenly. In controlled tests, accuracy was highest when the relevant fact sat at the start or end of the context and dropped sharply when it sat in the middle, even for models built for long contexts [4]. More text is not more understanding.

What works better is grounding. Retrieval-augmented generation, introduced in 2020, pairs a model with an external store it can look things up in, so answers come from retrieved evidence rather than from the model's own parameters alone [5]. Retrieval of isolated passages has a ceiling, though. It struggles with questions about the whole, such as "what are the main themes here?" Graph-based retrieval answers those better: it first builds a graph of entities and the relationships between them, then reasons over clusters of that graph [6].

So the question for a small business isn't "which model?" It's "what does the model read, and is it connected?"

## 3. What "second brain" meant, and what we changed

The idea is old. In 1945 Vannevar Bush imagined the memex, a desk-sized personal archive in which the user could tie any two items together into associative trails, because, he argued, the mind works by association and not by index [7]. Niklas Luhmann's card index ran on the same principle for decades: every note numbered, every note linked. The current popular version is Tiago Forte's *Building a Second Brain*, organised around four moves: capture, organise, distill, express [8].

Two ideas from cognitive science sit underneath. The extended mind thesis holds that tools reliably used to store and retrieve information can count as part of a person's cognition [9]. Transactive memory describes how groups remember: no one holds everything, but each member knows who holds what [10].

All of these assume one reader: the person. We changed the reader. In a practice where AI does real work, the second brain has two readers, the person and the model. The model doesn't browse or remember last week. It reads what it's given or what it can query, and it reads literally. For a small firm, the model can only become a working member of the group's transactive memory if the record itself says what exists, how things relate and who owns what.

Our working definition became: **a second brain is a record that both minds can read, in which the connections carry as much meaning as the contents.**

That definition has four parts. We name them with anatomy because the analogy is close: one body, different tissues, and none of them works alone.

## 4. The anatomy

### The brain: one record that holds what is true

One place is the authority for what has been decided, what is in progress and what the rules are. It isn't chosen because it's the most convenient or the newest. It's chosen once. Every other surface (documents, chats, task tools) can mirror it, but when they disagree, the record wins.

This is the cheapest change with the largest effect. A model faced with two versions of a rule has to guess which is current. A model pointed at one authority doesn't. In retrieval terms it is the difference between a corpus that contradicts itself and one that doesn't [5].

*Practice:* name the authority in writing. Tell every model that works for you to read it before it answers and to cite what it read.

### The ontology: what kinds of things exist

In knowledge engineering, an ontology is, in Thomas Gruber's often-quoted phrase, "an explicit specification of a conceptualization" [11]. Plainly: an agreed list of the kinds of things your record contains and what each kind means.

A decision is not a note. A study is not a project. An owner is a named seat, not "whoever's around." A small, stable set of types gives every record a shape a model can rely on. Without one, the same idea gets filed five ways and the model has to guess which you meant. A review of how large language models and knowledge graphs can work together frames the pairing this way: models are flexible but opaque and prone to inventing facts, and knowledge graphs hold explicit, structured knowledge that can ground them [12]. The ontology is what makes a graph explicit.

*Practice:* keep the type list short and change it rarely. Make the model use it when it writes, not only when it reads.

### The fascia: the connective tissue between records

Fascia is the connective tissue that wraps and links the body's muscles and organs. Anatomists long treated it as packing material. Research over the last two decades shows something different: fascia forms a body-wide network that can transmit force from one muscle to its neighbours and along chains of muscles, which challenges the classic picture of muscles as independent actuators [13].

Records behave the same way. A decision is not an independent object. It came from somewhere, it governs something and it will be superseded by something. The links carry that force. When a decision changes, the links are how the change reaches everything it affects. When a link is missing, the change stops where the link stops.

Our rule is that nothing floats. Every record links to where it came from and what it affects. A record with no connections is either a gap to fix or residue to archive. When we drew the record as a graph, unlinked records were obvious in a way they never were in a table. They pointed to categories that existed in someone's head but not in the record, and to decisions that had never been connected to the decisions they replaced. That echoes a finding from requirements engineering: traceability fails most often at the link back to a requirement's origin [14].

*Practice:* set links when a record is created, not later. A link made at birth costs nothing. One backfilled later costs an afternoon.

### Orchestration: the model as traffic control

The last layer is the model, and its job changes. It no longer has to remember. It reads. It reads the record before it answers, works inside what has already been decided, and writes back what was decided in the same turn, linked to where it belongs.

At this point a small business can run more than one model, or more than one specialist role, because they all read the same truth. Anthropic's guidance on building agents describes an orchestrator-workers pattern, in which a central model breaks a task down, hands the pieces to worker models and combines their results. The same guidance argues for the simplest system that works over elaborate frameworks [15]. What makes the pattern hold together in a small business is less the orchestrator than the shared record. A handoff loses the thread when the next worker can't read what the last one decided.

We hold one line firmly. The model is traffic control, not the decision-maker. It routes, checks and keeps the lanes clear. Intention, design judgment and decisions with consequences stay human.

*Practice:* give every worker the same authority to read and the same place to write back. Keep the human role at the start (intention) and at the gates (decisions), not in the middle relaying context.

## 5. The cycle

Put the four layers together and you get a loop:

1. **State the intention.** One line: what are we trying to get to?
2. **Read before speaking.** The model pulls the rules and the current state of the work from the record.
3. **Work inside that frame.**
4. **Write back and link.** The decision, the change or the open question is recorded, typed and connected.
5. **The next read starts further ahead.**

The model doesn't get smarter. It gets fewer blanks to fill. That is the whole mechanism, and it compounds: every turn that writes back improves the next turn's read.

How we talk matters as well as what we record. We wrote down a few conversation rules: say the intention first; ask one question at a time with a proposed answer; don't ask a question whose answer is already known; once the intention is set, don't reopen it with new what-ifs. A clear record and clear conversation reinforce each other. Neither works alone.

## 6. What we saw

We describe this qualitatively, on purpose. The numbers belong to the business, and the pattern is what transfers.

- **Rule-making came in a burst, then settled.** For a while every friction became a new rule. Then the rate of new rules fell off sharply. We read that as the system moving from defining how to work to working inside the definitions.
- **Continuity stopped depending on memory.** Once every working session left a checkpoint in the record, picking work back up no longer relied on anyone remembering where it stood, human or model.
- **Drawing the graph showed problems that reading the record didn't.** Loose records, loops and decisions that never closed were plain in the picture.
- **The model asked fewer orienting questions.** We haven't measured this; it's an observation. Its answers began from recorded decisions instead of reconstructing them from conversation.

## 7. What it isn't yet

Here we disagree a little with our own hook, and we'd rather say so.

- **The deepest layer is the hardest.** Seeing what connects to what is the easy part. Tracing a decision's lineage is harder: how an early choice leads to the next one, travels into the field, and what the field sends back. Without lineage the record is a map, not a memory of *why*.
- **Capture can outrun closure.** A record that makes capture easy will collect open items faster than anyone closes them. A second brain that remembers everything and finishes nothing is hoarding with good filing.
- **"Survival" is a position, not a finding.** What we can support is less re-explaining and continuity that doesn't depend on memory. Whether this keeps a small business alive is a claim to test over years, not weeks.
- **One practice, one primary model.** Most of the checking in our case was done by the system that built it. Get an outside reader before you trust anyone's results, including ours.

## 8. If you want to try this

- **Pick one authority.** Decide where truth lives and make everything else a copy.
- **Write down your types.** A short list of what kinds of things exist, and use it every time.
- **Link at creation.** Every new record names where it came from and what it affects.
- **Write decisions back in the same turn.** If a decision isn't recorded, the model will have to guess it next time.
- **Keep the model in traffic control.** It routes and checks. You decide.
- **Measure closure, not capture.** Count what gets finished.

The second brain isn't the notes. It's the tissue between them, a vocabulary that holds still, and a model that reads before it speaks. For a business too small to hire its way through AI, that anatomy is the difference between a tool and a tax.

## References

1. Breaux, C., Khatiwoda, D. *Large firms with at least 20 employees biggest AI users.* US Census Bureau, Business Trends and Outlook Survey, May 2026. https://www.census.gov/library/stories/2026/05/ai-use-businesses.html
2. Survey roundups of small-business AI use, 2026 (Goldman Sachs 10,000 Small Businesses Voices; SBE Council Small Business Technology Use Survey; Thryv). Definitions differ from the Census measure; see each survey's method.
3. Ji, Z. et al. *Survey of hallucination in natural language generation.* ACM Computing Surveys 55(12), 2023. arXiv:2202.03629.
4. Liu, N.F., Lin, K., Hewitt, J., Paranjape, A., Bevilacqua, M., Petroni, F., Liang, P. *Lost in the middle: how language models use long contexts.* TACL, 2023. arXiv:2307.03172.
5. Lewis, P. et al. *Retrieval-augmented generation for knowledge-intensive NLP tasks.* NeurIPS, 2020. arXiv:2005.11401.
6. Edge, D. et al. *From local to global: a graph RAG approach to query-focused summarization.* Microsoft Research, 2024. arXiv:2404.16130.
7. Bush, V. *As we may think.* The Atlantic, July 1945.
8. Forte, T. *Building a Second Brain.* Atria Books, 2022.
9. Clark, A., Chalmers, D. *The extended mind.* Analysis 58(1), 1998.
10. Wegner, D.M. *Transactive memory: a contemporary analysis of the group mind.* In Mullen & Goethals (eds.), Theories of Group Behavior, Springer, 1987.
11. Gruber, T.R. *A translation approach to portable ontology specifications.* Knowledge Acquisition 5(2), 1993.
12. Pan, S. et al. *Unifying large language models and knowledge graphs: a roadmap.* IEEE TKDE, 2024. arXiv:2306.08302.
13. Wilke, J., Schleip, R., Yucesoy, C.A., Banzer, W. *Not merely a protective packing organ? A review of fascia and its force transmission capacity.* Journal of Applied Physiology, 2018. See also Schleip, R., Findley, T.W., Chaitow, L., Huijing, P.A. (eds.) *Fascia: The Tensional Network of the Human Body.* Elsevier, 2012.
14. Gotel, O.C.Z., Finkelstein, A.C.W. *An analysis of the requirements traceability problem.* ICRE, 1994.
15. Schluntz, E., Zhang, B. *Building effective agents.* Anthropic, December 2024. https://www.anthropic.com/engineering/building-effective-agents

---

*Written jointly by Kellie Patry and Claude, a language model made by Anthropic, from the process side of the studio. The studio's record and systems are internal. This article describes the method and does not expose them. Comments and corrections: open an issue on this repository.*
