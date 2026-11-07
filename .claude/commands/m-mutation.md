---
description: "M — Mutation-test the engine (optional)"
---

Read AGENTS.md and docs/adr. Plan first and wait for my approval, because this adds a build plugin (record an ADR). Add PIT mutation testing (Maven plugin) scoped ONLY to the engine package. Run it and report the mutation score and each surviving mutant (file:line, mutation, why the tests missed it). Add or strengthen tests to kill the meaningful survivors. Do not change production logic; if a survivor reveals a real bug or an ambiguous rule, stop and report it.
