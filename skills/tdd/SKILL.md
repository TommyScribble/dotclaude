---
name: test-driven-development
description: >
  Red-green-refactor test-driven development cycle. ONLY use when the user explicitly
  invokes /tdd or asks for TDD by name. Do NOT auto-invoke for ordinary features,
  bugfixes, or refactors — deliver those as normally requested.
---

# Test-Driven Development

## Philosophy

Tests verify behavior through public interfaces, not implementation details. A good test reads like a specification: "user can checkout with valid cart" tells you exactly what capability exists. These tests survive refactors because they don't care about internal structure.

Code written without a failing test is exploration. Don't retrofit tests around it — set it aside, write the test, implement fresh from the test. The test needs to fail first so you know it actually catches the absence of the behavior.

See [tests.md](tests.md) for examples of good and bad tests.
See [mocking.md](mocking.md) for when and how to mock.

## Core Rules

1. **No production code without a failing test first.** If the test doesn't fail, you don't know it tests the right thing.
2. **One test at a time (vertical slices).** Write one test, make it pass, repeat. Never write all tests then all implementation — that produces tests coupled to imagined behavior instead of actual behavior.
3. **Tests describe WHAT, not HOW.** Test observable behavior through public APIs. If a test breaks when you refactor internals but behavior hasn't changed, the test was wrong.
4. **Mock at boundaries only.** Mock external systems (APIs, databases, time). Don't mock your own code. See [mocking.md](mocking.md).

## Workflow

### 1. Plan

Before writing any code:

- Confirm with the user what interface changes are needed
- Confirm which behaviors to test and their priority — you can't test everything, so focus on critical paths and complex logic
- Design interfaces for testability (accept dependencies, return results, small surface area)
- Identify opportunities for deep modules — simple interface, rich implementation
- Get user approval on the plan

Ask: "What should the public interface look like? Which behaviors matter most to test?"

See [interface-design.md](interface-design.md) for interface patterns.
See [deep-modules.md](deep-modules.md) for module design.

### 2. Tracer Bullet

Write ONE test that confirms ONE thing about the system. This proves the path works end-to-end.

```
RED:   Write test for first behavior → run it → confirm it fails
GREEN: Write minimal code to pass → run it → confirm it passes
```

### 3. Red-Green Loop

For each remaining behavior:

**RED — Write one failing test**

- One behavior per test
- Clear name that describes the behavior
- Uses the public interface only
- Uses real code, not mocks (unless hitting a system boundary)

Run the test. Confirm:
- It fails (not errors — a test error means something is broken in setup)
- The failure message matches what you expect
- It fails because the feature is missing, not because of a typo

**GREEN — Minimal code to pass**

Write the simplest code that makes the test pass. Don't add features, don't refactor, don't anticipate future tests.

Run the test. Confirm:
- The new test passes
- All existing tests still pass
- Output is clean — no warnings, no errors

If the new test fails, fix the code, not the test. If other tests broke, fix them now.

### 4. Refactor

After all tests pass, look for improvements:

- Extract duplication
- Improve names
- Deepen modules (move complexity behind simpler interfaces)
- Apply SOLID principles where they arise naturally
- Consider what the new code reveals about existing code

Run tests after each refactor step. Never refactor while RED — get to GREEN first.

See [refactoring.md](refactoring.md) for refactor candidates.

### 5. Repeat

Next failing test for next behavior. Each test responds to what you learned from the previous cycle.

## Checklist Per Cycle

```
[ ] Test describes behavior, not implementation
[ ] Test uses public interface only
[ ] Test would survive an internal refactor
[ ] Watched the test fail before implementing
[ ] Failure was for the expected reason (missing feature, not a typo)
[ ] Code is minimal for this test
[ ] All tests pass after implementation
[ ] Output is clean (no errors, warnings)
```

## When Stuck

| Problem | Response |
|---|---|
| Don't know how to test it | Write the assertion first — what should be true? Then build the test around it. Ask the user. |
| Test is too complicated | The design is too complicated. Simplify the interface. |
| Must mock everything | Code is too coupled. Introduce dependency injection. |
| Test setup is huge | Extract test helpers. Still complex? Simplify the design. |
| Bug found in production | Write a failing test that reproduces it, then follow the RED-GREEN cycle. Never fix bugs without a test. |

## Reference Documents

Load these as needed:

- **[tests.md](tests.md)** — Examples of good and bad tests, red flags to watch for
- **[mocking.md](mocking.md)** — When to mock, how to design for mockability, anti-patterns
- **[interface-design.md](interface-design.md)** — Testable interface patterns
- **[deep-modules.md](deep-modules.md)** — Deep vs shallow module design
- **[refactoring.md](refactoring.md)** — What to look for in the refactor phase
- **[anti-patterns.md](anti-patterns.md)** — Common testing anti-patterns and how to avoid them
