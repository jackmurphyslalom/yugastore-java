---
name: aisdlc-grilling
description: Guided decision interview for AI-SDLC context bootstrapping. Use when project facts are discoverable but domain intent, terminology, boundaries, or tradeoffs require human confirmation.
license: MIT
---

# AI-SDLC Grilling

Turn incomplete project evidence into confirmed shared understanding without making domain decisions for the user.

## Method

1. Inspect the available repository evidence before asking questions.
2. Separate discoverable facts from decisions that require a human.
3. State the evidence and your current inference briefly.
4. Ask exactly one decision question at a time.
5. Recommend an answer and explain the material tradeoff.
6. Wait for the answer before updating authoritative terminology or decisions.
7. At the end, summarize the proposed understanding and request explicit confirmation.
8. Mark context verified only after that confirmation.

Prefer questions that expose domain boundaries, invariants, actors, lifecycle states, and terms whose meaning changes behavior. Skip questions already answered by reliable evidence.

## Guardrails

- Do not present an inference as a fact.
- Do not bundle unrelated decisions into one question.
- Do not invent facts when evidence is insufficient; stop and identify the missing evidence.
- Do not create an ADR unless the domain-modeling skill's three decision gates are all satisfied and the user confirms the decision.
- Do not implement application code while bootstrapping context.
- Automated draft generation is not a substitute for this confirmation process.
