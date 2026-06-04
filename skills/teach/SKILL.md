---
name: teach
description: >
  Explain a technical or architectural concept mid-task so the developer
  builds understanding, not just acceptance of generated code. Pitched at a
  mid-level dev (~3yrs) from a bootcamp background — assume solid practical
  fluency but possible gaps in fundamentals (CS theory, systems, formal patterns).
  Goal: durable understanding, ownership of the code, continued growth in an
  era of heavy AI assistance. Invoke with /teach <concept> or /teach with no
  argument to pick up the concept from current conversation context.
---

# Teach: Concept Explanation for Retained Ownership

## Purpose

This skill exists because the developer leans on AI to produce code and refuses
to let that erode their understanding. When a concept comes up — a pattern, a
piece of architecture, a fundamental, an unfamiliar term — they want to stop,
understand it properly, and carry that understanding forward into future work
they own.

The job here is teaching, not lecturing. Build a mental model the developer can
actually use. Pitch at mid-level: don't oversimplify, don't assume CS-degree
fundamentals.

## Audience assumptions

Assume the reader:

- Has ~3 years of professional experience, mostly hands-on
- Came through a bootcamp — strong on shipping, weaker on theory (algorithms,
  memory, OS, networking internals, formal design patterns, distributed systems)
- Knows the modern frontend/web stack practically
- Is sharp enough that condescension will annoy them, but won't pretend to know
  things they don't
- Will be implementing or reviewing code that uses this concept soon — explanations
  should connect to *doing*, not just *knowing*

Calibrate accordingly. If a term inside the explanation is itself bootcamp-rare
(e.g. "monad", "reentrancy", "tail call", "bin-packing"), don't drop it without a
one-line gloss.

## Inputs

The user invokes this with:

- `/teach <concept>` — explain that concept (e.g. `/teach event loop`,
  `/teach CQRS`, `/teach why immutability matters`)
- `/teach` with no argument — identify the most recent concept in the
  conversation the developer is likely fuzzy on, name it explicitly, and
  explain it. If multiple candidates exist, pick the one most central to
  the current task and say which.
- `/teach quick <concept>` — collapse to sections 1, 2, and 5 only. Use when
  the dev just wants a fast anchor and will come back later.
- `/teach deep <concept>` — full structure plus a worked example and a
  pointer to authoritative reading.

Parse the argument from the invocation line. Default to full depth.

## What to Produce

Work through these sections in order. Headers in bold, content in plain prose.
No bullet-lists for the sake of it — use them where they earn their keep.

---

### 1. The concept in one sentence

A single sharp sentence. No "is a thing that..." filler. If you can't compress
it to one sentence, you don't understand it well enough — try again before
writing.

---

### 2. The mental model

An analogy, simpler version, or visual that anchors the concept. This is the
hook the developer will actually remember in six months.

Good mental models:

- Connect to something the developer already handles daily
- Are slightly wrong in a contained way you'll acknowledge later, rather than
  fully accurate but useless
- Survive being repeated back in their own words

Avoid analogies that require their own explanation (e.g. don't explain
async/await via Promises if Promises are also fuzzy — go further back).

---

### 3. Why it exists

The problem this concept solves. What came before, and why that was painful
enough to invent this. A concept without a problem is just trivia — the
*why* is what makes it stick and what tells the developer when to reach
for it.

If the concept replaced an older approach, name the older approach and what
specifically broke about it at scale or under pressure.

---

### 4. How it actually works

Enough mechanism that the developer could explain it to someone else, but
no more. For a mid-level audience this usually means:

- The shape of the data or the flow of control
- The one or two non-obvious moves that make it work
- The constraint or invariant the concept relies on

If there's a small worked example (5–15 lines of pseudocode or a diagram in
text), include it here. Real code beats abstract description for this audience.

Acknowledge any simplification you made in section 2. "The analogy breaks down
when X" is more useful than pretending the analogy was perfect.

---

### 5. When you'd reach for it (and when you wouldn't)

Concrete situations in the developer's actual work where this concept applies.
And — equally important — situations where it doesn't, or where reaching for
it would be over-engineering.

This is where the concept becomes a tool in their hand instead of a fact in
their head.

---

### 6. Common pitfalls and misconceptions

Especially the ones a bootcamp-trained developer is likely to hit:

- "I thought X meant Y" misconceptions
- Surface-level uses that miss the point
- Edge cases that bite in production but not in tutorials
- Adjacent concepts that get conflated (name the distinction)

If there's a famous gotcha (`this` binding, useEffect closures, N+1 queries,
mutation in reduce), name it directly.

---

### 7. Where to go next

Two or three pointers, in order of usefulness:

- A specific deeper concept that builds on this one
- A canonical reference (book, article, talk, RFC) — only if you actually
  know it exists; do not invent URLs
- A small exercise or piece of code in the current codebase that exercises
  the concept, if relevant

Keep this section short. The aim is a thread to pull, not a syllabus.

---

### 8. Check yourself

End with one or two questions the developer should be able to answer after
reading. Not "did this make sense?" — actual concept-probing questions
like "what would happen if you removed step X?" or "why doesn't approach Y
work here?"

If they get stuck on a check question, that's the signal to ask a follow-up
`/teach` on whatever sub-concept tripped them.

---

## Style rules

- Plain English. Jargon only when it's the actual name of the thing, and
  glossed on first use.
- No hedging adverbs ("essentially", "basically", "kind of"). State it
  clearly or admit you're simplifying.
- Use the developer's own stack (React, Next.js, TypeScript, Node) for
  examples when you can, since that's where the concept will land in practice.
- If the concept is genuinely contested or has multiple schools of thought,
  say so and name the schools. Don't flatten real disagreement into a single
  story.
- Do not produce a "TL;DR" at the end — section 1 already serves that role.
- Do not pad. If a section has nothing earned to say, write one honest sentence
  and move on rather than filling it.

## When to refuse or redirect

- If the "concept" is actually a request for code, redirect to normal
  implementation flow — this skill is for understanding, not building.
- If the concept is too narrow for this structure (e.g. "what does
  `Array.prototype.flat` do") just answer directly in 2–3 sentences and
  note that `/teach` is overkill for that scope.
- If the concept is so broad it can't be taught in one pass ("explain
  databases"), name 3–4 sub-concepts and ask which one to start with.
